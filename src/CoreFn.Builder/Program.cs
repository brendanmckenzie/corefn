using Microsoft.CodeAnalysis.CSharp;
using Microsoft.CodeAnalysis.CSharp.Syntax;
using System;

namespace CoreFn.Builder
{
    public static class Program
    {
        public static void Main(string[] args)
        {

            var method = SyntaxFactory.MethodDeclaration(SyntaxFactory.IdentifierName("method"), "FindMethod");


            var @switch = SyntaxFactory.SwitchStatement(SyntaxFactory.IdentifierName("method"));
            var cls = SyntaxFactory.ClassDeclaration("HelloWorld");

            var workspace = new CustomWorkspace();
            var code = Formatter.Format(cls, workspace);

            Console.WriteLine(code.ToFullString());
        }
    }
}