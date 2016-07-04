FROM microsoft/dotnet:1.0.0-core-deps

# FROM alpine

# RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories

# RUN apk update && \
#   apk add openssh git@edge && \
#   rm -rf /var/cache/apk/*

# RUN adduser git -h /var/git -D
# RUN passwd -d 'git' git

RUN apt-get update && \
  apt-get install -y openssh-server git && \
  rm -rf /var/lib/apt/lists/*

RUN useradd git -d /var/git -m -p git

ADD hooks /etc/git/hooks

USER git
RUN echo "[core]" > /var/git/.gitconfig
RUN echo "    hooksPath = /etc/git/hooks" >> /var/git/.gitconfig

USER root

EXPOSE 22

COPY docker-entrypoint.sh /

CMD [ "sh", "/docker-entrypoint.sh" ]
