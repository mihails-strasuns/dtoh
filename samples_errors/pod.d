module pod;

struct S
{
    this(this)
    {
    }
}

extern(C) void foo(S x);
