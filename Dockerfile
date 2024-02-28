FROM debian:12.5

RUN sudo useradd gestsup
RUN sudo usermod -aG sudo gestsup

RUN apt update
RUN apt install curl -y && curl -s https://gestsup.fr/install.deb12.sh | bash

EXPOSE 80 443
