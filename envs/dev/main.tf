terraform {
  required_version = ">= 1.5.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "vpc" {
  source       = "../../modules/vpc"
  name         = var.env_name
  region       = var.region
  subnet_cidr  = var.subnet_cidr
}

module "vm" {
  source       = "../../modules/vm"
  name         = "${var.env_name}-vm"
  machine_type = var.machine_type
  zone         = var.zone
  image        = var.image
  subnet       = module.vpc.subnet
}

module "dns" {
  source   = "../../modules/dns"
  enabled  = var.enable_private_dns
  name     = "${var.env_name}-dns"
  dns_name = var.dns_name
  network  = module.vpc.network
}
