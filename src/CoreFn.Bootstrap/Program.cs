using System;
using System.Diagnostics;
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
        readonly TcpClient _client;
        readonly Guid _id = Guid.NewGuid();

        public Worker(TcpClient client)
        {
            _client = client;
        }

        void Log(string message)
            => Console.WriteLine($"{DateTime.Now.Ticks} {_id}: {message}");

        public async Task Run()
        {
            var stopwatch = new Stopwatch();
            stopwatch.Start();
            Log($"Client connected");

            var stream = _client.GetStream();
            var buffer = new byte[1024];

            using (var cts = new CancellationTokenSource(500))
            using (cts.Token.Register(() => stream.Dispose()))
            {
                try
                {
                    var read = await stream.ReadAsync(buffer, 0, buffer.Length);

                    if (read == 8)
                    {
                        if (buffer[0] == 0x0F && buffer[1] == 0x0A)
                        {
                            var command = BitConverter.ToInt32(buffer, 2);

                            Proxy.Pass(command);
                        }
                    }

                    Log($"{read}: {BitConverter.ToString(buffer, 0, read)}");
                }
                catch (ObjectDisposedException)
                {
                    Log("Read timeout");
                }
            }
            Log($"Client disconnected");
            stopwatch.Stop();
            Log($"Elapsed ms: {stopwatch.ElapsedMilliseconds}");
        }
    }
}