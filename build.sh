set -e

rm -rf _build
mkdir -p _build/{bin,src}

echo Building project
dotnet build test/$1

echo Copying binary output
cp test/$1/bin/Debug/netcoreapp1.0/*.dll _build/bin

echo Building proxy and manifest
dotnet src/CoreFn.Builder/bin/Debug/netcoreapp1.0/CoreFn.Builder.dll test/$1/bin/Debug/netcoreapp1.0/ _build/src/$1

echo Copying original source
cp -R test/$1 _build/src
rm -rf _build/src/$1/{bin,obj,project.lock.json}

echo Copying bootstrapper
cp src/CoreFn.Bootstrap/Program.cs _build/src/$1

echo Updating project.json to emit entry point
sed -i -e 's/"emitEntryPoint": false/"emitEntryPoint": true/' _build/src/$1/project.json
rm _build/src/$1/project.json-e

echo Building bootstrapped program
dotnet restore _build/src/$1
dotnet build _build/src/$1