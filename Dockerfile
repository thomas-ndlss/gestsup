FROM debian:12.5

RUN useradd -r -m -s /bin/bash gestsup

RUN apt update
RUN apt upgrade
RUN apt install curl -y
RUN apt install wget -y
RUN apt install systemctl -y
RUN apt install apache2 -y
RUN apt install mariadb-server -y
RUN apt install unzip -y
RUN apt install ntp -y
RUN apt install cron -y
RUN apt install php libapache2-mod-php -y
RUN apt install php-common php-curl php-gd php-imap php-intl php-ldap php-mbstring php-mysql php-xml php-zip -y
RUN apt install sudo -y

WORKDIR /home/gestsup
COPY --chown=gestsup:gestsup run-gestup-install.sh run-gestup-install.sh

RUN chmod 777 run-gestup-install.sh

RUN usermod -aG sudo gestsup

RUN id gestsup

EXPOSE 80 443

USER gestsup

CMD ["su gestsup", "./run-gestup-install.sh"]
