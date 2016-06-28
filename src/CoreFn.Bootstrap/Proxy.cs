using System;

namespace CoreFn.Bootstrap
{
    public static class Proxy
    {
        public static void Pass(int command)
        {
            Console.WriteLine($"Execute command: {command}");
            // switch statement goes here
        }
    }
}