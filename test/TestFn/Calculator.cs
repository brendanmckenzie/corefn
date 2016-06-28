using CoreFn;

namespace TestFn
{
    public class Calculator
    {
        [ExportedFunction]
        public int Add(int a = 1, int b = 2) => a + b;
    }
}