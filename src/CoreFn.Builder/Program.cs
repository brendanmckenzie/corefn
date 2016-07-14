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
            var dest = Path.GetFullPath(args[1]);

            Directory.CreateDirectory(dest);

            var functions = files
                // Filter out system
                .Where(ent => !new[] { "CoreFn" }.Contains(Path.GetFileNameWithoutExtension(ent)))
                // Load the assemblies
                .Select(ent => AssemblyLoadContext.Default.LoadFromAssemblyPath(Path.GetFullPath(ent)))
                // Get their exported types
                .SelectMany(ent => ent.ExportedTypes)
                // List the methods
                .SelectMany(ent => ent.GetRuntimeMethods())
                // Find the ones with the ExportedFunction attribute
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

            var classStr = ProxyClass.Replace(
                "$switch$",
                string.Join(Environment.NewLine,
                    functions.Select(ent =>
                        $"{new string(' ', 16)}case {ent.Index}: {{ {ProcessMethodCall(ent.Method)}; }} break;"
                    )
                )
            );
            Console.WriteLine("Writing Proxy class");
            File.WriteAllText(Path.Combine(dest, "Proxy.cs"), classStr);

            Console.WriteLine("Writing Manifest");

            var manifest = new Manifest
            {
                Functions = functions.Select(ent => new FunctionSummary
                {
                    Index = ent.Index,
                    Name = $"{ent.Type.Name}.{ent.Method.Name}",
                    Parameters = ent.Method.GetParameters().Select(p => new ParameterSummary { Name = p.Name, Type = p.ParameterType.Name })
                }).ToArray()
            };
            File.WriteAllText(Path.Combine(dest, "manifest.json"), JsonConvert.SerializeObject(manifest));

        }

        static string ProcessParameters(MethodInfo method)
        {
            var parameters = method.GetParameters();
            switch (parameters.Count())
            {
                case 0:
                    return null;
                case 1:
                    var type = parameters.First().ParameterType;
                    if (type == typeof(string))
                    {
                        return "input";
                    }
                    else
                    {
                        return $"JsonConvert.DeserializeObject<{type.FullName.Replace('+', '.')}>(input)";
                    }
                default:
                    throw new InvalidOperationException($"Only one parameter is accepted. Function: {method.Name}");
            }
        }

        static string ProcessMethodCall(MethodInfo method)
        {
            var methodCall = $"new {method.DeclaringType.FullName}().{method.Name}({ProcessParameters(method)})";

            if (method.ReturnType == typeof(void))
            {
                return methodCall;
            }
            else if (method.ReturnType == typeof(string))
            {
                return methodCall = $"var ret = {methodCall}; await callback(ret)";
            }
            else
            {
                return methodCall = $"var ret = {methodCall}; await callback(JsonConvert.SerializeObject(ret))";
            }
        }

        const string ProxyClass = @"
using System;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace CoreFn.Bootstrap
{
    public static class Proxy
    {
        public static async Task Pass(int command, string input, Func<string, Task> callback)
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