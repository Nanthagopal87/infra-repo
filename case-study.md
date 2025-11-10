Got it.
I’ll give you a **single, one-shot Bash setup script** that:

* Creates **two VPCs** (Producer + Consumer) in the **same project**
* Creates **Cloud NAT** for private VM outbound internet
* Creates **internal-only NGINX VM**
* Creates **Internal Load Balancer**
* Creates **PSC Service Attachment**
* Creates **PSC Endpoint in Consumer VPC**
* Creates **Consumer test VM**
* Verifies **curl works** privately end-to-end

---

### ✅ Before Running — Set Your Values

Choose region & zones:

```
PROJECT_ID="your-project-id"
REGION="asia-south1"
ZONE="${REGION}-a"
```

---

### 🚀 **FULL AUTOMATED SETUP SCRIPT**

Copy → paste into **Cloud Shell**:

```bash
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
echo "Creating Instance Group..."
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

gcloud compute backend-services add-backend $BS_NAME \
  --project=$PROJECT_ID --region=$REGION \
  --instance-group=$IG_NAME --instance-group-region=$REGION

# -------------------------
echo "Creating Internal Load Balancer..."
gcloud compute addresses create $ILB_IP \
  --project=$PROJECT_ID --region=$REGION --subnet=$PROD_SUBNET

gcloud compute forwarding-rules create $ILB_FR \
  --project=$PROJECT_ID --region=$REGION \
  --load-balancing-scheme=INTERNAL_MANAGED \
  --address=$ILB_IP --ports=80 \
  --backend-service=$BS_NAME

# -------------------------
echo "Creating PSC NAT Subnet..."
gcloud compute networks subnets create $PSC_NAT_SUBNET \
  --project=$PROJECT_ID --region=$REGION \
  --network=$PROD_VPC --range=10.0.1.0/28 \
  --purpose=PRIVATE_SERVICE_CONNECT

# -------------------------
echo "Creating Service Attachment..."
gcloud compute service-attachments create $SA_NAME \
  --project=$PROJECT_ID --region=$REGION \
  --producer-forwarding-rule=$ILB_FR \
  --connection-preference=ACCEPT_AUTOMATIC \
  --nat-subnets=$PSC_NAT_SUBNET

SA_URI=$(gcloud compute service-attachments describe $SA_NAME \
  --project=$PROJECT_ID --region=$REGION --format="value(selfLink)")

# -------------------------
echo "Creating PSC Endpoint in Consumer VPC..."
gcloud compute addresses create $PSC_EP_IP \
  --project=$PROJECT_ID --region=$REGION --subnet=$CONS_SUBNET

gcloud compute forwarding-rules create $PSC_EP_FR \
  --project=$PROJECT_ID --region=$REGION \
  --network=$CONS_VPC --address=$PSC_EP_IP --ports=80 \
  --target-service-attachment=$SA_URI

# -------------------------
echo "Creating Consumer Test VM..."
gcloud compute instances create $CLIENT_VM \
  --project=$PROJECT_ID --zone=$ZONE \
  --machine-type=e2-micro \
  --subnet=$CONS_SUBNET \
  --no-address

EP_IP=$(gcloud compute addresses describe $PSC_EP_IP --project=$PROJECT_ID --region=$REGION --format="value(address)")

echo "Testing connection from consumer VM..."
gcloud compute ssh $CLIENT_VM --project=$PROJECT_ID --zone=$ZONE --tunnel-through-iap --command "
curl -v http://$EP_IP
"

echo "✅ PSC setup completed successfully."
```

---

## ✅ Expected Output

* The final `curl` command prints the **NGINX Welcome Page HTML**
* No VM has external IPs
* Traffic flows **private → PSC → ILB → NGINX**

---

## 🎯 Next Options

Would you like me to also provide:

**A. Architecture Diagram (PNG)**
**B. Terraform Version**
**C. GitLab CI pipeline to deploy this**

Reply: **A**, **B**, or **C**.
