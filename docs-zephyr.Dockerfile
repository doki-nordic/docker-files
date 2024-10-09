FROM ubuntu:22.04
LABEL Description="Zephyr documentation build environment"

# Packages to install
ARG ARG_LINUX_PACKAGES=" \
    wget curl mc tzdata sudo doxygen mscgen plantuml graphviz \
    git cmake ninja-build gperf \
    device-tree-compiler \
    python3 python3-dev python3-pip python3-setuptools python3-tk python3-wheel python-is-python3 \
    xz-utils file make libmagic1 \
    librsvg2-bin texlive-latex-base texlive-latex-extra latexmk texlive-fonts-recommended imagemagick \
"

ENV TZ=Etc/UTC

# Install linux packages (with cache)
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
	--mount=type=cache,target=/var/lib/apt,sharing=locked \
	apt update && \
	DEBIAN_FRONTEND=noninteractive apt install -y -qq $ARG_LINUX_PACKAGES

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

RUN pip3 install west
