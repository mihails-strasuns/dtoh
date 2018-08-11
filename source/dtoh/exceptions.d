module dtoh.exceptions;

/// Common base class for all dtoh exceptions
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

/// Thrown when trying to convert D type that can't be represented
/// in C directly
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

/// Thrown when trying to use non-POD struct in C bindings. This
/// generally a very bad idea because D will expect its rules
/// regarding stuff like postblit complied to, and on C side of things
/// it will be ignored.
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

/// In C struct fields can't have default initializers thus
/// it is not possible to represent D structs which uses those
/// directly.
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

/// It is only possible to link to extern(C) global variable
/// if it is also __gshared, otherwise it will land in TLS despite
/// having C mangling.
public class VariableTLS : ConversionException
{
    import dmd.mtype : Type;

    this (Type type, string file = __FILE__, int line = __LINE__)
    {
        import std.format;

        super(
            type,
           "Missing __gshared on extern(C) global variable",
            file,
            line
        );
    }
}

/// C syntax doesn't allow to express anonymous function pointer,
/// not even as another function parameter. It must always have to
/// be either bound to named parameter/variable, or get a named
/// type via typedef.
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

/// Generic exception for weird stuff that shouldn't really happen
/// but I am not sure how to explain if it really happens.
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