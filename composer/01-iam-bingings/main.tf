provider "google" {
  project = "prj-gdg-ai-meetup-20250717"
  region  = "asia-south1"
}

resource "google_service_account" "custom_service_account" {
  provider = google
  account_id   = "custom-service-account"
  display_name = "Example Custom Service Account"
}

resource "google_project_iam_member" "custom_service_account" {
  provider = google
  project  = "prj-gdg-ai-meetup-20250717"
  member   = format("serviceAccount:%s", google_service_account.custom_service_account.email)
  // Role for Public IP environments
  role     = "roles/composer.worker"
}

# Grant Artifact Registry Reader role to Composer SA
resource "google_project_iam_member" "artifact_registry_reader" {
  provider = google
  project  = "prj-gdg-ai-meetup-20250717"
  member   = format("serviceAccount:%s", google_service_account.custom_service_account.email)
  role     = "roles/artifactregistry.reader"
}
