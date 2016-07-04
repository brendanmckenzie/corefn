docker run \
  -ti \
  --rm \
  -v "$(pwd)/var/git/.ssh":/var/git/.ssh \
  -v "$(pwd)/var/git/projects":/var/git/projects \
  -p 7022:22 corefn/git "$@"
