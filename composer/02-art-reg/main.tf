provider "google" {
  project = "prj-gdg-ai-meetup-20250717"
  region  = "asia-south1"
}

provider "google-beta" {
  project = "prj-gdg-ai-meetup-20250717"
  region  = "asia-south1"
}

resource "google_project_service" "artifact_registry_api" {
  project  = "prj-gdg-ai-meetup-20250717"
  service  = "artifactregistry.googleapis.com"
  disable_on_destroy = false
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