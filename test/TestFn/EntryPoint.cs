using Microsoft.Extensions.Logging;

namespace TestFn
{
    public class EntryPoint
    {
        readonly ILogger _log;

        public EntryPoint(ILoggerFactory loggerFactory)
        {
            _log = loggerFactory.CreateLogger<EntryPoint>();
        }

        public void Run(string param)
        {
            _log.LogInformation("Hello from TestFn!");
            _log.LogInformation($"Input: {param}");
        }
    }
}