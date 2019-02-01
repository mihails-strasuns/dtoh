module dtoh.hack;

version(Windows)
{
    import dmd.root.longdouble : longdouble_soft;

    // Workaround for linker issue with DMD FE. We simply forward implementation
    // to the one of the compiler which builds this binary instead of trying to reach
    // DMD backend.
    //
    // See https://issues.dlang.org/show_bug.cgi?id=18810
    extern(C++) longdouble_soft strtold_dm(const(char)* p, char** endp)
    {
        import core.stdc.string;
        import std.conv;
        auto len = strlen(p);
        if (endp)
            *endp = cast(char*) p + len;
        return longdouble_soft(to!real(p[0 .. len]));
    }
}