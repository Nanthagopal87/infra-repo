# GCP Terraform (Conditional VPC & VM with JSON tfvars)

Each environment is isolated (its own state via GCS backend).  
Enable/disable resources via booleans in `terraform.tfvars.json`.

## Usage
cd envs/dev   # or uat/stg/prd
terraform init
terraform plan
terraform apply

## Notes
- If `enable_vm = true` and `enable_vpc = false`, you must provide an existing `subnet_self_link` in tfvars.
- Edit only the JSON in each env for promotions (great for Backstage automation).


### Example using existing VPC - infra/envs/stg/terraform.tfvars.json
```
{
  "project_id": "my-gcp-stg",
  "region": "us-central1",
  "zone": "us-central1-c",

  "enable_vpc": false,
  "enable_vm": true,

  "network_name": "stg-vpc",
  "subnetwork_name": "stg-subnet",
  "subnet_cidr": "10.30.0.0/16",

  "subnet_self_link": "https://www.googleapis.com/compute/v1/projects/my-gcp-stg/regions/us-central1/subnetworks/stg-subnet",

  "vm_name": "stg-vm",
  "machine_type": "e2-medium",
  "image": "debian-cloud/debian-12",
  "tags": ["env-stg", "app-demo"]
}
```

### Hot to Run
```
cd envs/dev
terraform init
terraform plan -var-file="terraform.tfvars.json"
terraform apply -var-file="terraform.tfvars.json"
```

### Note
```
With this setup:

If enable_vpc = true, VM will attach to the newly created subnet.

If enable_vpc = false and you give subnet_self_link in tfvars.json, it will attach to that instead.
```