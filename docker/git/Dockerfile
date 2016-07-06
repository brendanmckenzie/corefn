FROM microsoft/dotnet:1.0.0-core-deps

# FROM alpine

# RUN echo "@edge http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories

# RUN apk update && \
#   apk add openssh git@edge && \
#   rm -rf /var/cache/apk/*

# RUN adduser git -h /var/git -D
# RUN passwd -d 'git' git


RUN apt-get update && \
  apt-get install -y apt-transport-https ca-certificates && \
  apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D && \
  echo "deb https://apt.dockerproject.org/repo debian-jessie main" > /etc/apt/sources.list.d/docker.list

RUN apt-get update && \
  apt-get install -y \
    openssh-server curl build-essential libcurl4-gnutls-dev \
    libexpat1-dev gettext libz-dev libssl-dev xz-utils libunwind8 \
    docker-engine && \
  rm -rf /var/lib/apt/lists/*

  # TODO: tidy this up

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
RUN rm -rf /tmp/dotnet.tar.gz

WORKDIR /

RUN apt-get remove -y build-essential xz-utils libcurl4-gnutls-dev libexpat1-dev apt-transport-https
RUN apt-get autoremove -y

RUN mkdir /var/run/sshd

# Configure git user
RUN useradd git -d /var/git -m -p git

ADD hooks /etc/git/hooks

USER git
RUN echo "[core]" > /var/git/.gitconfig
RUN echo "    hooksPath = /etc/git/hooks" >> /var/git/.gitconfig

USER root

ADD build /build
RUN chmod 666 /build/utils/bin/*.dll
RUN mkdir -m 777 -p /build/_temp

EXPOSE 22

COPY docker-entrypoint.sh /

CMD [ "sh", "/docker-entrypoint.sh" ]
