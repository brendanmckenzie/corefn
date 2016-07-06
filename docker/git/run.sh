docker run \
  -ti \
  --rm \
  -v "$(pwd)/var/git/.ssh":/var/git/.ssh \
  -v "$(pwd)/var/git/projects":/var/git/projects \
  -v "$(pwd)/var/func":/var/func \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -p 7022:22 corefn/git "$@"
