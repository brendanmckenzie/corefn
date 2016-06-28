using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.Loader;
using Newtonsoft.Json;

namespace CoreFn.Builder
{
    public static class Program
    {
        static void Log(string message)
            => Console.WriteLine(message);

        public static void Main(string[] args)
        {
            var files = Directory.GetFiles(args[0], "*.dll");

            var functions = files
                .Where(ent => !new[] { "CoreFn" }.Contains(Path.GetFileNameWithoutExtension(ent)))
                .Select(ent => AssemblyLoadContext.Default.LoadFromAssemblyPath(Path.GetFullPath(ent)))
                .SelectMany(ent => ent.ExportedTypes)
                .SelectMany(ent => ent.GetRuntimeMethods())
                .Where(ent => ent.GetCustomAttribute<ExportedFunctionAttribute>() != null)
                .Select((ent, index) => new FunctionInfo
                {
                    Type = ent.DeclaringType,
                    Method = ent,
                    Index = int.MaxValue - index,
                    Parameters = ent.GetParameters().Select(p => new ParameterSummary { Name = p.Name, Type = p.ParameterType.Name })
                });

            if (!functions.Any())
            {
                throw new InvalidOperationException("No exported functions found");
            }

            var classStr = ProxyClass.Replace("$switch$", string.Join(Environment.NewLine, functions.Select(ent => $"{new string(' ', 16)}case {ent.Index}: {ent.Type.FullName}.{ent.Method.Name}();")));
            Console.WriteLine("Proxy class");
            Console.WriteLine(classStr);
            Console.WriteLine();

            var manifest = new Manifest
            {
                Functions = functions.Select(ent => new FunctionSummary
                {
                    Index = ent.Index,
                    Name = $"{ent.Type.Name}.{ent.Method.Name}",
                    Parameters = ent.Method.GetParameters().Select(p => new ParameterSummary { Name = p.Name, Type = p.ParameterType.Name })
                }).ToArray()
            };
            Console.WriteLine("Manifest");
            Console.WriteLine(JsonConvert.SerializeObject(manifest, Formatting.Indented));

            // TODO: write to files/directory
        }

        const string ProxyClass = @"
using System;

namespace CoreFn.Bootstrap
{
    public static class Proxy
    {
        public static void Pass(int command)
        {
            switch (command)
            {
$switch$
            }
        }
    }
}
";
    }

    class FunctionInfo
    {
        public Assembly Assembly { get; set; }
        public Type Type { get; set; }
        public MethodInfo Method { get; set; }
        public int Index { get; set; }
        public IEnumerable<ParameterSummary> Parameters { get; set; }
    }

    class FunctionSummary
    {
        public int Index { get; set; }
        public string Name { get; set; }
        public IEnumerable<ParameterSummary> Parameters { get; set; }
    }

    class ParameterSummary
    {
        public string Type { get; set; }
        public string Name { get; set; }
    }

    class Manifest
    {
        public IEnumerable<FunctionSummary> Functions { get; set; }
    }
}