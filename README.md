# Infrastructure as Code (IaC)

A personal learning project for exploring and implementing Infrastructure as Code (IaC) and infrastructure solutions. This repository is public for visibility and knowledge sharing.

## Overview

This project uses Infrastructure as Code principles to manage, version control, and automate infrastructure provisioning and management. It's a hands-on learning exercise in modern infrastructure practices and cloud automation patterns.

## Features

- **Infrastructure Automation**: Automated provisioning and configuration of cloud resources
- **Version Control**: All infrastructure changes tracked and versioned
- **Reproducibility**: Consistent and repeatable infrastructure deployments
- **Documentation**: Clear documentation of infrastructure architecture
- **Best Practices**: Follows industry standards and best practices for IaC

## Directory Structure & Files

**Current Structure:**
```
.
├── README.md                    # This file
├── ansible.yaml                 # Ansible playbook for VM configuration
├── main.tf                      # Terraform main configuration
├── variables.tf                 # Terraform variable definitions
├── output.tf                    # Terraform output definitions
├── locals.tf                    # Terraform local variables
├── secrets.auto.tfvars          # Terraform secrets (DO NOT COMMIT)
├── vars.yaml                    # Ansible variables & API credentials (DO NOT COMMIT)
├── vars.yaml.example            # Template for vars.yaml
├── tfplan.json                  # Terraform plan output
└── terraform.tfstate            # Terraform state (DO NOT COMMIT)
```

**Note:** The directory structure for environments (dev/staging/production) has not been fully implemented yet. Current configuration is structured at the root level.

## Prerequisites

- **Terraform** - Infrastructure provisioning
- **Ansible** - VM configuration and orchestration
- **Azure CLI** - For authentication to Azure (if using Azure)
- **Git** - Version control
- Azure credentials/subscription (if deploying to Azure)
- SSH key access to Azure VM

## Getting Started

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd IaC
   ```

2. **Set up variables and secrets**
   - Copy `vars.yaml.example` to `vars.yaml` and fill in the required fields:
     ```bash
     cp vars.yaml.example vars.yaml
     ```
   - Edit `vars.yaml` with your actual credentials:
     - `api_key` - Your private API authentication key
     - `api_addr` - Your webhook API endpoint address
     - `vm_user` - Azure VM username
     - `vm_password` - Azure VM password (must match `secrets.auto.tfvars`)

3. **Configure Terraform secrets**
   - Update or create `secrets.auto.tfvars` with your Azure VM password:
     ```hcl
     admin_password = "your-vm-password"
     ```

4. **Review configurations**
   - Check `main.tf`, `variables.tf`, and `locals.tf` for infrastructure settings
   - Review `ansible.yaml` for VM provisioning steps

5. **Deploy infrastructure**
   ```bash
   # Initialize Terraform
   terraform init
   
   # Plan infrastructure changes
   terraform plan -out=tfplan.out
   
   # Apply infrastructure changes
   terraform apply tfplan.out
   
   # Run Ansible playbook for VM configuration
   ansible-playbook ansible.yaml
   ```

## Configuration Files

### Terraform Files
- **variables.tf** - Defines all Terraform input variables (location, resource group, network settings, etc.)
- **main.tf** - Main infrastructure configuration for provisioning Azure resources
- **output.tf** - Outputs from Terraform (e.g., VM IP address, resource IDs)
- **locals.tf** - Local values and computed values used in Terraform
- **secrets.auto.tfvars** - Sensitive values automatically loaded by Terraform (VM password)

### Ansible Files
- **ansible.yaml** - Playbook for configuring the VM after it's provisioned by Terraform
- **vars.yaml** - Variables for Ansible including:
  - API credentials (api_key, api_addr) for webhook integration
  - VM credentials (vm_user, vm_password)
  - Terraform metadata (tf_dir, tf_plan_file, tf_plan_json)

### Variable Files
- **vars.yaml.example** - Template file showing required variables structure
  - Copy to `vars.yaml` and fill in your actual values
  - Never commit `vars.yaml` to version control (contains secrets)

## Usage & Attribution

This project is free to use and adapt for your own infrastructure needs. If you find it useful and use it in your own projects, attribution is appreciated but not required.

Refer to the documentation in each environment or module directory for specific usage instructions.

## Security

**CRITICAL: Do NOT commit the following files to version control:**
- `secrets.auto.tfvars` - Contains Azure VM password
- `vars.yaml` - Contains API credentials and VM password
- `terraform.tfstate` and `terraform.tfstate.backup` - Contain infrastructure state with sensitive data
- `.terraform/` directory - Contains provider configurations and cached modules

**Best Practices:**
- Use `.gitignore` to exclude sensitive files
- Never hardcode credentials in code
- Ensure `vars.yaml` and `secrets.auto.tfvars` are in your `.gitignore`
- Review all infrastructure changes before applying to production
- Use environment variables or secure vaults for managing secrets in CI/CD pipelines
- Store the actual files securely (1Password, LastPass, encrypted storage, etc.)

## Webhook API Integration

This project integrates with a private webhook API (`api_addr`) authenticated via `api_key`. The API processes requests and responds using simple bash scripts. Logs of API interactions are maintained by the webhook service.

## Disclaimer

This is a personal learning project. While the infrastructure patterns and practices demonstrated here are solid, use at your own discretion. Always test thoroughly in non-production environments before deploying to production infrastructure.

## License

This project is provided as-is for educational and personal use. Feel free to use, modify, and distribute the code. Attribution is appreciated if you use this in your own projects.

For full details on permissions and limitations, consider adopting a standard open-source license (e.g., MIT, Apache 2.0) if you haven't already.
