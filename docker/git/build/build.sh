# This file builds a docker image from sources with bootstrap

set -e

# $1 == path to root of project
# $1/.func has name of functions

ID=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
REPO_DIR=$1
REPO_NAME=$(basename $REPO_DIR)

BUILD_ROOT=/build
WORK_DIR=$BUILD_ROOT/_temp/$ID

mkdir -p $WORK_DIR

echo "Cloning repository"
git clone $REPO_DIR $WORK_DIR

if [ -e "WORK_DIR/.func" ]
then
  echo ".func file missing"
  exit 2
fi

echo Building project
dotnet restore $WORK_DIR
dotnet build $WORK_DIR/src/**/project.json

FUNC=$(cat $WORK_DIR/.func)

echo Building proxy and manifest
dotnet $BUILD_ROOT/utils/bin/CoreFn.Builder.dll $WORK_DIR/src/$FUNC/bin/Debug/netcoreapp1.0/ $WORK_DIR/src/$FUNC

echo Copying bootstrapper
cp $BUILD_ROOT/utils/Bootstrap.Program.cs $WORK_DIR/src/$FUNC/Program.cs

echo Updating project.json to emit entry point
sed -i -e 's/"emitEntryPoint": false/"emitEntryPoint": true/' $WORK_DIR/src/$FUNC/project.json

echo Building bootstrapped program
dotnet build $WORK_DIR/src/$FUNC
dotnet publish -o $WORK_DIR/publish $WORK_DIR/src/$FUNC

echo Building docker image
echo "FROM microsoft/dotnet:latest\n\nCOPY . /app\n\nENTRYPOINT [\"dotnet\", \"/app/$FUNC.dll\"]" > $WORK_DIR/publish/Dockerfile

SAFE_NAME="$(echo $FUNC | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
SAFE_NAME="$(basename $REPO_DIR)$SAFE_NAME"
echo name: corefn/$SAFE_NAME

docker build -t corefn/$SAFE_NAME $WORK_DIR/publish

echo Killing running instances
docker kill $(docker ps -f "ancestor=corefn/$SAFE_NAME" -q)

# TODO: remove redis cache key

echo Updating manifest store
cp $WORK_DIR/src/$FUNC/manifest.json /var/func/manifest/$REPO_NAME/$FUNC.json

rm -rf $WORK_DIR
