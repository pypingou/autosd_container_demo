#!/usr/bin/bash

ROOT_DIR=/var

set -x

install_tarball() {
    transaction_checksum=$(sha256sum $1 | cut -d " " -f 1)
    d=$(dirname $1)
    tar -zxvf $1 -C $ROOT_DIR/apps/
    transaction_dir=$ROOT_DIR/quadlet_$transaction_checksum
    mkdir -p $transaction_dir

    # link old configs
    link=$(readlink -f $ROOT_DIR/quadlets)
    if [[ ! "$link" == "$ROOT_DIR/quadlets" && ! -z "$link" ]] ; then
        cp -R $link/. $transaction_dir
    fi

    # copy new configs and replace overwritten old ones
    config_dirs=$(tar -ztf $1 | tree --fromfile . -L 2 -d -if | grep "_" | sed "s#./##g")
    for dd in $config_dirs ; do
        for f in $ROOT_DIR/apps/$dd/* ; do
            [ -e "$f" ] || continue
            src=$(find -L "$f" | tail -n1)
            name=$(basename "$src")
            ln -sf "$src" $transaction_dir/$name
        done
    done

    image_dirs=$(tar -ztf $1 | tree --fromfile . -L 2 -d -if | grep -v "_" | sed "s#\/##g" | sed "s#\.##g" | grep -v "directories")

    for dir in $image_dirs ; do
        mkdir -p $ROOT_DIR/apps/$dir/imagestore
        # it is not possible to use the same directories for --root and -i
        podman --root=$ROOT_DIR/apps/$dir/imagestore load -i $ROOT_DIR/apps/$dir
        # fix selinux
        semanage fcontext -a -e /var/lib/containers $ROOT_DIR/apps/$dir/imagestore
        restorecon -R -v $ROOT_DIR/apps/$dir/imagestore
    done

    ln -snf $transaction_dir $ROOT_DIR/quadlets
}

mkdir -p $ROOT_DIR/apps/
install_tarball "$@"
