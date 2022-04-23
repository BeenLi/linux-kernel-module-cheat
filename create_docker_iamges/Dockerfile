# https://cirosantilli.com/linux-kernel-module-cheat#docker
FROM ubuntu:20.04
RUN apt-get update \
  && apt-get install -y \
        sudo \
        gosu 



COPY setup /
COPY requirements.txt /
RUN /setup -y

# RUN chmod 660 /var/log/tallylog 
RUN groupadd dev \
    && useradd --create-home -g dev dev \
    && usermod -p '*' dev \
    && passwd -u dev

USER dev:dev
# using dev to install 
RUN python3 -m pip install --user -r requirements.txt

# All subsequent steps are performed as user.
USER root:root
# Scripting for use within this container.
COPY start.sh /start.sh
COPY sudoconf /etc/sudoers.d/dev



ENTRYPOINT [ "/start.sh" ]

