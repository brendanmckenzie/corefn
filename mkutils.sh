dotnet build src/CoreFn.Builder
dotnet publish -o utils/bin src/CoreFn.Builder
cp src/CoreFn.Bootstrap/Program.cs utils/Bootstrap.Program.cs
