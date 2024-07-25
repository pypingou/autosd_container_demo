#!/bin/bash

# Build the container
podman build -t app:v2 .

# Generate an uuid for this transaction
u=uuid

# create a folder for that transaction
mkdir $u

# Save that container into an archive
podman save --format=oci-archive -o $u/app_v2.tar.gz localhost/app:v2

# Sign the quadlet file
# Requires validator, available from:
# https://copr.fedorainfracloud.org/coprs/g/centos-automotive-sig/validator/
# dnf copr enable @centos-automotive-sig/validator && dnf install validator
validator sign --key=../secret.pem app_v2.container

# Insert the new quadlet file and its signature into the transaction
cp app_v2.container app_v2.container.sig $u/

# Create a tarball of that
tar cvfz $u.tar.gz $u

