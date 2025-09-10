https://cloud.google.com/composer/docs/composer-3/terraform-create-environments



### Code with Artifact reg
```
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