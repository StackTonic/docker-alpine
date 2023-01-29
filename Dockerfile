FROM alpine:3.16 as rootfs-stage
# environment
ENV REL=v3.17
ENV ARCH=x86_64
ENV MIRROR=http://mirror.aarnet.edu.au/pub/alpine
ENV PACKAGES=alpine-baselayout,\
alpine-keys,\
apk-tools,\
busybox,\
libc-utils,\
xz
# install packages
RUN \
 apk add --no-cache \
	bash \
	curl \
	tzdata \
	xz
# fetch builder script from gliderlabs
RUN \
 curl -o \
 /mkimage-alpine.bash -L \
	https://raw.githubusercontent.com/gliderlabs/docker-alpine/master/builder/scripts/mkimage-alpine.bash && \
 chmod +x \
	/mkimage-alpine.bash && \
 ./mkimage-alpine.bash  && \
 mkdir /root-out && \
 tar xf \
	/rootfs.tar.xz -C \
	/root-out && \
 sed -i -e 's/^root::/root:!:/' /root-out/etc/shadow

# Runtime stage
FROM scratch
COPY --from=rootfs-stage /root-out/ /

ARG BUILD_DATE
ARG VERSION=dev
ARG S6_OVERLAY_VERSION=3.1.0.1

LABEL build_version="StackTonic.au version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="HunterNyan"

# Disable frontend dialogs
ENV DEBIAN_FRONTEND=noninteractive
ENV LC_ALL=C.UTF-8

# environment variables
ENV PS1="$(whoami)@$(hostname):$(pwd)\\$ " \
HOME="/root" \
TERM="xterm"

#Update Container
RUN  echo "**** Update Container ****" && \
    apk update --no-cache  && \
    apk upgrade --no-cache  && \
  echo "**** install build packages ****" && \
  apk add --no-cache --virtual=build-dependencies \
	  curl \
	  patch \
	  tar && \
  echo "**** install runtime packages ****" && \
  apk add --no-cache \
  	bash \
  	ca-certificates \
  	coreutils \
  	procps \
  	shadow \
  	tzdata \
	sudo

# Install s6 overlay
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/syslogd-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/syslogd-overlay-noarch.tar.xz

RUN \
  echo "**** create app user and make our folders ****" && \
  groupmod -g 1000 users && \
  useradd -u 911 -U -d /config -s /bin/false app && \
  usermod -G users app && \
  mkdir -p \
	  /app \
	  /config && \
  rm -rf \
	  /tmp/*

COPY root/ /

ENTRYPOINT ["/init"]