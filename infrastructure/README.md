# Infrastructure

This directory contains the Terraform configuration for provisioning the Azure infrastructure for the Disaster Relief Platform.

## Multi-Environment Architecture

This architecture supports `dev`, `uat`, `qa`, and `prod` environments within a single Azure subscription using isolated states (Workspaces) and environment-specific variable files.

### Network Architecture
The network is partitioned into strictly isolated **Application** and **Database** subnet tiers. 
- Network Security Groups (NSGs) prevent the Database tier from being accessed from the internet.
- Only the Application subnets have permission to communicate with the DB subnets over standard database ports.

### Deployment Workflow

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Select the Environment Workspace:**
   Using separate workspaces ensures that the `.tfstate` files for each environment remain totally separate, avoiding accidental cross-environment modifications.
   ```bash
   terraform workspace select dev || terraform workspace new dev
   ```

3. **Plan the Deployment:**
   Always pass the respective `.tfvars` file for your target environment.
   ```bash
   terraform plan -var-file="environments/dev.tfvars"
   ```

4. **Apply the Changes:**
   ```bash
   terraform apply -var-file="environments/dev.tfvars"
   ```
