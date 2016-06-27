using System.Net;
using System.Net.Sockets;
using System.Threading.Tasks;

namespace CoreFn.Runner
{
    public static class Program
    {
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

                var buffer = new byte[] { 0x00, 0x01, 0x02, 0x04 };

                await stream.WriteAsync(buffer, 0, 4);
            }
        }
    }
}