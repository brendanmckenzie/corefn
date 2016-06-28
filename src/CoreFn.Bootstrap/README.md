# CoreFn.Bootstrap

This wraps the executing code and is called externally over TCP.

When code is "deployed" the Program.cs file is added and Proxy.cs is generated based on the available actions in the target assembly.

A manifest file will be generated mapping functions to integer ids.