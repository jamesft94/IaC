#!/usr/bin/env bash

set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly ROOT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
readonly ANSIBLE_VARS="$ROOT_DIR/ansible/vars/vars.yaml"

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

command -v ansible-playbook >/dev/null 2>&1 || die "ansible-playbook is not installed."
command -v terraform >/dev/null 2>&1 || die "terraform is not installed."

mkdir -p "$(dirname "$ANSIBLE_VARS")"
touch "$ANSIBLE_VARS"

read_yaml_value() {
    local key="$1"
    awk -v key="$key" '$0 ~ "^[[:space:]]*" key ":[[:space:]]*" {
        sub("^[[:space:]]*" key ":[[:space:]]*", "")
        print
        exit
    }' "$ANSIBLE_VARS"
}

read_tfvar_value() {
    local file="$1" key="$2"
    [[ -f "$file" ]] || return 0
    awk -v key="$key" '$0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
        sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "")
        gsub(/^[\" ]+|[\" ]+$/, "")
        print
        exit
    }' "$file"
}

write_yaml_value() {
    local key="$1" value="$2" escaped
    escaped=${value//\\/\\\\}
    escaped=${escaped//&/\\&}
    if grep -qE "^[[:space:]]*${key}:" "$ANSIBLE_VARS"; then
        sed -i -E "s|^[[:space:]]*${key}:.*|${key}: ${escaped}|" "$ANSIBLE_VARS"
    else
        printf '%s: %s\n' "$key" "$escaped" >> "$ANSIBLE_VARS"
    fi
}

write_tfvar_value() {
    local file="$1" key="$2" value="$3" escaped rendered
    escaped=${value//\\/\\\\}
    escaped=${escaped//\"/\\\"}
    if [[ "$value" =~ ^\[.*\]$ ]]; then
        rendered="$value"
    else
        rendered="\"$escaped\""
    fi
    mkdir -p "$(dirname "$file")"
    touch "$file"
    if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$file"; then
        sed -i -E "s|^[[:space:]]*${key}[[:space:]]*=.*|${key} = ${rendered}|" "$file"
    else
        printf '%s = %s\n' "$key" "$rendered" >> "$file"
    fi
}

prompt_value() {
    local prompt="$1" current="$2" secret="${3:-false}" answer
    if [[ -n "$current" ]]; then
        printf '%s [%s]: ' "$prompt" "$([[ "$secret" == true ]] && printf 'configured' || printf '%s' "$current")"
    else
        printf '%s: ' "$prompt"
    fi
    if [[ "$secret" == true ]]; then
        read -r -s answer
        printf '\n'
    else
        read -r answer
    fi
    printf '%s' "${answer:-$current}"
}

choose_provider() {
    printf '\nChoose a cloud provider:\n'
    printf '  1) Amazon Web Services (AWS)\n'
    printf '  2) Microsoft Azure\n'
    printf '  3) Google Cloud Platform (GCP)\n\n'
    local choice
    read -r -p 'Provider [1-3]: ' choice
    case "$choice" in
        1) CLOUD_PROVIDER=aws; PROVIDER_NAME='Amazon Web Services (AWS)' ;;
        2) CLOUD_PROVIDER=azure; PROVIDER_NAME='Microsoft Azure' ;;
        3) CLOUD_PROVIDER=gcp; PROVIDER_NAME='Google Cloud Platform (GCP)' ;;
        *) die 'Please choose 1, 2, or 3.' ;;
    esac
}

show_defaults() {
    printf '\nDefault Terraform variables for %s:\n' "$PROVIDER_NAME"
    case "$CLOUD_PROVIDER" in
        aws)
            printf '  region=eu-north-1, vnet_name=vnet-demo, address_space=10.0.0.0/16\n'
            printf '  subnet_prefix=10.0.1.0/24, vm_name=test-compute, vm_size=t3.small\n'
            printf '  pubkey=~/.ssh/id_rsa.pub\n'
            ;;
        azure)
            printf '  location=eastus, resource_group_name=rg-demo-terraform, vnet_name=vnet-demo\n'
            printf '  address_space=[10.0.0.0/16], subnet_prefix=[10.0.1.0/24]\n'
            printf '  vm_name=vm-demo, vm_size=Standard_D2als_v7, admin_username=azureadmin\n'
            printf '  pubkey=~/.ssh/id_rsa.pub\n'
            ;;
        gcp)
            printf '  region=us-central1, zone=us-central1-c, vnet_name=vnet-demo\n'
            printf '  address_space=[10.0.0.0/16], subnet_prefix=[10.0.1.0/24]\n'
            printf '  vm_name=demo-compute, vm_size=e2-micro, admin_username=test-user\n'
            printf '  image-os=ubuntu-os-cloud/ubuntu-2404-lts-amd64, OS-disk-type=pd-standard\n'
            ;;
    esac
}

ensure_shared_values() {
    local api_key api_addr vm_user vm_password
    api_key=$(read_yaml_value api_key || true)
    api_addr=$(read_yaml_value api_addr || true)
    vm_user=$(read_yaml_value vm_user || true)
    vm_password=$(read_yaml_value vm_password || true)

    [[ -n "$api_key" ]] || api_key=$(prompt_value 'Private API key' '' true)
    [[ -n "$api_addr" ]] || api_addr=$(prompt_value 'Private API address' '')
    [[ -n "$vm_user" ]] || vm_user=$(prompt_value 'VM username' '')
    [[ -n "$vm_password" ]] || vm_password=$(prompt_value 'VM password' '' true)

    write_yaml_value api_key "$api_key"
    write_yaml_value api_addr "$api_addr"
    write_yaml_value vm_user "$vm_user"
    write_yaml_value vm_password "$vm_password"
}

ensure_provider_secrets() {
    local tf_dir="$ROOT_DIR/terraform/$CLOUD_PROVIDER"
    local secrets="$tf_dir/secrets.auto.tfvars"
    local tailnet_key pubkey admin_password gcp_project_id

    tailnet_key=$(read_tfvar_value "$secrets" 'tailnet-key' || true)
    [[ -n "$tailnet_key" ]] || tailnet_key=$(prompt_value 'Tailscale auth key' '' true)
    write_tfvar_value "$secrets" 'tailnet-key' "$tailnet_key"

    case "$CLOUD_PROVIDER" in
        aws)
            pubkey=$(read_tfvar_value "$secrets" pubkey || true)
            [[ -n "$pubkey" ]] || pubkey=$(prompt_value 'SSH public key path' "$HOME/.ssh/id_rsa.pub")
            write_tfvar_value "$secrets" pubkey "$pubkey"
            ;;
        azure)
            admin_password=$(read_tfvar_value "$secrets" admin_password || true)
            [[ -n "$admin_password" ]] || admin_password=$(prompt_value 'Azure admin password' '' true)
            write_tfvar_value "$secrets" admin_password "$admin_password"
            ;;
        gcp)
            gcp_project_id=$(read_tfvar_value "$secrets" gcp_project_id || true)
            [[ -n "$gcp_project_id" ]] || gcp_project_id=$(prompt_value 'GCP project ID' '')
            write_tfvar_value "$secrets" gcp_project_id "$gcp_project_id"
            ;;
    esac
}

configure_defaults_or_guided() {
    local mode
    show_defaults
    printf '\nTerraform uses these defaults unless values are set in %s.\n' "terraform/$CLOUD_PROVIDER/secrets.auto.tfvars"
    printf 'You can edit the variable files directly before continuing.\n'
    read -r -p 'Use defaults? [Y/n] ' mode
    [[ "$mode" =~ ^[Nn]$ ]] || return 0

    local tf_dir="$ROOT_DIR/terraform/$CLOUD_PROVIDER" key current value
    case "$CLOUD_PROVIDER" in
        aws) keys=(region vnet_name address_space subnet_prefix vm_name vm_size pubkey) ;;
        azure) keys=(location resource_group_name vnet_name address_space subnet_prefix vm_name vm_size admin_username pubkey) ;;
        gcp) keys=(region zone gcp_project_id vnet_name address_space subnet_prefix vm_name vm_size admin_username image-os OS-disk-type) ;;
    esac
    for key in "${keys[@]}"; do
        current=$(read_tfvar_value "$tf_dir/secrets.auto.tfvars" "$key" || true)
        value=$(prompt_value "$key" "$current")
        [[ -n "$value" ]] && write_tfvar_value "$tf_dir/secrets.auto.tfvars" "$key" "$value"
    done
}

check_tailscale() {
    if ! command -v tailscale >/dev/null 2>&1; then
        printf 'Warning: tailscale is not installed; this workflow expects Tailscale to be available.\n' >&2
        return
    fi
    if ! tailscale status >/dev/null 2>&1; then
        printf 'Warning: Tailscale does not appear to be up. The workflow is intended to run with Tailscale available.\n' >&2
    else
        printf 'Tailscale is up.\n'
    fi
}

choose_provider
check_tailscale
ensure_shared_values
ensure_provider_secrets
configure_defaults_or_guided

printf '\nStarting Terraform and Ansible for %s...\n' "$PROVIDER_NAME"
cd "$ROOT_DIR"
exec ansible-playbook ansible/ansible.yaml -e "cloud_provider=$CLOUD_PROVIDER"