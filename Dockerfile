# https://cirosantilli.com/linux-kernel-module-cheat#docker
FROM ubuntu:20.04
ADD sources.list /etc/apt/
RUN apt-get update && apt-get install -y vim \
    software-properties-common \
    wget
RUN  add-apt-repository ppa:git-core/ppa
COPY setup /
COPY requirements.txt /
RUN /setup -y
CMD bash
