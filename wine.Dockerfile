FROM scottyhardy/docker-wine:latest

# The my-dockers scripts will provide user information allowing
# # to user your user name from host.
# ARG UN
# ARG UI
# ARG GN
# ARG GI

# # Setup user account
# RUN groupadd -g $GI $GN && \
# 	useradd -s `which bash` -m -g $GI -G adm,dialout,cdrom,sudo,dip,plugdev -u $UI $UN && \
# 	echo "$UN ALL=(ALL:ALL) NOPASSWD: ALL" > /etc/sudoers.d/$UN
# USER $UN:$GN
# WORKDIR /home/$UN
# ENV PATH=$PATH:/home/$UN/.local/bin
# RUN mkdir -p /home/$UN/.local/bin && \
# 	mkdir -p /home/$UN/.cache

ENTRYPOINT ["/usr/bin/entrypoint"]
