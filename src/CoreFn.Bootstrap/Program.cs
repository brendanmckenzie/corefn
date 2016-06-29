using System;
using System.Diagnostics;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
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
            try
            {
                var totalBuffer = Enumerable.Empty<byte>();

                var read = 0;
                var buffer = new byte[1024];
                while ((read = await stream.ReadAsync(buffer, 0, buffer.Length)) > 0)
                {
                    totalBuffer = totalBuffer.Concat(buffer.Take(read));
                    if (BitConverter.ToInt32(totalBuffer.Skip(totalBuffer.Count() - 4).Take(4).ToArray(), 0) == 0)
                    {
                        break;
                    }
                    Log($"{read}: {BitConverter.ToString(buffer, 0, read)}");
                }

                if (totalBuffer.ElementAt(0) == 0x0F && totalBuffer.ElementAt(1) == 0x0A)
                {
                    var command = BitConverter.ToInt32(totalBuffer.Skip(2).Take(4).ToArray(), 0);
                    var request = Encoding.UTF8.GetString(totalBuffer.Skip(8).ToArray());

                    Log($"cmd: {command}. request: {request}");

                    try
                    {
                        await Proxy.Pass(command, request, async (response) =>
                        {
                            Log($"writing response: {response}");

                            var responseBuffer = Encoding.UTF8.GetBytes(response);

                            await stream.WriteAsync(responseBuffer, 0, responseBuffer.Length);
                        });
                    }
                    catch (Exception ex)
                    {
                        Log($"Exception: {ex.Message}");
                        throw;
                    }
                }
            }
            catch (Exception ex)
            {
                Log($"Exception handling client request: {ex.Message}");
            }
            finally
            {
                stream.Dispose();
            }

            Log($"Client disconnected");
            stopwatch.Stop();
            Log($"Elapsed ms: {stopwatch.ElapsedMilliseconds}");
        }
    }
}
