module dtoh.exceptions;

public abstract class ConversionException : Exception
{
    import dmd.mtype : Type;

    this (Type type, string msg, string file = __FILE__, int line = __LINE__)
    {
        import std.string : format, fromStringz;

        super(
            format("[%s] %s", fromStringz(type.toPrettyChars(true)), msg),
            file,
            line
        );
    }
}

public class BadTypeKind : ConversionException
{
    import dmd.mtype : Type;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        import std.format;

        super(
            type,
            format("Type of kind '%s' can't be represented in C", type.kind()),
            file,
            line
        );
    }
}

public class NonPOD : ConversionException
{
    import dmd.mtype : Type;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        import std.format;

        super(
            type,
            "Using non-POD struct as extern(C) is likely to result in hard to debug" ~
                " differences in behaviour",
            file,
            line
        );
    }
}

public class StructFieldInit : ConversionException
{
    import dmd.mtype : Type;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        import std.format;

        super(
            type,
           "C does not support explicit field initializers in structs",
            file,
            line
        );
    }
}

public class UnnamedFunction : ConversionException
{
    import dmd.mtype : Type;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        import std.format;

        super(
            type,
            "C does not support unnamed function pointers, "
                ~ "consider using alias or named parameter",
            file,
            line
        );
    }
}

public class Oops : ConversionException
{
    import dmd.mtype : Type;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        import std.format;

        super(
            type,
           "Converter has encountered something that doesn't make sense",
            file,
            line
        );
    }
}