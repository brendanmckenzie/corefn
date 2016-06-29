using System;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
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

                var packet = Header
                    .Concat(BitConverter.GetBytes(2147483647)) // command
                    .Concat(Footer)
                    .Concat(Encoding.UTF8.GetBytes("{\"A\":1,\"B\":2}"))
                    .Concat(BitConverter.GetBytes(0))
                    .ToArray();

                await stream.WriteAsync(packet, 0, packet.Length);

                // if (stream.DataAvailable)
                {
                    var read = 0;
                    var buffer = new byte[1024];
                    var totalBuffer = Enumerable.Empty<byte>();
                    while ((read = await stream.ReadAsync(buffer, 0, buffer.Length)) > 0)
                    {
                        totalBuffer = totalBuffer.Concat(buffer.Take(read).ToArray());
                    }

                    Console.WriteLine($"Response: {Encoding.UTF8.GetString(totalBuffer.ToArray())}");
                }
            }
        }
    }
}
