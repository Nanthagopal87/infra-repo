Please update above terraform code with artifact registry 

Perfect 👍 let’s extend your **Terraform code** so Composer installs Python packages from a **private Artifact Registry PyPI repository** instead of `pypi.org`.

---

## 🔹 Steps to prepare Artifact Registry (one-time outside Terraform)

1. **Enable Artifact Registry API**

   ```bash
   gcloud services enable artifactregistry.googleapis.com \
     --project prj-gdg-ai-meetup-20250717
   ```

2. **Create a PyPI repository**

   ```bash
   gcloud artifacts repositories create composer-pypi \
     --repository-format=python \
     --location=asia-south1 \
     --description="Private PyPI for Composer packages" \
     --project=prj-gdg-ai-meetup-20250717
   ```

   This gives you a repo URL like:

   ```
   https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi/simple
   ```

3. **Upload Python packages** you need:

   ```bash
   gcloud artifacts packages upload requests \
     --repository=composer-pypi \
     --location=asia-south1 \
     --project=prj-gdg-ai-meetup-20250717
   ```

---

## 🔹 Updated Terraform Code

```hcl
resource "google_project_service" "composer_api" {
  provider = google-beta
  project  = "prj-gdg-ai-meetup-20250717"
  service  = "composer.googleapis.com"
  disable_on_destroy                    = false
  check_if_service_has_usage_on_destroy = true
}

resource "google_service_account" "custom_service_account" {
  provider     = google-beta
  account_id   = "custom-service-account"
  display_name = "Example Custom Service Account"
}

resource "google_project_iam_member" "custom_service_account" {
  provider = google-beta
  project  = "prj-gdg-ai-meetup-20250717"
  member   = format("serviceAccount:%s", google_service_account.custom_service_account.email)
  role     = "roles/composer.worker"
}

resource "google_composer_environment" "example_environment" {
  provider = google-beta
  name     = "example-environment"
  project  = "prj-gdg-ai-meetup-20250717"
  region   = "asia-south1"

  config {
    software_config {
      image_version = "composer-3-airflow-2.10.5-build.13"

      # Install packages from private Artifact Registry PyPI repo
      pypi_packages = {
        "requests" = "==2.31.0"
      }

      env_variables = {
        PIP_INDEX_URL = "https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi/simple"
      }
    }

    node_config {
      service_account = google_service_account.custom_service_account.email
    }
  }
}
```

---

## 🔹 Explanation of changes

* Added `region   = "asia-south1"` to Composer env (required for TF provider ≥ 5.0).
* Added `software_config.pypi_packages` → tells Composer to install `requests==2.31.0`.
* Added `software_config.env_variables.PIP_INDEX_URL` → overrides default PyPI URL with your **Artifact Registry PyPI repo**.

---

✅ With this config, Composer workers will **only install packages from your private Artifact Registry repo**.
❌ No calls will be made to `pypi.org`.

---

👉 Do you want me to also update this so Terraform **creates the Artifact Registry PyPI repo automatically** (instead of doing it manually)? That way your infra stays fully IaC-driven.
