using System;

// THIS FILE IS NOT USED. IT IS REPLACED BY THE BUILD PROCESS

namespace CoreFn.Bootstrap
{
    public static class Proxy
    {
        public static void Pass(int command, string input, Action<string> callback)
        {
            Console.WriteLine($"Execute command: {command}");
            // switch statement goes here
        }
    }
}