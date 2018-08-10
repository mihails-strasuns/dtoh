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

alias Seq(T...) = T;

static foreach (int i, T; Seq!(S, int))
    mixin("extern(C) __gshared " ~ T.stringof ~ " global" ~ i.stringof ~ ";");
