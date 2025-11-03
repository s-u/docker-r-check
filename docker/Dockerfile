## specify the favor of Debian to create the image from. Can be set on CLI, example:
##
##   docker build --build-arg DEBIAN_TAG=testing --target base -t rchk-base:testing .

ARG DEBIAN_TAG=unstable

## Target: base - base image with rcheckserver
FROM docker.io/debian:${DEBIAN_TAG} AS base

ARG DEBIAN_MIRROR=http://deb.debian.org
ENV DEBIAN_MIRROR=${DEBIAN_MIRROR}

## main setup; apt cannot pull from other repos without ca-certificates so have to install that one first
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked   \
    sed -i "s,http://deb[.]debian[.]org,${DEBIAN_MIRROR},g" /etc/apt/sources.list.d/debian.sources && \
    cat /etc/apt/sources.list.d/debian.sources && \
    apt-get update -qq && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y upgrade && \
    DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install ca-certificates

## install key and WU sources
COPY aasc.sources /etc/apt/sources.list.d/aasc.sources
COPY aasc-archive.pgp /etc/apt/keyrings/aasc-archive.pgp

## install rcheckserver
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install rcheckserver
## add source repos
RUN sed -i 's/^Types: deb/\0 deb-src/g' /etc/apt/sources.list.d/debian.sources && apt-get update -qq && DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y build-dep r-base


## Target: build-r - image for building R, caches R sources and QA/Kurt
FROM base AS build-r

## list of additional system depenencies for the R build image (e.g. specific BLAS libraries)
## can be empty if default setup is sufficient
ARG R_BUILD_SYSDEPS
ENV R_BUILD_SYSDEPS="${R_BUILD_SYSDEPS}"

## those can be set during build-time, but we can also re-set those to match the mounts so not very important
ARG UID=1000
ARG GID=1000

## setup a build user + sudo
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install sudo && /sbin/groupadd -g ${GID} rbuild && /sbin/useradd -m -u ${UID} -g ${GID} rbuild && echo 'rbuild ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/10rbuild

## prepare sources if not mounted so we can cache long pulls (mostly relevant to remote places like NZ ;))
RUN mkdir -p /src && \
    svn co https://svn.r-project.org/R-dev-web/trunk/CRAN/QA/Kurt /src/QA && \
    svn co https://svn.r-project.org/R/trunk /src/R && ( cd /src/R && tools/rsync-recommended ) && \
    chown -R rbuild:rbuild /src

## install additional sysdeps
RUN if [ -n "${R_BUILD_SYSDEPS}" ]; then apt-get update -qq && DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true apt-get -y install ${R_BUILD_SYSDEPS}; fi

## copy the entrypoint which will update SVN (unless NO_UPDATE is set) and run the build
COPY entry-build-r.sh /entry-build-r.sh

USER rbuild

ENTRYPOINT [ "/bin/bash", "/entry-build-r.sh" ]


FROM build-r AS pkgcheck

COPY entry-pkgcheck.sh /entry-pkgcheck.sh
ENTRYPOINT [ "/bin/bash", "/entry-pkgcheck.sh" ]

