#!/bin/bash

if [ ! -e /build/bin/R ] || ! /build/bin/R --version | head -n1; then
    echo "** ERROR: /build not mounted with working R build!"
    echo ''
    echo 'Please make sure you start the container with -v $(pwd)/build:/build or similar.'
    echo ''
    exit 1
fi

set -e
if [ ! -e /pkg ]; then
    if [ -e /build/pkg ]; then
	echo " == found /build/pkg - using it for checks"
	sudo ln -sfn /build/pkg /pkg
    else
	echo "** ERROR: /pkg not mounted!"
	echo ''
	echo 'Please make sure you start the container with -v $(pwd)/pkg:/pkg or similar.'
	echo 'Alternatively, you can put the packages in /build/pkg, i.e., in the pkg'
	echo 'subdirectory of your R build'
	echo ''
	exit 1
    fi
fi

cd /pkg
exec /build/bin/Rscript -e 'chooseCRANmirror(graphics=FALSE, ind=1, local.only=TRUE); tools::check_packages_in_dir("/pkg")'
