dotnet build ../../src/CoreFn.Builder
dotnet publish -o build/utils/bin ../../src/CoreFn.Builder
cp ../../src/CoreFn.Bootstrap/Program.cs build/utils/Bootstrap.Program.cs
