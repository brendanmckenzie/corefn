using System;
using System.Net;
using System.Net.Sockets;
using System.Threading;
using System.Threading.Tasks;

namespace CoreFn.Bootstrap
{
    public static class Program
    {
        public static void Main(string[] args)
        {
            Run().Wait();
        }

        public static async Task Run()
        {
            var listener = new TcpListener(IPAddress.Any, 6543);
            listener.Start();
            Console.WriteLine("Listening on port 6543");
            while (true)
            {
                var worker = new Worker(await listener.AcceptTcpClientAsync());

                RunAsyncThread(worker.Run);
            }
        }

        public static void RunAsyncThread(Func<Task> fn)
        {
            new Thread(async () => { await fn(); }).Start();
        }
    }

    public class Worker
    {
        static short CommandHeader = BitConverter.ToInt16(new byte[] { 0xA0, 0x0F }, 0);
        readonly TcpClient _client;
        public Worker(TcpClient client)
        {
            _client = client;
        }

        public async Task Run()
        {
            Console.WriteLine($"Client connected");

            var stream = _client.GetStream();
            while (_client.Connected)
            {
                var buffer = new byte[1024];
                var read = await stream.ReadAsync(buffer, 0, buffer.Length);

                if (read > 0)
                {
                    for (var i = 0; i < read; i++)
                    {
                        if (i + 6 < buffer.Length)
                        {
                            var header = BitConverter.ToInt16(buffer, 0);
                            if (header == CommandHeader)
                            {
                                var command = BitConverter.ToInt32(buffer, 3);

                                Proxy.Pass(command);
                            }
                        }
                    }

                    Console.WriteLine($"{read}: {BitConverter.ToString(buffer, 0, read)}");
                }
            }
            Console.WriteLine($"Client disconnected");
        }
    }

    public static class Proxy
    {
        public static void Pass(int command)
        {
            Console.WriteLine($"Execute command: {command}");
            // switch statement goes here
        }
    }
}