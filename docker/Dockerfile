FROM microsoft/dotnet:1.0.0-rc2-core

ADD . /app

WORKDIR /app

ENTRYPOINT dotnet CoreFn.Bootstrap.dll FUNCTION_NAME
