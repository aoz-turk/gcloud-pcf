#!/bin/bash

set -eu

network_assignment="$(jq -n \
  --arg azs "$AZS" \
  '
  {
    "network": {
      "name": "Services"
    },
    "service_network": {
      "name": "DynamicServices"
    },
    "other_availability_zones": ($azs | split(",") | map({name: .})),
    "singleton_availability_zone": ($azs | split(",") | map({name: .})) | .[0]
  }
  '
  )"

properties="$(jq -n \
  --arg opsman_url "https://$OPSMAN_DOMAIN_OR_IP_ADDRESS" \
  --arg azs "$AZS" \
  --arg backup_server_ssh_user "$BACKUP_SERVER_SSH_USER" \
  --arg backup_server_ssh_private_key "$BACKUP_SERVER_SSH_PRIVATE_KEY" \
  --arg backup_server_ssh_host "$BACKUP_SERVER_SSH_HOST" \
  --arg backup_server_ssh_directory "$BACKUP_SERVER_SSH_DIRECTORY" \
  --arg backup_cron_schedule "$BACKUP_CRON_SCHEDULE" \
  '
  {
    ".properties.plan1_selector.active.az_multi_select": {
      "value": $azs | split(",")
    },
    ".properties.plan2_selector.active.az_multi_select": {
      "value": $azs | split(",")
    },
    ".properties.plan3_selector.active.az_multi_select": {
      "value": $azs | split(",")
    },
    ".properties.backups_selector": {
      "value": "SCP Backups"
    },
    ".properties.backups_selector.scp.cron_schedule": {
      "value": $backup_cron_schedule
    },
    ".properties.backups_selector.scp.user": {
      "value": $backup_server_ssh_user
    },
    ".properties.backups_selector.scp.key": {
      "value": $backup_server_ssh_private_key
    },
    ".properties.backups_selector.scp.server": {
      "value": $backup_server_ssh_host
    },
    ".properties.backups_selector.scp.destination": {
      "value": $backup_server_ssh_directory
    },
    ".properties.backups_selector.scp.port": {
      "value": "22"
    }
  }
  '
)"

om-linux \
  --target "https://$OPSMAN_DOMAIN_OR_IP_ADDRESS" \
  --username "$OPSMAN_USERNAME" \
  --password "$OPSMAN_PASSWORD" \
  --skip-ssl-validation \
  configure-product \
  --product-name pivotal-mysql \
  --product-network "$network_assignment" \
  --product-properties "$properties"
