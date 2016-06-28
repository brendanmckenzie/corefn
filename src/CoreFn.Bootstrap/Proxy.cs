using System;
using System.Threading.Tasks;

// THIS FILE IS NOT USED. IT IS REPLACED BY THE BUILD PROCESS

namespace CoreFn.Bootstrap
{
    public static class Proxy
    {
        public static async Task Pass(int command, string input, Func<string, Task> callback)
        {
            Console.WriteLine($"Execute command: {command}");
            // switch statement goes here
        }
    }
}