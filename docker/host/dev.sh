#!/usr/bin/env bash

exec docker run --rm -it \
  -v "$(pwd)/nginx/conf":/opt/openresty/nginx/conf \
  -v "$(pwd)/nginx/lualib":/opt/openresty/nginx/lualib \
  -v "$(pwd)/corefn/manifest":/var/func/manifest \
  -v "/var/run/docker.sock":/var/run/docker.sock \
  -p 8080:8080 \
  --link=redis \
  corefn/host "$@"

# you may add more -v options to mount another directories, e.g. nginx/html/

# do not do -v "$(pwd)/nginx":/opt/openresty/nginx because it will hide
# the NginX binary located at /opt/openresty/nginx/sbin/nginx
