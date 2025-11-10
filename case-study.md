#!/bin/bash

set -e

# -------------------------
# CONFIG
# -------------------------
PROJECT_ID="your-project-id"
REGION="asia-south1"
ZONE="${REGION}-a"

PROD_VPC="prod-vpc"
PROD_SUBNET="prod-subnet"
CONS_VPC="cons-vpc"
CONS_SUBNET="cons-subnet"
PSC_NAT_SUBNET="psc-nat-subnet"

NGINX_VM="nginx-vm"
CLIENT_VM="client-vm"

IG_NAME="nginx-ig"
HC_NAME="nginx-hc"
BS_NAME="nginx-bs"
ILB_IP="ilb-ip"
ILB_FR="nginx-ilb"

SA_NAME="nginx-psc-sa"
PSC_EP_IP="psc-endpoint-ip"
PSC_EP_FR="psc-endpoint"

ROUTER="prod-router"
NAT="prod-nat"

# Firewall Rule Names
PROD_FW_SSH="prod-fw-allow-ssh"
PROD_FW_ILB_HC="prod-fw-allow-ilb-hc"
PROD_FW_EGRESS="prod-fw-allow-egress"

CONS_FW_SSH="cons-fw-allow-ssh"
CONS_FW_EGRESS="cons-fw-allow-egress"

# -------------------------
echo "Enabling Compute API..."
gcloud services enable compute.googleapis.com --project=$PROJECT_ID

# -------------------------
echo "Creating Producer VPC..."
gcloud compute networks create $PROD_VPC --project=$PROJECT_ID --subnet-mode=custom

gcloud compute networks subnets create $PROD_SUBNET \
  --project=$PROJECT_ID --region=$REGION --network=$PROD_VPC \
  --range=10.0.0.0/24

# -------------------------
echo "Creating Consumer VPC..."
gcloud compute networks create $CONS_VPC --project=$PROJECT_ID --subnet-mode=custom

gcloud compute networks subnets create $CONS_SUBNET \
  --project=$PROJECT_ID --region=$REGION --network=$CONS_VPC \
  --range=10.10.0.0/24

# -------------------------
echo "Setting up Cloud NAT for Producer VPC..."
gcloud compute routers create $ROUTER \
  --project=$PROJECT_ID --network=$PROD_VPC --region=$REGION

gcloud compute routers nats create $NAT \
  --project=$PROJECT_ID --router=$ROUTER --region=$REGION \
  --auto-allocate-nat-external-ips --nat-all-subnet-ip-ranges

# -------------------------
echo "Creating Producer VPC Firewall Rules..."

# Allow SSH from IAP for the NGINX VM (and other management)
gcloud compute firewall-rules create $PROD_FW_SSH \
  --project=$PROJECT_ID --network=$PROD_VPC \
  --allow=tcp:22 --source-ranges=35.235.240.0/20 \
  --description="Allow SSH from IAP for producer VMs"

# Allow ingress for internal load balancer health checks
gcloud compute firewall-rules create $PROD_FW_ILB_HC \
  --project=$PROJECT_ID --network=$PROD_VPC \
  --allow=tcp:80 \
  --source-ranges=130.211.0.0/22,35.191.0.0/16 \
  --target-tags=nginx \
  --description="Allow health check traffic to NGINX VMs"

# Allow all egress for producer VMs (e.g., for apt updates)
gcloud compute firewall-rules create $PROD_FW_EGRESS \
  --project=$PROJECT_ID --network=$PROD_VPC \
  --allow=all \
  --destination-ranges=0.0.0.0/0 \
  --direction=EGRESS \
  --description="Allow all egress traffic from producer VMs"

# -------------------------
echo "Creating Consumer VPC Firewall Rules..."

# Allow SSH from IAP for the client VM
gcloud compute firewall-rules create $CONS_FW_SSH \
  --project=$PROJECT_ID --network=$CONS_VPC \
  --allow=tcp:22 --source-ranges=35.235.240.0/20 \
  --description="Allow SSH from IAP for consumer VMs"

# Allow all egress for consumer VMs (e.g., to reach PSC endpoint)
gcloud compute firewall-rules create $CONS_FW_EGRESS \
  --project=$PROJECT_ID --network=$CONS_VPC \
  --allow=all \
  --destination-ranges=0.0.0.0/0 \
  --direction=EGRESS \
  --description="Allow all egress traffic from consumer VMs"


# -------------------------
echo "Creating Internal-only NGINX VM..."
gcloud compute instances create $NGINX_VM \
  --project=$PROJECT_ID --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=$PROD_SUBNET \
  --no-address \
  --tags=nginx \
  --image-family=debian-12 --image-project=debian-cloud

echo "Installing NGINX..."
gcloud compute ssh $NGINX_VM --project=$PROJECT_ID --zone=$ZONE --tunnel-through-iap --command "
sudo apt update && sudo apt install -y nginx && sudo systemctl enable --now nginx
"

# -------------------------
echo "Creating Instance Group for NGINX..."
gcloud compute instance-groups unmanaged create $IG_NAME --project=$PROJECT_ID --zone=$ZONE
gcloud compute instance-groups unmanaged add-instances $IG_NAME --instances=$NGINX_VM --zone=$ZONE --project=$PROJECT_ID

# -------------------------
echo "Creating Health Check..."
gcloud compute health-checks create http $HC_NAME --project=$PROJECT_ID --port=80

# -------------------------
echo "Creating Backend Service..."
gcloud compute backend-services create $BS_NAME \
  --project=$PROJECT_ID --region=$REGION \
  --protocol=HTTP --load-balancing-scheme=INTERNAL_MANAGED \
  --health-checks=$HC_NAME

gcloud com
