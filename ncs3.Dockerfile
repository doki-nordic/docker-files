FROM ubuntu:24.04

# Packages to install
ARG ARG_LINUX_PACKAGES=" \
    usbutils libusb-1.0-0-dev udev \
    wget curl mc tzdata sudo doxygen mscgen plantuml graphviz iputils-ping \
    git cmake ninja-build gperf fuse libfuse2 \
    device-tree-compiler ccache dfu-util \
    python3 python3-dev python3-pip python3-setuptools python3-tk python3-wheel \
    python-is-python3 python3-venv \
    xz-utils file make libmagic1 gcc gcc-multilib g++-multilib libsdl2-dev \
    librsvg2-bin texlive-latex-base texlive-latex-extra latexmk texlive-fonts-recommended imagemagick \
	libcanberra-gtk-module libcanberra-gtk3-module \
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

ARG ARG_NRFUTIL_VER=0
ARG ARG_NRFUTIL_URL=https://files.nordicsemi.com/ui/api/v1/download?repoKey=swtools&path=external/nrfutil/executables/x86_64-unknown-linux-gnu/nrfutil&isNativeBrowsing=false&_uuid_my_docker=1
ARG ARG_NRF_UDEV_URL=https://github.com/NordicSemiconductor/nrf-udev/releases/download/v1.0.1/nrf-udev_1.0.1-all.deb

# Download and install nrfutil, nrf-udev, nrf-command-line-tools
RUN --mount=type=cache,target=/var/cache/cwget,sharing=locked \
	chmod +x /usr/bin/*.sh && \
	mkdir -p tmp && \
	cd tmp && \
	cwget.sh "$ARG_NRFUTIL_URL$ARG_NRFUTIL_VER" nrfutil && \
	chmod 755 nrfutil && \
	mv nrfutil /usr/bin && \
	cwget.sh "$ARG_NRF_UDEV_URL" nrf-udev.deb && \
	dpkg -i nrf-udev.deb && \
	cd .. && \
	rm -Rf tmp

ARG ARG_OZONE_VER=0
ARG ARG_OZONE_URL=https://www.segger.com/downloads/jlink/Ozone_Linux_x86_64.deb?_uuid_my_docker=1

# Install Segger Ozone
RUN --mount=type=cache,target=/var/cache/cwget,sharing=locked \
	mkdir -p tmp && \
	cd tmp && \
	cwget.sh "$ARG_OZONE_URL$ARG_OZONE_VER" Ozone_Linux_x86_64.deb && \
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

# Install sdk-manager
RUN nrfutil install sdk-manager && \
	mkdir -p /home/$UN/ncs

ARG SDK_VERSION

# Install SDK manager
ARG MY_DOCKERS_COMMAND
RUN --mount=type=bind,target=/home/$UN/_tmp_sdkman,source=./_tmp/cache/ncs \
	mkdir -p /home/$UN/ncs/downloads && \
	cp /home/$UN/_tmp_sdkman/* /home/$UN/ncs/downloads/ && \
	sudo chown $UN:$GN /home/$UN/ncs/downloads/* && \
	ls -la /home/$UN/ncs/downloads && \
	nrfutil sdk-manager install $SDK_VERSION && \
	rm -Rf /home/$UN/ncs/downloads/*

ARG ARG_NRF_CONNECT_DESKTOP=https://eu.files.nordicsemi.com/ui/api/v1/download?repoKey=web-assets-com_nordicsemi&path=external%2fswtools%2fncd%2flauncher%2fv5.2.1%2fnrfconnect-5.2.1-x86_64.AppImage

# Install nRF Connect for Desktop
RUN wget -O /home/$UN/.local/bin/nrfconnect "$ARG_NRF_CONNECT_DESKTOP"
RUN chmod +x /home/$UN/.local/bin/nrfconnect
ENV ELECTRON_DISABLE_SANDBOX=1

# # Copy startup script
# RUN mkdir -p /home/$UN/.my-dockers-startup
# COPY utils/ncs-startup.sh /home/$UN/.my-dockers-startup/
# RUN sudo chmod +x /home/$UN/.my-dockers-startup/ncs-startup.sh

# # Install nrfutil device and kms
# # RUN --mount=type=secret,id=FILES_NORDICSEMI_COM_TOKEN,env=FILES_NORDICSEMI_COM_TOKEN \
# # 	nrfutil config package-index add internal-production \
# # 	https://files.nordicsemi.com/artifactory/swtools/internal/nrfutil/index/init.json \
# # 	--environment-variable-name FILES_NORDICSEMI_COM_TOKEN
# # RUN --mount=type=secret,id=FILES_NORDICSEMI_COM_TOKEN,env=FILES_NORDICSEMI_COM_TOKEN \
# # 	nrfutil install --package-index-name internal-production device
# # RUN --mount=type=secret,id=FILES_NORDICSEMI_COM_TOKEN,env=FILES_NORDICSEMI_COM_TOKEN \
# # 	nrfutil install --package-index-name internal-production kms
# RUN nrfutil install device

# RUN --mount=type=bind,target=/home/dok/bashrc-cat.sh,source=./utils/bashrc-cat.sh \
# 	cat /home/dok/bashrc-cat.sh >> ~/.bashrc

COPY utils/ncs-startup2.sh /home/$UN/.my-dockers-startup/
RUN sudo chmod +x /home/$UN/.my-dockers-startup/ncs-startup2.sh

RUN --mount=type=bind,target=/home/dok/bashrc-cat.sh,source=./utils/bashrc-cat.sh \
	cat /home/dok/bashrc-cat.sh >> ~/.nrfutil/share/toolchain-manager-core/*/shell/bashrc

