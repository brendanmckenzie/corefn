FROM mhart/alpine-node

RUN apk update
RUN apk add docker

ADD . /app

CMD [ "node", "/app/index.js" ]
