module codegen;

import std.meta : AliasSeq;

static foreach (int i, T; AliasSeq!(double, int))
    mixin("extern(C) __gshared " ~ T.stringof ~ " global" ~ i.stringof ~ ";");

template T ( )
{
    alias foo_t = extern(C) void function();
}

mixin T;

static if (true)
    extern(C) __gshared foo_t callback;
else
    extern(C) __gshared foo_t no_callback;
