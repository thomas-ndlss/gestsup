FROM debian:12.5

RUN apt update
RUN apt install curl -y && curl -s https://gestsup.fr/install.deb12.sh | bash

EXPOSE 80 443
