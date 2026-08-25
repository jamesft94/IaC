# Infrastructure as Code (IaC)

A personal learning project for exploring and implementing Infrastructure as Code (IaC) and infrastructure solutions. This repository is public for visibility and knowledge sharing.

## Overview

This project is an automated infrastructure workflow that uses **Ansible to orchestrate Terraform** for temporary infrastructure provisioning. The workflow provisions a complete AWS, Azure, or GCP infrastructure stack, tests the deployment by making API calls to a private webhook endpoint, and lets the user decide whether to destroy the stack afterward. It's a hands-on learning exercise in infrastructure automation, IaC practices, and API integration patterns.

## Features

- **Ansible-Driven Orchestration**: Ansible triggers and manages the complete Terraform workflow
- **Automated Provisioning**: Terraform provisions AWS, Azure, or GCP infrastructure in the selected provider directory
- **Private API Integration**: Tests the provisioned VM by calling a private webhook API with custom authentication
- **Optional Cleanup**: The launcher asks whether to destroy resources after testing
- **Temporary Infrastructure**: Ideal for testing, validation, and temporary deployments
- **Webhook Testing**: Validates infrastructure by executing bash scripts on the private API server and recording results

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
   - Review `ansible.yaml` for orchestration and API integration steps

5. **Run the Ansible playbook**
   ```bash
   # This triggers the complete workflow: provision → test → destroy
   ansible-playbook ansible/ansible.yaml -e cloud_provider=azure
   ```
   Or use the interactive launcher, which checks provider-specific secrets and
   variables before starting the playbook:
   ```bash
   ./scripts/start.sh
   ```
   The playbook will:
   - Initialize and validate Terraform
   - Provision infrastructure in the selected cloud provider directory
   - Extract the Tailscale hostname of the created VM
   - Connect to the VM over Tailscale
   - Test the VM and call your private API endpoints
   - Destroy all resources (even if tests fail)

## Configuration Files

### Terraform Files
- **variables.tf** - Defines all Terraform input variables (location, resource group, network settings, etc.)
- **main.tf** - Main infrastructure configuration for provisioning Azure resources
- **output.tf** - Outputs from Terraform (e.g., VM IP address, resource IDs)
- **locals.tf** - Local values and computed values used in Terraform
- **secrets.auto.tfvars** - Sensitive values automatically loaded by Terraform (VM password)

### Ansible Files
- **ansible.yaml** - Complete orchestration playbook that:
  - Runs Terraform to provision infrastructure
  - Performs validation checks on the VM (uptime, disk space, connectivity)
  - Calls private webhook API endpoints to test system status and execute bash scripts
   - Passes cleanup control to the interactive launcher after the workflow completes
- **vars.yaml** - Variables for Ansible and Terraform including:
  - API credentials (api_key, api_addr) for webhook authentication
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

## Workflow Execution

When you run `ansible-playbook ansible/ansible.yaml -e cloud_provider=<aws|azure|gcp>`, the following sequence occurs:

1. **Terraform Initialization & Planning**
   - Formats and validates Terraform configuration
   - Creates a plan of resources to be provisioned
   - Converts the plan to JSON for inspection

2. **Infrastructure Provisioning**
   - Applies the Terraform plan on Azure
   - Creates the resources defined in `terraform/<cloud_provider>`
   - Terraform outputs the VM's Tailscale hostname

3. **VM Connectivity & Testing**
   - Waits for SSH port (22) to become available on the new VM
   - Performs connectivity tests (ping, uptime check, disk space check)
   - Tests external connectivity (google.com)

4. **Webhook API Integration**
   - Makes authenticated requests to your private webhook endpoint
   - Calls multiple endpoints: `/metrics`, `/8ball`, `/whoami`, `/roast`
   - Sends VM information including:
   - Tailscale hostname
     - VM username and connectivity status
     - System uptime and disk space
     - Google connectivity status
   - The webhook server receives requests, executes bash scripts to process data, and maintains logs

5. **Automatic Cleanup**
   - Asks whether to run `terraform destroy` after the workflow completes
   - Leaves resources running when cleanup is declined
   - Ensures no resources are left running

## Webhook API Integration

This project integrates with a private webhook API (`api_addr`) authenticated via `api_key`. The webhook server:
- Receives POST requests from the provisioned VM
- Executes simple bash scripts to process requests
- Records data, metrics, and responses in server logs
- Responds with status information back to the Ansible playbook

The API is called with authentication headers and JSON payloads containing infrastructure metadata for testing and logging purposes.

## Disclaimer

This is a personal learning project. While the infrastructure patterns and practices demonstrated here are solid, use at your own discretion. Always test thoroughly in non-production environments before deploying to production infrastructure.

## License

This project is provided as-is for educational and personal use. Feel free to use, modify, and distribute the code. Attribution is appreciated if you use this in your own projects.
