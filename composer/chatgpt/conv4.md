PLease proceed

Perfect 👍 let’s make your **Terraform code fully IaC-driven** by also creating the **Artifact Registry PyPI repo** inside Terraform.

Here’s the **updated complete Terraform config**:

---

## 🔹 Full Terraform Code with Artifact Registry + Composer

```hcl
provider "google" {
  project = "prj-gdg-ai-meetup-20250717"
  region  = "asia-south1"
}

provider "google-beta" {
  project = "prj-gdg-ai-meetup-20250717"
  region  = "asia-south1"
}

# Enable required APIs
resource "google_project_service" "composer_api" {
  project  = "prj-gdg-ai-meetup-20250717"
  service  = "composer.googleapis.com"
  disable_on_destroy                    = false
  check_if_service_has_usage_on_destroy = true
}

resource "google_project_service" "artifact_registry_api" {
  project  = "prj-gdg-ai-meetup-20250717"
  service  = "artifactregistry.googleapis.com"
  disable_on_destroy                    = false
  check_if_service_has_usage_on_destroy = true
}

# Create Artifact Registry PyPI repo
resource "google_artifact_registry_repository" "composer_pypi" {
  provider        = google-beta
  project         = "prj-gdg-ai-meetup-20250717"
  location        = "asia-south1"
  repository_id   = "composer-pypi"
  format          = "PYTHON"
  description     = "Private PyPI for Composer packages"
}

# Custom Service Account for Composer
resource "google_service_account" "custom_service_account" {
  provider     = google-beta
  account_id   = "custom-service-account"
  display_name = "Example Custom Service Account"
}

# Grant Composer worker role to custom SA
resource "google_project_iam_member" "custom_service_account" {
  provider = google-beta
  project  = "prj-gdg-ai-meetup-20250717"
  member   = format("serviceAccount:%s", google_service_account.custom_service_account.email)
  role     = "roles/composer.worker"
}

# Grant Artifact Registry Reader role to Composer SA
resource "google_project_iam_member" "artifact_registry_reader" {
  provider = google-beta
  project  = "prj-gdg-ai-meetup-20250717"
  member   = format("serviceAccount:%s", google_service_account.custom_service_account.email)
  role     = "roles/artifactregistry.reader"
}

# Create Composer Environment with private PyPI
resource "google_composer_environment" "example_environment" {
  provider = google-beta
  name     = "example-environment"
  project  = "prj-gdg-ai-meetup-20250717"
  region   = "asia-south1"

  config {
    software_config {
      image_version = "composer-3-airflow-2.10.5-build.13"

      # Example package from Artifact Registry
      pypi_packages = {
        "requests" = "==2.31.0"
      }

      env_variables = {
        PIP_INDEX_URL = "https://${google_artifact_registry_repository.composer_pypi.location}-python.pkg.dev/${google_artifact_registry_repository.composer_pypi.project}/${google_artifact_registry_repository.composer_pypi.repository_id}/simple"
      }
    }

    node_config {
      service_account = google_service_account.custom_service_account.email
    }
  }
}
```

---

## 🔹 What this does

1. Enables **Composer API** + **Artifact Registry API**.
2. Creates **Artifact Registry PyPI repo** (`composer-pypi`).
3. Creates **Custom SA** + grants:

   * `roles/composer.worker`
   * `roles/artifactregistry.reader`
4. Deploys **Composer environment** that:

   * Installs `requests==2.31.0` from Artifact Registry.
   * Uses `PIP_INDEX_URL` to fetch packages only from private repo.

---

👉 Next Step: you’ll need to **upload your required Python wheels** to Artifact Registry before Composer can install them.

Would you like me to also add a **Terraform + Cloud Build job** to automatically upload wheels (e.g., `requests-2.31.0-py3-none-any.whl`) into your Artifact Registry repo? That way, package availability is also automated.
