# This file builds a docker image from sources with bootstrap

set -e

# $1 == path to root of project
# $1/.func has name of functions

rm -rf _build
mkdir -p _build/bin
mkdir _build/src
mkdir -p _build/tools/bin

echo Copying required tools
cp src/CoreFn.Bootstrap/Program.cs _build/tools/Bootstrap.Program.cs
cp src/CoreFn.Builder/bin/Debug/netcoreapp1.0/publish/* _build/tools/bin

echo Building project
dotnet restore $1
dotnet build $1/**/project.json

FUNC=$(cat $1/.func)

echo Copying binary output
cp $1/src/$FUNC/bin/Debug/netcoreapp1.0/*.dll _build/bin

echo Building proxy and manifest
dotnet _build/tools/bin/CoreFn.Builder.dll $1/src/$FUNC/bin/Debug/netcoreapp1.0/ _build/src/$FUNC

echo Copying original source
cp -R $1/src/* _build/src
rm -rf _build/src/$FUNC/bin
rm -rf _build/src/$FUNC/obj
rm -f _build/src/$FUNC/project.lock.json

echo Copying bootstrapper
cp _build/tools/Bootstrap.Program.cs _build/src/$FUNC/Program.cs

echo Updating project.json to emit entry point
sed -i -e 's/"emitEntryPoint": false/"emitEntryPoint": true/' _build/src/$FUNC/project.json

echo Building bootstrapped program
dotnet restore _build/src/$FUNC
dotnet build _build/src/$FUNC
dotnet publish -o _build/publish _build/src/$FUNC

echo Building docker image
echo "FROM microsoft/dotnet:latest\n\nCOPY . /app\n\nENTRYPOINT [\"dotnet\", \"/app/$FUNC.dll\"]" > _build/publish/Dockerfile

SAFE_NAME="$(echo $1 | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g')"
echo name: corefn/$SAFE_NAME

docker build -t corefn/$SAFE_NAME _build/publish

echo Updating manifest store
mkdir _build/manifest
mv _build/src/$FUNC/manifest.json _build/manifest/$FUNC.json
