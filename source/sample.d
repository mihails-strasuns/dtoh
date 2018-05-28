module sample;

void foo_ignored () { };

extern(C):

void foo ( ) { }

int bar ( ) { return 0; }

struct S
{
    double d;
}

mixin("void foo_generated ( size_t x );");
