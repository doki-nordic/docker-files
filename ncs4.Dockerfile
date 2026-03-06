FROM ubuntu:24.04

# Packages to install
ARG ARG_LINUX_PACKAGES=" \
    usbutils libusb-1.0-0-dev udev \
    wget curl mc tzdata sudo iputils-ping \
    fuse libfuse2 \
    xz-utils file gcc gcc-multilib g++-multilib libsdl2-dev \
	tk doublecmd-gtk libcanberra-gtk-module libcanberra-gtk3-module \
	quickjs libnss3 blt \
"

ENV TZ=Etc/UTC

# Install linux packages (with cache)
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	apt update && \
	DEBIAN_FRONTEND=noninteractive apt install -y -qq $ARG_LINUX_PACKAGES

# Copy utils
COPY utils/cwget.sh /usr/bin/

# Prepare install directory
RUN mkdir -p /_install
WORKDIR /_install

# Download and install nrfutil, nrf-udev
ARG ARG_NRFUTIL_URL
ARG ARG_NRF_UDEV_URL
RUN --mount=type=cache,target=/var/cache/cwget,sharing=locked \
	chmod +x /usr/bin/*.sh && \
	mkdir -p tmp && \
	cd tmp && \
	cwget.sh "$ARG_NRFUTIL_URL" nrfutil && \
	chmod 755 nrfutil && \
	mv nrfutil /usr/bin && \
	cwget.sh "$ARG_NRF_UDEV_URL" nrf-udev.deb && \
	dpkg -i nrf-udev.deb && \
	cd .. && \
	rm -Rf tmp

# Install Segger Ozone
ARG ARG_OZONE_URL
RUN --mount=type=cache,target=/var/cache/cwget,sharing=locked \
	mkdir -p tmp && \
	cd tmp && \
	cwget.sh "$ARG_OZONE_URL" Ozone_Linux_x86_64.deb && \
	DEBIAN_FRONTEND=noninteractive apt install -y -qq `realpath Ozone_Linux_x86_64.deb` --fix-broken && \
	cd .. && \
	rm -Rf tmp

# The my-dockers scripts will provide user information allowing
# to user your user name from host.
ARG UN
ARG UI
ARG GN
ARG GI

# Setup user account
RUN sudo userdel -rf ubuntu && \
	groupadd -g $GI $GN && \
	useradd -s `which bash` -m -g $GI -G adm,dialout,cdrom,sudo,dip,plugdev -u $UI $UN && \
	echo "$UN ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$UN
USER $UN:$GN
WORKDIR /home/$UN
ENV PATH=$PATH:/home/$UN/.local/bin
RUN mkdir -p /home/$UN/.local/bin && \
	mkdir -p /home/$UN/.cache

# Install nRF Connect for Desktop
ARG ARG_NRF_CONNECT_DESKTOP
RUN --mount=type=cache,target=/home/$UN/.cache/cwget,sharing=locked \
	cwget.sh "$ARG_NRF_CONNECT_DESKTOP" /home/$UN/.local/bin/nrfconnect && \
	chmod +x /home/$UN/.local/bin/nrfconnect
ENV ELECTRON_DISABLE_SANDBOX=1

# Copy startup script
COPY utils/ncs-startup2.sh /home/$UN/.my-dockers-startup/
RUN sudo chmod +x /home/$UN/.my-dockers-startup/ncs-startup2.sh

# Install nrfutil and SDK manager
ARG SDK_VERSION
RUN --mount=type=bind,target=/home/$UN/_tmp_sdkman,source=./_tmp/cache/ncs \
	nrfutil install sdk-manager && \
	mkdir -p /home/$UN/ncs/downloads && \
	cp /home/$UN/_tmp_sdkman/* /home/$UN/ncs/downloads/ && \
	sudo chown $UN:$GN /home/$UN/ncs/downloads/* && \
	ls -la /home/$UN/ncs/downloads && \
	nrfutil sdk-manager install $SDK_VERSION && \
	rm -Rf /home/$UN/ncs/downloads/*

# Install SDK manager in toolchain
RUN rm /home/$UN/ncs/toolchains/*/nrfutil/home/locked && \
	nrfutil sdk-manager toolchain launch --ncs-version $SDK_VERSION nrfutil install sdk-manager

# Install Segger JLink
ARG ARG_JLINK_URL
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	--mount=type=cache,target=/home/$UN/.cache/cwget,sharing=locked \
	cwget.sh --post-data accept_license_agreement=accepted "$ARG_JLINK_URL" JLink_Linux_x86_64.deb && \
	sudo DEBIAN_FRONTEND=noninteractive apt install -y -qq $PWD/JLink_Linux_x86_64.deb --fix-broken || true && \
	rm JLink_Linux_x86_64.deb

# Add bashrc modifications
RUN echo exit | nrfutil sdk-manager toolchain launch --ncs-version $SDK_VERSION --shell
RUN --mount=type=bind,target=/home/$UN/bashrc-cat2.sh,source=./utils/bashrc-cat2.sh \
	cat /home/$UN/bashrc-cat2.sh >> `realpath ~/.nrfutil/share/toolchain-manager-core/*`/shell/bashrc

# Add environment workarounds
RUN --mount=type=bind,target=/home/$UN/sdk-env.js,source=./utils/sdk-env.js \
	qjs sdk-env.js $(find ~/ncs/toolchains -name environment.json -mindepth 1 -maxdepth 2)

# Apply tk workaround
RUN --mount=type=bind,target=/home/$UN/_tkinter.cpython-312-x86_64-linux-gnu.so,source=./utils/_tkinter.cpython-312-x86_64-linux-gnu.so \
	env_json="$(find /home/$UN/ncs/toolchains -mindepth 2 -maxdepth 2 -type f -name environment.json -print -quit)" && \
	[ -n "$env_json" ] && \
	toolchain_dir="$(dirname "$env_json")" && \
	mkdir -p "$toolchain_dir/usr/local/lib/python3.12/lib-dynload" && \
	cp /home/$UN/_tkinter.cpython-312-x86_64-linux-gnu.so "$toolchain_dir/usr/local/lib/python3.12/lib-dynload/"
