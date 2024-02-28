FROM debian:12.5

RUN useradd -r -m -s /bin/bash gestsup

WORKDIR /home/gestsup
COPY --chown=gestsup:gestsup run-gestup-install.sh run-gestup-install.sh

RUN pwd
RUN ls -lah ./

RUN chmod 777 run-gestup-install.sh
#RUN chown gestsup:gestsup run-gestup-install.sh

RUN ls -lah ./

EXPOSE 80 443

USER gestsup

CMD run-gestup-install.sh
