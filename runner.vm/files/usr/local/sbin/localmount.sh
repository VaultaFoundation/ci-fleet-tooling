#!/bin/bash

set -euo pipefail
set -x

mkdir -p /var/lib/docker

# sadly the documented "google-local-nvme-ssd-x" name is something plumbed through custom udev rules and even a custom
# script (google_nvme_id) in GCP's images. Look for hex of nvme_card[0-9]+ which won't match a persistent disk that
# gets hex of nvme_card-pd
readarray -d '' LOCAL_NVME_DRIVES < <(find /dev/disk/by-id -regextype egrep -regex '.*\/nvme-nvme\.1ae0-6e766d655f63617264(3[0-9a-f-]+|-)[0-9a-f-]+' -print0)

echo Found ${#LOCAL_NVME_DRIVES[@]} local NVMe drives

if (( ${#LOCAL_NVME_DRIVES[@]} == 0 )); then
   mount -t tmpfs tmpfs /var/lib/docker
elif (( ${#LOCAL_NVME_DRIVES[@]} == 1 )); then
   mkfs.xfs -f "${LOCAL_NVME_DRIVES[0]}"
   mount "${LOCAL_NVME_DRIVES[0]}" /var/lib/docker
else
   mdadm -B /dev/md0 -f -n ${#LOCAL_NVME_DRIVES[@]} -l 0 "${LOCAL_NVME_DRIVES[@]}"
   mkfs.xfs -f /dev/md0
   mount /dev/md0 /var/lib/docker
fi
