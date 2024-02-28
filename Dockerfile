FROM debian:12.5

RUN useradd -r -m -s /bin/bash gestsup

WORKDIR /home/gestsup
COPY run-gestup-install.sh run-gestup-install.sh

RUN pwd
RUN ls ./

RUN chmod 777 run-gestup-install.sh

EXPOSE 80 443

CMD run-gestup-install.sh
