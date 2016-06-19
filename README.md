# corefn

An implementation of how .NET CoreCLR code can be executed in a reactive
manner, such as in response to external events.

## Workflow

 1. Project is created containing functionality
 2. Project is submitted to builder
 3. Builder creates docker image
 4. When triggered, runner execute docker image
