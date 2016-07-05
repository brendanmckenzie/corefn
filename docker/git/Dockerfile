FROM microsoft/dotnet:1.0.0-core-deps

# FROM alpine

# RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories

# RUN apk update && \
#   apk add openssh git@edge && \
#   rm -rf /var/cache/apk/*

# RUN adduser git -h /var/git -D
# RUN passwd -d 'git' git

RUN apt-get update && \
  apt-get install -y openssh-server curl build-essential libcurl4-gnutls-dev libexpat1-dev gettext libz-dev libssl-dev xz-utils libunwind8 && \
  rm -rf /var/lib/apt/lists/*

# Install git 2.9
RUN curl -o /tmp/git-2.9.0.tar.xz https://www.kernel.org/pub/software/scm/git/git-2.9.0.tar.xz
WORKDIR /tmp
RUN tar xJf git-2.9.0.tar.xz
WORKDIR /tmp/git-2.9.0
RUN ./configure --prefix=/usr --with-gitconfig=/etc/gitconfig
RUN make
RUN make install
WORKDIR /
RUN rm -rf /tmp/git-2.9.0 /tmp/git-2.9.0.tar.xz

# Install dotnet
RUN curl -sSL -o /tmp/dotnet.tar.gz https://go.microsoft.com/fwlink/?LinkID=809130
WORKDIR /tmp
RUN mkdir -p /opt/dotnet && tar zxf dotnet.tar.gz -C /opt/dotnet
RUN ln -s /opt/dotnet/dotnet /usr/local/bin

RUN mkdir /var/run/sshd

# Configure git user
RUN useradd git -d /var/git -m -p git

ADD hooks /etc/git/hooks

USER git
RUN echo "[core]" > /var/git/.gitconfig
RUN echo "    hooksPath = /etc/git/hooks" >> /var/git/.gitconfig

USER root

EXPOSE 22

COPY docker-entrypoint.sh /

CMD [ "sh", "/docker-entrypoint.sh" ]
