AutoSD Container Demo
=====================

Context
-------

This project contains the osbuild manifest (and its associated files)
allowing to build and AutoSD OS image that has the following
characteristics:
* It can be built as image mode with composefs enabled
* It comes with a containerized "apps" built-in (service name: app_v1)
* It has the [validator|https://github.com/containers/validator] project
  installed and pre-configured
* It has a script: `/usr/bin/install_app` built-in.

The goal of this image is to provide a demonstration of AutoSD's
capabilities of being secured and tamperproof while also giving the
flexibility of installing and updating containerized applications.

Building the image
------------------

Building the image relies on the [automotive-image-builder|https://gitlab.com/CentOS/automotive/src/automotive-image-builder]
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

[automotive-image-builder|https://gitlab.com/CentOS/automotive/src/automotive-image-builder]
provides a convenient tool to make it easy to run these images.
Assuming you already have a local copy of automotive-image-builder, you
can simply do:

```
cd automotive-image-builder
./automotive-image-runner --nographics image.qcow2
```

