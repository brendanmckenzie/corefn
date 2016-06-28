using CoreFn;

namespace TestFn
{
    public class Calculator
    {
        [ExportedFunction]
        public int Add(int a, int b) => a + b;
    }
}