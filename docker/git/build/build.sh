# This file builds a docker image from sources with bootstrap

set -e

# $1 == path to root of project
# $1/.func has name of functions

BUILD_ROOT=/build

echo Building project
dotnet restore $1
dotnet build $1/src/**/project.json

FUNC=$(cat $1/.func)

echo Building proxy and manifest
dotnet $BUILD_ROOT/utils/bin/CoreFn.Builder.dll $1/src/$FUNC/bin/Debug/netcoreapp1.0/ $1/src/$FUNC

echo Copying bootstrapper
cp $BUILD_ROOT/utils/Bootstrap.Program.cs $1/src/$FUNC/Program.cs

echo Updating project.json to emit entry point
sed -i -e 's/"emitEntryPoint": false/"emitEntryPoint": true/' $1/src/$FUNC/project.json

echo Building bootstrapped program
dotnet build $1/src/$FUNC
dotnet publish -o $1/publish $1/src/$FUNC

echo Building docker image
echo "FROM microsoft/dotnet:latest\n\nCOPY . /app\n\nENTRYPOINT [\"dotnet\", \"/app/$FUNC.dll\"]" > $1/publish/Dockerfile

SAFE_NAME="$(echo $FUNC | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
SAFE_NAME="$(basename $2)$SAFE_NAME"
echo name: corefn/$SAFE_NAME

docker build -t corefn/$SAFE_NAME $1/publish

# TODO: kill any running instances of this image

echo Updating manifest store
mkdir -p /home/corefn/manifest/`basename $2`
cp $1/src/$FUNC/manifest.json /home/corefn/manifest/`basename $2`/$FUNC.json
