using System;
using System.Reflection;
using System.Linq;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.DependencyInjection;

namespace CoreFn.Bootstrap
{
    public class Program
    {
        public static void Main(string[] args)
        {
            var loggerFactory = new LoggerFactory();
            var log = loggerFactory.CreateLogger<Program>();

            loggerFactory.AddConsole();

            var serviceCollection = new ServiceCollection();
            serviceCollection.AddSingleton(typeof(ILoggerFactory), loggerFactory);

            log.LogInformation("CoreFn Bootstrap");

            var assemblyName = args[0];

            log.LogInformation($"Running function: {assemblyName}");

            var assm = Assembly.Load(new AssemblyName(assemblyName));
            var entryPoints = assm.GetTypes().Where(ent => ent.Name == "EntryPoint");

            var entryPoint = entryPoints.Single();

            serviceCollection.AddScoped(entryPoint, entryPoint);

            var serviceProvider = serviceCollection.BuildServiceProvider();

            var instance = serviceProvider.GetService(entryPoint);

            var runFn = entryPoint.GetMethod("Run");
            if (runFn.GetParameters().Any())
            {
                runFn.Invoke(instance, new object[] { Environment.GetEnvironmentVariable("COREFN_PARAM") });
            }
            else
            {
                runFn.Invoke(instance, null);
            }
        }
    }
}
