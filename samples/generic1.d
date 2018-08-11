module sample;

void foo_ignored () { };

extern(C) {
    void foo ( ) { }

    int bar ( ) { return 0; }

    struct S
    {
        double d;
    }

    mixin("S foo_generated ( size_t x );");
}

import std.meta : AliasSeq;

static foreach (int i, T; AliasSeq!(S, int))
    mixin("extern(C) __gshared " ~ T.stringof ~ " global" ~ i.stringof ~ ";");


alias foo_t = extern(C) void function();

enum E
{
    A,
    B
}

extern(C):

float baz(E, foo_t);
