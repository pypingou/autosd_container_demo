AutoSD Container Demo
=====================

Context
-------

This project contains the osbuild manifest (and its associated files)
allowing to build and AutoSD OS image that has the following
characteristics:
* It can be built as image mode with composefs enabled
* It comes with a containerized "apps" built-in (service name: app_v1)
* It has the [validator](https://github.com/containers/validator) project
  installed and pre-configured
* It has a script: `/usr/bin/install_app` built-in.

The goal of this image is to provide a demonstration of AutoSD's
capabilities of being secured and tamperproof while also giving the
flexibility of installing and updating containerized applications.

Building the image
------------------

Building the image relies on the [automotive-image-builder](https://gitlab.com/CentOS/automotive/src/automotive-image-builder)
project and tooling as well as `git` and `podman` being installed and
available on the system.

You can build the OS image by simply doing:

```
git clone https://gitlab.com/CentOS/automotive/src/automotive-image-builder.git
git clone https://github.com/pypingou/autosd_container_demo.git
cd automotive-image-builder
./automotive-image-builder \
    --container build \
    --distro autosd9 \
    --target qemu \
    --export qcow2 \
    --mode image \
    ../autosd_container_demo/mycontainer.mpp.yml image.qcow2
```

Running the image
-----------------

In the command above we've created a `qcow2` targetting qemu/kvm, this
means we can easily run that image on a system where qemu/kvm is available.

[automotive-image-builder](https://gitlab.com/CentOS/automotive/src/automotive-image-builder)
provides a convenient tool to make it easy to run these images.
Assuming you already have a local copy of automotive-image-builder, you
can simply do:

```
cd automotive-image-builder
./automotive-image-runner --nographics image.qcow2
```

Installing a demo app
---------------------

We have a tarball with a demo "app" available that can be used.

Here are the commands you can follow to install this app:

```
# Download application and its signature
wget https://pingou.fedorapeople.org/a3.tar.gz
wget https://pingou.fedorapeople.org/a3.tar.gz.sig

# Check its signature
validator -v validate --key /usr/lib/validator/keys/etc.key a3.tar.gz

# Install the application
bash /usr/bin/install_app a3.tar.gz
systemctl restart validator

# Show that nothing changed
systemctl status fedora-minimal

# Reload
systemctl daemon-reload

# New app is there \ó/
systemctl status fedora-minimal
systemctl start fedora-minimal
systemctl status fedora-minimal
```

TODO and Knonw issues
---------------------

TODO
* Move the validation of the tarball/app into the install_app script
  (there is no need to keep it separate)

Known issues:
* Validator was originally intended to run into dracut, the idea is to run
  validator before the systemd generator are ran, this way validator
  installs the quadlet files before the quadlet generator is ran and
  converts them into systemd service files. The issue is that, I could not
  make it work in dracut as in dracut the view of the filesystem is limited
  and I could not find how to access the content that will end up being
  in `/var` or `/opt`. In other words, I was not able to make validator
  find the files the validate and install. I've thus moved it to a regular
  systemd service file that is executed before `basic.target` in the boot
  chain, but that's already too late, the quadlet generator has already
  ran. This means that currently, we need to execute a `systemctl daemon-reload`
  after the `validator` service is ran. We could automate this by adding
  `ExecStartPost=systemctl daemon-reload` in `validator.service`, we would
  then need to consider "restarting validator" as the action one would have
  to do move from the running transaction to the next one.
