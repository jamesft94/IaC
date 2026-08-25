# Infrastructure as Code (IaC)

This project provisions temporary Linux VM environments on Amazon Web Services (AWS), Microsoft Azure, or Google Cloud Platform (GCP). Terraform creates the cloud infrastructure, cloud-init installs and registers Tailscale, and Ansible verifies the VM and calls a private webhook API. The interactive launcher selects the provider, prepares configuration, runs Ansible, and optionally destroys the Terraform stack afterward.

## What It Does

- Provisions one provider-specific infrastructure stack from `terraform/aws`, `terraform/azure`, or `terraform/gcp`.
- Uses Tailscale as the VM network path instead of relying on a public IP for Ansible access.
- Uses regular SSH over Tailscale with the configured private key. Tailscale SSH is disabled because SSH authorization is handled by the VM.
- Waits up to 10 minutes for the VM to become reachable before running checks.
- Tests VM connectivity, uptime, disk space, and outbound access to Google.
- Sends test data to the configured private API endpoints.
- Lets the user decide whether to run Terraform destroy after the workflow.

## Repository Layout

```text
.
├── ansible/
│   ├── ansible.yaml              # Terraform, connectivity, and API workflow
│   ├── requirements.yml          # Required Ansible collections
│   └── vars/                     # Ansible API and SSH configuration
├── common/cloud-init.yaml        # Installs and configures Tailscale on VMs
├── terraform/
│   ├── aws/                      # AWS VPC, NAT, security group, and EC2 VM
│   ├── azure/                    # Azure network, NAT, and Linux VM
│   └── gcp/                      # GCP network, Cloud NAT, and Compute Engine VM
├── scripts/start.sh              # Interactive entry point
└── README.md
```

Terraform state, provider lock files, secrets, and generated plan files are kept in their respective provider directories. Do not commit credentials, state files, or `.tfvars` files.

## Prerequisites

Install these tools on the machine that runs the workflow:

- **Terraform CLI**, version 1.5 or newer.
- **Ansible Core**, including the `ansible-playbook` command.
- **Ansible `community.general` collection**:
  ```bash
  ansible-galaxy collection install -r ansible/requirements.yml
  ```
- **Bash** and standard Unix tools such as `awk`, `sed`, `grep`, and `ssh`.
- **Tailscale**, logged into the tailnet used by the VMs. The launcher checks Tailscale status. In WSL, it can use the Windows Tailscale CLI at `C:\Program Files\Tailscale\tailscale.exe`.
- An SSH key pair. AWS and Azure Terraform configurations install the public key on the VM, and Ansible uses the private key over Tailscale. The default private-key path is `.ssh/id_rsa` in this repository. GCP requires equivalent user and key bootstrap configuration for the selected image.

Install and authenticate the CLI for the provider you intend to use:

- **AWS:** AWS CLI, authenticated with a profile or environment variables that can manage VPC, EC2, Elastic IP, NAT gateway, and related resources. For example, run `aws configure` or set `AWS_PROFILE`.
- **Azure:** Azure CLI, authenticated with `az login`, with access to create the resource group, network, public IP, NAT gateway, and VM in the selected subscription. Set the subscription with `az account set --subscription <subscription-id>` when needed.
- **GCP:** Google Cloud CLI, authenticated with `gcloud auth application-default login` or suitable service-account credentials. The account needs a project with billing enabled and permissions for Compute Engine, VPC, Cloud NAT, and related resources. Set the project with `gcloud config set project <project-id>`.

The active cloud account must also have permission to use the selected region or zone and to create the resources defined by that provider module.

## Configuration

The launcher checks and prompts for values before starting:

- `ansible/vars/vars.yaml`: `api_key`, `api_addr`, and `vm_private_key`.
- `terraform/aws/secrets.auto.tfvars`: `tailnet-key` and `pubkey`.
- `terraform/azure/secrets.auto.tfvars`: `tailnet-key`, `pubkey`, and `admin_password`.
- `terraform/gcp/secrets.auto.tfvars`: `tailnet-key` and `gcp_project_id`.

Copy the Ansible example if needed:

```bash
cp ansible/vars/vars.yaml.example ansible/vars/vars.yaml
```

The launcher shows the provider's Terraform defaults and offers either to keep them or define Terraform variables one by one. You can also edit the provider's `variables.tf` defaults and `secrets.auto.tfvars` directly before running.

Terraform supplies the effective VM SSH username to Ansible after apply:

- AWS uses `ubuntu`, the default user in the Canonical Ubuntu image used by the module.
- Azure uses `admin_username`.
- GCP uses `admin_username`; ensure the selected GCP image/bootstrap creates that OS user and authorizes the matching key before relying on it.

## Running the Workflow

Use the interactive launcher from the repository root:

```bash
./scripts/start.sh
```

It will:

1. Ask whether to use AWS, Azure, or GCP.
2. Check Tailscale and required configuration values.
3. Show provider defaults and optionally prompt for overrides.
4. Run `ansible/ansible.yaml` with the selected provider.
5. Wait for Tailscale DNS and regular SSH connectivity to become available.
6. Ask whether to destroy the entire selected Terraform stack.

The playbook can also be run directly when configuration is already prepared:

```bash
ansible-playbook ansible/ansible.yaml -e cloud_provider=azure
```

Direct playbook execution does not prompt for cleanup. Use the launcher when you want the post-run destroy question.

## Cloud Resources

Each provider module is independent and must be initialized and applied from its own directory. The Ansible playbook selects the directory from `cloud_provider` and runs Terraform formatting, validation, planning, and apply there.

The VM receives a Tailscale hostname based on `vm_name`. Cloud-init installs Tailscale and registers the VM with the supplied `tailnet-key`. Because regular SSH is used over Tailscale, the VM must have the corresponding public key and SSH user configured.

## Security and Cleanup

Never commit:

- `terraform/*/secrets.auto.tfvars`
- `ansible/vars/vars.yaml`
- Terraform state files and backups
- Terraform plan files
- Tailscale auth keys, cloud credentials, API keys, or VM passwords

The launcher uses `terraform destroy -auto-approve` only after the user confirms cleanup. If cleanup is declined, the stack remains running and must be destroyed later from the matching provider directory:

```bash
terraform -chdir=terraform/<aws|azure|gcp> destroy
```

Review the plan before applying changes, and use short-lived credentials and an ephemeral Tailscale auth key where possible.

## Webhook Checks

The playbook sends authenticated POST requests to the configured `api_addr` for:

```text
/metrics
/8ball
/whoami
/roast
```

The requests include the Tailscale hostname, VM username, uptime, disk-space output, and external connectivity status.

## License

This project is provided as-is for educational and personal use.