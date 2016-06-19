set -e

FUNCTION_NAME=TestFn

# dotnet restore ../
dotnet build ../**/project.json
dotnet publish ../src/CoreFn.Bootstrap

rm -rf _temp
mkdir _temp
cp ../test/$FUNCTION_NAME/bin/Debug/netcoreapp1.0/$FUNCTION_NAME.dll _temp/
cp ../src/CoreFn.Bootstrap/bin/Debug/netcoreapp1.0/publish/* _temp/

sed -e s/FUNCTION_NAME/$FUNCTION_NAME/g Dockerfile > _temp/Dockerfile

docker build -t corefn-test _temp