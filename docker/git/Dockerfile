FROM alpine

RUN apk update && \
  apk add openssh git && \
  rm -rf /var/cache/apk/*

RUN adduser git -h /var/git -D
RUN mkdir -p /var/git/.ssh
RUN touch /var/git/.authorized_keys
RUN chown -R git:git /var/git
RUN chmod 644 /var/git/.ssh/authorized_keys

RUN sed -i -e 's/.*LogLevel.*/LogLevel VERBOSE/' -e 's/#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i -e 's/#UsePAM.*/UsePAM no/' /etc/ssh/sshd_config

EXPOSE 22

COPY docker-entrypoint.sh /

CMD [ "sh", "/docker-entrypoint.sh" ]
