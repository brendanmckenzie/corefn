using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;

namespace CoreFn.Runner
{
    public static class Program
    {
        static byte[] Header = new byte[] { 0x0F, 0x0A };
        static byte[] Footer = new byte[] { 0xFF, 0xAA };
        public static void Main(string[] args)
        {
            Run().Wait();
        }

        public static async Task Run()
        {
            using (var client = new TcpClient())
            {
                await client.ConnectAsync(IPAddress.Loopback, 6543);

                var stream = client.GetStream();

                var buffer = Header
                    .Concat(BitConverter.GetBytes(10))
                    .Concat(Footer)
                    .ToArray();

                // System.Threading.Thread.Sleep(1000);

                await stream.WriteAsync(buffer.ToArray(), 0, buffer.Count());
            }
        }
    }
}