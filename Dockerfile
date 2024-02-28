FROM debian:12.5

RUN useradd -r -m -s /bin/bash gestsup

RUN apt update
RUN apt upgrade
RUN apt install curl -y
RUN apt install wget -y
RUN apt install systemctl -y
RUN apt install apache2 -y
RUN apt install mariadb -y

WORKDIR /home/gestsup
COPY --chown=gestsup:gestsup run-gestup-install.sh run-gestup-install.sh

RUN chmod 777 run-gestup-install.sh

EXPOSE 80 443

USER gestsup

CMD ["./run-gestup-install.sh"]
