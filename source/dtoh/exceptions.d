module dtoh.exceptions;

alias WarningHandler = void delegate(string);

public abstract class ConversionException : Exception
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}

public class NotSupported : ConversionException
{
    import dmd.mtype : Type;
    import core.stdc.string : strlen;
    import std.format;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        char* pretty = type.toPrettyChars(true);
        size_t pretty_ln = strlen(pretty);
        super(
            format("Type '%s' of kind '%s' can't be represented in C",
                pretty[0 .. pretty_ln], type.kind()),
            file, line
        );
    }
}

public class InformationLoss : ConversionException
{
    import std.exception : basicExceptionCtors;
    mixin basicExceptionCtors;
}