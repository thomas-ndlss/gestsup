//Debian
FROM debian:12.5

RUN mkdir -p /home/gestsup && chown -R gestsup:gestsup /home/gestsup

//Install
RUN apt update
RUN apt install curl -y && curl -s https://gestsup.fr/install.deb12.sh | bash

EXPOSE 80 443
