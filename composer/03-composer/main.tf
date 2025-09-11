resource "google_project_service" "composer_api" {
  provider = google-beta
  project = "prj-gdg-ai-meetup-20250717"
  service = "composer.googleapis.com"
  // Disabling Cloud Composer API might irreversibly break all other
  // environments in your project.
  // This parameter prevents automatic disabling
  // of the API when the resource is destroyed.
  // We recommend to disable the API only after all environments are deleted.
  disable_on_destroy = false
  // this flag is introduced in 5.39.0 version of Terraform. If set to true it will
  //prevent you from disabling composer_api through Terraform if any environment was
  //there in the last 30 days
  check_if_service_has_usage_on_destroy = true
}

resource "google_composer_environment" "example_environment" {
  provider = google-beta
  name = "example-environment1"

  config {

    software_config {
      image_version = "composer-3-airflow-2.10.5-build.13"
    

        /*
        * Added specification for using private PyPI repository
        */
        # Example package from Artifact Registry
          pypi_packages = {
            "requests" = "==2.31.0"
          }

          env_variables = {
            #PIP_INDEX_URL = "https://${google_artifact_registry_repository.composer_pypi.location}-python.pkg.dev/${google_artifact_registry_repository.composer_pypi.project}/${google_artifact_registry_repository.composer_pypi.repository_id}/simple"
            #https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi
            PIP_INDEX_URL = "https://asia-south1-python.pkg.dev/prj-gdg-ai-meetup-20250717/composer-pypi/simple"
          }
        /*
        * End
        */

    }
    node_config {
      #service_account = google_service_account.custom_service_account.email
      service_account = "custom-service-account@prj-gdg-ai-meetup-20250717.iam.gserviceaccount.com"
    }

  }
}