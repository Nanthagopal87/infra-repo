This is my tf source code resource "google_project_service" "composer_api" { provider = google-beta project = "prj-gdg-ai-meetup-20250717" service = "composer.googleapis.com" // Disabling Cloud Composer API might irreversibly break all other // environments in your project. // This parameter prevents automatic disabling // of the API when the resource is destroyed. // We recommend to disable the API only after all environments are deleted. disable_on_destroy = false // this flag is introduced in 5.39.0 version of Terraform. If set to true it will //prevent you from disabling composer_api through Terraform if any environment was //there in the last 30 days check_if_service_has_usage_on_destroy = true } resource "google_service_account" "custom_service_account" { provider = google-beta account_id = "custom-service-account" display_name = "Example Custom Service Account" } resource "google_project_iam_member" "custom_service_account" { provider = google-beta project = "prj-gdg-ai-meetup-20250717" member = format("serviceAccount:%s", google_service_account.custom_service_account.email) // Role for Public IP environments role = "roles/composer.worker" } resource "google_composer_environment" "example_environment" { provider = google-beta name = "example-environment" config { software_config { image_version = "composer-3-airflow-2.10.5-build.13" } node_config { service_account = google_service_account.custom_service_account.email } } } post creatin im seeeing only 1. Composer 2. GCS

Got it 👍 thanks for sharing your **Terraform code**.
What you are seeing (only **Composer** + **GCS buckets**) is expected — the other resources are **created *lazily*** once the environment gets to the “RUNNING” state.

Let me explain what’s happening in your case:

---

## 🔹 What Terraform Manages Directly

* Enables **Composer API** (`google_project_service`)
* Creates your **custom Service Account**
* Binds `roles/composer.worker` to that SA
* Creates the **Composer environment resource** (`google_composer_environment`)

That’s why after `terraform apply`, you see only:

* Composer environment in the console
* 1 or more GCS buckets (DAGs, logs, data)

---

## 🔹 What Composer Auto-Creates *afterwards*

When the Composer environment starts provisioning, **Google’s managed service** takes over and spins up resources **on your behalf** in the same project. These do not appear as Terraform resources, but they will exist in the project:

1. **GKE Autopilot Cluster**

   * Hosts Airflow components (scheduler, workers, triggerer, webserver)

2. **Cloud SQL (Postgres)**

   * Airflow metadata database (private IP if your env uses private IP)

3. **Cloud Memorystore (Redis)**

   * Task queue backend

4. **Pub/Sub topics/subscriptions**

   * For scheduling and internal ops

5. **Secret Manager entries**

   * DB credentials, Redis credentials

6. **Internal Load Balancers**

   * Airflow webserver, worker communication

7. **IAM bindings**

   * Between your custom SA and Kubernetes service accounts (via Workload Identity)

---

## 🔹 Why You Don’t See Them Immediately

* Composer resource creation is **asynchronous**.
* After `terraform apply`, Terraform just requests Composer to create the environment.
* Composer takes **\~20–30 minutes** to fully provision all dependent resources (GKE, Cloud SQL, Redis, etc.).
* Until then, you’ll see only **Composer + GCS buckets**.

---

✅ **Check progress:**
You can run:

```bash
gcloud composer environments describe example-environment \
  --location <your-region>
```

and look at the `config.gkeCluster`, `config.databaseConfig`, `config.webServerIpv4Address`, etc.

You can also check in the **Cloud Console** → **Composer → Environment → Details tab**, you’ll see linked **GKE cluster, Cloud SQL instance, Redis instance, Pub/Sub topics** once provisioning finishes.

---

👉 Do you want me to give you a **list of `gcloud` commands** to enumerate *all the hidden resources Composer created* in your project, so you can audit them after Terraform runs?
