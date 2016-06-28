using CoreFn;

namespace TestFn
{
    public class Calculator
    {
        public class AddRequest { public int A { get; set; } public int B { get; set; } }
        public class AddResponse { public int Result { get; set; } }

        [ExportedFunction]
        public AddResponse Add(AddRequest request) =>
            new AddResponse { Result = request.A + request.B };
    }
}