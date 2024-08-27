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
    --container \
    build \
    --build-dir _build \
    --ostree-repo _ostree \
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

Creating an update image and moving to it
-----------------------------------------

The first image we've built is a simple image that does not contain any
of the tools and files needed to be able to install applications
dynamically.

To have that, we need another image. We could build it stand-alone and
just run it, but we can also "update" from the first image to the second.
The way we will do this is by leveraging "[ostree static delta](https://ostreedev.github.io/ostree/formats/#static-deltas)".
Some information on how this is achieved and works can also be found
in the [CentOS Automotive SIG documentation](https://sigs.centos.org/automotive/building/updating_ostree/#offline-delta-updates).

So assuming we followed the previous step and built the first image with
the exact command give above (especially the `--ostree-repo _ostree`
argument). We will build a second image and update that ostree repo
while doing so:

```
cd automotive-image-builder
./automotive-image-builder \
    --container \
    build \
    --build-dir _build \
    --ostree-repo _ostree \
    --distro autosd9 \
    --target qemu \
    --export qcow2 \
    --mode image \
    ../autosd_container_demo/mycontainer_v2.mpp.yml image_v2.qcow2
```

That `image_v2.qcow2` file can be ran stand alone or discarded as we will
not use it further.

When building that image, we have also update the ostree repo located
in `_ostree`. This means we can now generate a static delta between the
different images stored in that repository.
To do this we will use the script available here that is called
`generate-deltas` (copied from the CentOS Automotive SIG [sample-images](
https://gitlab.com/CentOS/automotive/sample-images/) repository).

Simply run it as:

```
../autosd_container_demo/generate-deltas _ostre _deltas
```

Where `_ostree` is the folder where is stored the ostree repository used
in the two previous image builds and `_deltas` is the folder where we
want the script to store these deltas.

If you only built two images, you will have two `.update` files. They will
look similar to:
```
 du -sh _deltas/*
188K	_deltas/autosd-x86_64-qemu-mycontainer-manifest-5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc-6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354.update
612M	_deltas/autosd-x86_64-qemu-mycontainer-manifest-6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354.update
```

Any one of these updates can be applied, but if you were to install a
wrong one you would get an error like "Commit XYZ, which is the delta
source, is not in repository".
The difference in size is interesting to notice, the second one is basically
a whole new image while the first one contains just the diff between
the commit `5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc`
and the commit `6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354`.

To know which ostree commit you are on, you can run `rpm-ostree status`
in your image. It should be something like:

```
# rpm-ostree status
State: idle
Deployments:
● auto-sig:autosd/x86_64/qemu-mycontainer-manifest
                  Version: 1 (2024-08-27T09:07:23Z)
                   Commit: 5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc
```

So we are on the commit `5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc`.

The next step is to get into the VM the delta you want to install, here
we will take the smaller of the two:
```
autosd-x86_64-qemu-mycontainer-manifest-5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc-6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354.update
```
It can be pulled into the VM via http, ssh... however you want/can.

Once the file is in the VM, you can install the update:
```
# ostree static-delta apply-offline autosd-x86_64-qemu-mycontainer-manifest-5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc-6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354.update
```

Then ask the system to move to the new version:
```
# rpm-ostree rebase 6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354
Staging deployment... done
Added:
  validator-0.2.2-13.el9.x86_64
Changes queued for next boot. Run "systemctl reboot" to start a reboot
```

Check that the new version is installed:
```
# rpm-ostree status
State: idle
Deployments:
  auto-sig:6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354
                  Version: 1 (2024-08-27T10:08:30Z)
                   Commit: 6b1286ba47ed3cc7dc57c1b7919e5a955be30fcf429a931fed5221cd4cdd8354
                     Diff: 1 added

● auto-sig:autosd/x86_64/qemu-mycontainer-manifest
                  Version: 1 (2024-08-27T09:07:23Z)
                   Commit: 5dbb71fd2bd03ccbe609010b77815e7de1472a78a3fc602fb8b1645ae9c3afdc
```

Then `reboot` and running `rpm-ostree status` will show you that you have
changed version and you will be in an image that has all the tools and
files needed to install containerized applications. You can verify this
by checking that `validator` is installed (`rpm -q validator`) or that you
have the public key needed to verify signatures (`ls /usr/lib/validator/keys/`)
for examples.


Installing a demo app
---------------------

We have a tarball with a demo "app" available that can be used.

Here are the commands you can follow to install this app:

```
# Download application and its signature
wget https://pingou.fedorapeople.org/a6.tar.gz
wget https://pingou.fedorapeople.org/a6.tar.gz.sig

# Check its signature
validator -v validate --key /usr/lib/validator/keys/etc.key a6.tar.gz

## Install the application

# Unpack the archive
tar xvfz a6.tar.gz
# Update containers - data - nothing changes
cp -a var/apps /var/
# Update application
cp -a var/quadlets /var/
validator -vvv install --config=/etc/validator/validator.conf

# So we have installed the application. It is all on disk but from the
# system's perspective, nothing has changed. systemd is still not aware
# that this application has been installed (the command below will fail
# to find the application)
systemctl status fedora-minimal

# Reload systemd, so it runs quadlet and becomes aware of the new application
# installed
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
