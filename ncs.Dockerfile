FROM ubuntu:22.04

# Packages to install
ARG ARG_LINUX_PACKAGES=" \
    usbutils libusb-1.0-0-dev udev \
    wget curl mc tzdata sudo doxygen mscgen plantuml graphviz iputils-ping \
    git cmake ninja-build gperf \
    device-tree-compiler ccache dfu-util \
    python3 python3-dev python3-pip python3-setuptools python3-tk python3-wheel \
    python-is-python3 python3-venv \
    xz-utils file make libmagic1 gcc gcc-multilib g++-multilib libsdl2-dev \
    librsvg2-bin texlive-latex-base texlive-latex-extra latexmk texlive-fonts-recommended imagemagick \
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

ARG ARG_NRFUTIL_URL=https://files.nordicsemi.com/ui/api/v1/download?repoKey=swtools&path=external/nrfutil/executables/x86_64-unknown-linux-gnu/nrfutil&isNativeBrowsing=false
ARG ARG_NRF_COMMAND_LINE_TOOLS_URL=https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/desktop-software/nrf-command-line-tools/sw/versions-10-x-x/10-24-2/nrf-command-line-tools_10.24.2_amd64.deb
ARG ARG_NRF_UDEV_URL=https://github.com/NordicSemiconductor/nrf-udev/releases/download/v1.0.1/nrf-udev_1.0.1-all.deb

# Download and install nrfutil, nrf-udev, nrf-command-line-tools
RUN --mount=type=cache,target=/var/cache/cwget,sharing=locked \
	chmod +x /usr/bin/*.sh && \
	mkdir -p tmp && \
	cd tmp && \
	cwget.sh "$ARG_NRFUTIL_URL" nrfutil && \
	chmod 755 nrfutil && \
	mv nrfutil /usr/bin && \
	cwget.sh "$ARG_NRF_UDEV_URL" nrf-udev.deb && \
	dpkg -i nrf-udev.deb && \
	cwget.sh "$ARG_NRF_COMMAND_LINE_TOOLS_URL" nrf-command-line-tools.deb && \
	dpkg -i nrf-command-line-tools.deb && \
	cd .. && \
	rm -Rf tmp

# The my-dockers scripts will provide user information allowing
# to user your user name from host.
ARG UN
ARG UI
ARG GN
ARG GI

# Setup user account
RUN groupadd -g $GI $GN && \
	useradd -s `which bash` -m -g $GI -G adm,dialout,cdrom,sudo,dip,plugdev -u $UI $UN && \
	echo "$UN ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$UN
USER $UN:$GN
WORKDIR /home/$UN
ENV PATH=$PATH:/home/$UN/.local/bin
RUN mkdir -p /home/$UN/.local/bin && \
	mkdir -p /home/$UN/.cache

# Install west
RUN pip install west

ARG ARG_ZEPHYR_SDK=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/zephyr-sdk-0.16.8_linux-x86_64_minimal.tar.xz
ARG ARG_ZEPHYR_SDK_HOST=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/hosttools_linux-x86_64.tar.xz
ARG ARG_ZEPHYR_SDK_ARM=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_linux-x86_64_arm-zephyr-eabi.tar.xz
ARG ARG_ZEPHYR_SDK_RISCV=https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.16.8/toolchain_linux-x86_64_riscv64-zephyr-elf.tar.xz

# Install zephyr SDK
RUN --mount=type=cache,target=/home/$UN/.cache/cwget,sharing=locked \
	sudo chmod 777 /home/$UN/.cache/cwget && \
	cwget.sh "$ARG_ZEPHYR_SDK"       arch.tar.xz && tar xf arch.tar.xz && rm arch.tar.xz && \
	cd zephyr-sdk-* && \
	cwget.sh "$ARG_ZEPHYR_SDK_HOST"  arch.tar.xz && tar xf arch.tar.xz && rm arch.tar.xz && \
	cwget.sh "$ARG_ZEPHYR_SDK_ARM"   arch.tar.xz && tar xf arch.tar.xz && rm arch.tar.xz && \
	cwget.sh "$ARG_ZEPHYR_SDK_RISCV" arch.tar.xz && tar xf arch.tar.xz && rm arch.tar.xz && \
	./setup.sh -t riscv64-zephyr-elf -t arm-zephyr-eabi -h -c && \
	sudo cp sysroots/x86_64-pokysdk-linux/usr/share/openocd/contrib/60-openocd.rules /etc/udev/rules.d

# Copy startup script
RUN mkdir -p /home/$UN/.my-dockers-startup
COPY utils/ncs-startup.sh /home/$UN/.my-dockers-startup/
RUN sudo chmod +x /home/$UN/.my-dockers-startup/ncs-startup.sh

# Install nrfutil device and kms
RUN --mount=type=secret,id=FILES_NORDICSEMI_COM_TOKEN,env=FILES_NORDICSEMI_COM_TOKEN \
	nrfutil config package-index add internal-production \
	https://files.nordicsemi.com/artifactory/swtools/internal/nrfutil/index/init.json \
	--environment-variable-name FILES_NORDICSEMI_COM_TOKEN
RUN --mount=type=secret,id=FILES_NORDICSEMI_COM_TOKEN,env=FILES_NORDICSEMI_COM_TOKEN \
	nrfutil install --package-index-name internal-production device
RUN --mount=type=secret,id=FILES_NORDICSEMI_COM_TOKEN,env=FILES_NORDICSEMI_COM_TOKEN \
	nrfutil install --package-index-name internal-production kms
