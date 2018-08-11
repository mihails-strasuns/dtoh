/**
    Core part of dtoh - recursive converter for types and declarations
    to their C equivalent.

    `convertDeclaration` family of methods is used to convert actual
    top-level symbols like function or struct declarations. To ensure
    correct order of declarations and no duplicates different kinds of
    generated output are stored separately in the `Output` sub-struct
    and only merged together when `render` is called.

    `convert` family of methods is used to correctly represent types
    used as part of declarations. If it ever encounters struct/enum
    type, it adds it to the mapping of struct/enum declarations to
    be converted.
 */
module dtoh.converter;

import dmd.mtype;
import dmd.identifier;
import dmd.dstruct;
import dmd.globals;
import dmd.declaration;
import dmd.init;
import dmd.expression;

import dtoh.exceptions;

/// ditto
struct Converter
{
    public void convertDeclaration (Type t, Identifier ident)
    {
        import std.format : format;

        // global variable
        this.output.declarations ~=
            format("%s %s;", this.convert(t), ident.toString());
    }

    public void convertDeclaration (TypeFunction t, Identifier ident,
        bool typedef = false)
    {
        import std.algorithm : map;
        import std.range : join;
        import std.format : format;

        string params;

        if (t.parameters !is null)
        {
            params = (*t.parameters)[]
                .map!(param => convert(param.type, param.ident))
                .join(", ");
        }

        if (typedef)
        {
            this.output.fptr_typedef_declarations ~= format(
                "typedef %s (*%s)(%s);",
                convert(t.next),
                ident.toString(),
                params
            );
            this.output.fptr_typedefs[cast(void*) t] = ident.toString().idup;
        }
        else
        {
            this.output.declarations ~= format(
                "%s %s(%s);",
                convert(t.next),
                ident.toString(),
                params
            );
        }
    }

    public void convertDeclaration (TypeStruct t)
    {
        auto pt = cast(void*) t;
        if (pt in this.output.structs)
            return;

        if (!t.sym.isPOD())
            throw new NonPOD(t);

        import std.algorithm : map;
        import std.range : join;
        import std.format : format;

        string fieldToString (VarDeclaration field)
        {
            if (field._init !is null)
                throw new StructFieldInit(t);

            return format(
                "    %s %s;",
                convert(field.type),
                field.ident.toString()
            );
        }

        auto fields = t.sym.fields[]
            .map!fieldToString
            .join("\n");

        if (fields.length)
            fields ~= "\n";

        this.output.structs[pt] = format(
            "struct %s\n{\n%s};",
            t.sym.ident.toString(),
            fields
        );
    }

    public void convertDeclaration (TypeEnum t)
    {
        auto pt = cast(void*) t;
        if (pt in this.output.enums)
            return;

        import std.algorithm : map;
        import std.range : join;
        import dmd.dsymbol;
        import std.format : format;

        string fields;

        string formatEnumMember (Dsymbol sym)
        {
            import std.string;

            auto member = sym.isEnumMember();
            if (member is null)
                throw new Oops(t);

            return format(
                "    %s_%s = %s",
                t.sym.ident.toString(),
                member.ident.toString(),
                fromStringz(member.origValue.toChars())
            );
        }

        if (t.sym.members !is null)
        {
            fields = (*t.sym.members)[]
                .map!formatEnumMember
                .join(",\n");

            if (fields.length)
                fields ~= "\n";
        }

        this.output.enums[pt] = format(
            "enum %s\n{\n%s};",
            t.sym.ident.toString(),
            fields
        );
    }

    private string convert (Type t, Identifier name = null)
    {
        if (auto tb = t.isTypeBasic())
            return this.convert(tb);

        switch (t.ty) with (ENUMTY)
        {
            case Tpointer:
                return this.convert(cast(TypePointer) t);
            case Tfunction:
                return this.convert(cast(TypeFunction) t, name);
            case Tstruct:
                return this.convert(cast(TypeStruct) t);
            case Tenum:
                return this.convert(cast(TypeEnum) t);

            default:
                throw new BadTypeKind(t);
        }
    }

    private string convert (TypeBasic t)
    {
        switch (t.ty)
        {
            case Tvoid: return "void";
            case Tbool: return "bool";
            case Tchar: return "char";

            case Tint8:  return "int8_t";
            case Tuns8:  return "uint8_t";
            case Tint16: return "int16_t";
            case Tuns16: return "uint16_t";
            case Tint32: return "int32_t";
            case Tuns32: return "uint32_t";
            case Tint64: return "int64_t";
            case Tuns64: return "uint64_t";

            case Tfloat32: return "float";
            case Tfloat64: return "double";
            case Tfloat80: return "long double";

            case Timaginary32: return "_Imaginary float";
            case Timaginary64: return "_Imaginary double";
            case Timaginary80: return "_Imaginary long double";

            case Tcomplex32: return "_Complex float";
            case Tcomplex64: return "_Complex double";
            case Tcomplex80: return "_Complex long double";

            case Twchar:
            case Tdchar:
            case Tint128:
            case Tuns128:
                throw new BadTypeKind(t);

            default:
                assert(false);
        }
    }

    private string convert (TypePointer t)
    {
        if (t.next.ty == ENUMTY.Tfunction)
            return convert(t.next);
        else
            return convert(t.next) ~ "*";
    }

    private string convert (TypeFunction t, Identifier name)
    {
        import std.algorithm : map;
        import std.range : join;
        import std.format : format;

        auto exists_typedef = ((cast(void*) t) in this.output.fptr_typedefs);
        if (exists_typedef ! is null)
            return *exists_typedef;

        if (name is null)
            throw new UnnamedFunction(t);

        string ret = convert(t.next);
        string params;

        if (t.parameters !is null)
        {
            params = (*t.parameters)[]
                .map!(param => convert(param.type, param.ident))
                .join(", ");
        }

        return format(
            "%s (*%s)(%s)",
            ret,
            name.toString(),
            params
        );
    }

    private string convert (TypeStruct t)
    {
        this.convertDeclaration(t);
        return "struct " ~ t.sym.ident.toString().idup;
    }

    private string convert (TypeEnum t)
    {
        this.convertDeclaration(t);
        return "enum " ~ t.sym.ident.toString().idup;
    }

    public string render ( )
    {
        import std.range;
        import std.algorithm : map;

        auto forward_decls = this.output.structs.keys.map!((key) {
            auto name = (cast(TypeStruct) key).sym.ident.toString().idup;
            return "struct " ~ name ~ ";";
        }).array();

        return only(
            [ "#include <stdint.h>" ],
            [ "// Used enum definitions:" ],
            this.output.enums.values,
            [ "// Struct forward declaration to resolve cycles:" ],
            forward_decls,
            [ "// Function pointer types:" ],
            this.output.fptr_typedef_declarations,
            [ "// Used struct definitions:" ],
            this.output.structs.values,
            [ "// Variable and function declarations:" ],
            this.output.declarations
        ).map!(x => x.join("\n"))
         .join("\n\n") ~ "\n";
    }

    private struct Output
    {
        /// Mapping of TypeEnum addresses to matching C declarations
        string[void*] enums;
        /// Mapping of TypeStruct addresses to matching C declarations
        string[void*] structs;
        /// Mapping of TypeFunction addresses to alias names, will be turned
        /// into C typedefs. NB: it doesn't seem possible to distinguish
        /// between two different aliases to the same type in DMD frontend
        /// so dtoh will pick the first one declared for all use cases.
        string[void*] fptr_typedefs;
        /// Declarations for function pointer typedefs
        string[] fptr_typedef_declarations;
        /// Declarations for functions and global variables
        string[] declarations;
    }

    private Output output;
}

version(unittest)
{
    shared static this ()
    {
        Type.stringtable._init();
    }

    private Loc dummy_loc;
}

unittest
{
    Converter x;
    x.convertDeclaration(new TypeBasic(Tvoid), new Identifier("x"));
    assert(x.output.declarations == [ "void x;" ]);
}

unittest
{
    Converter x;
    x.convertDeclaration(
        new TypePointer(
            new TypePointer(new TypeBasic(Tchar))),
        new Identifier("p")
    );
    assert(x.output.declarations == [ "char** p;" ]);
}

unittest
{
    import dmd.arraytypes;
    Parameters params;

    params.push(new Parameter(
        0,
        new TypeBasic(ENUMTY.Tint16),
        new Identifier("param1"),
        null,
        null
    ));

    params.push(new Parameter(
        0,
        new TypePointer(new TypeBasic(ENUMTY.Tfloat32)),
        new Identifier("param2"),
        null,
        null
    ));

    auto foo = new TypeFunction(
        &params,
        new TypeBasic(ENUMTY.Tvoid),
        0,
        LINK.init
    );

    Converter x;
    x.convertDeclaration(foo, new Identifier("foo"));
    assert(x.output.declarations == [ "void foo(int16_t, float*);" ]);
}

unittest
{
    auto s = new TypeStruct(new StructDeclaration(
        dummy_loc,
        new Identifier("S"),
        false
    ));

    s.sym.fields.push(new VarDeclaration(
        dummy_loc,
        new TypeBasic(ENUMTY.Tint16),
        new Identifier("field1"),
        null
    ));

    s.sym.fields.push(new VarDeclaration(
        dummy_loc,
        new TypePointer(new TypeBasic(ENUMTY.Tvoid)),
        new Identifier("field2"),
        null
    ));

    Converter x;
    x.convertDeclaration(s);
    assert(x.output.structs[cast(void*) s] ==
"struct S
{
    int16_t field1;
    void* field2;
};");
}

unittest
{
    import dmd.denum;
    import dmd.dsymbol;
    import dmd.dscope;

    auto e = new TypeEnum(new EnumDeclaration(
        dummy_loc,
        new Identifier("E"),
        new TypeBasic(ENUMTY.Tint64)
    ));

    Converter x;
    x.convert(e);
    assert(x.output.enums[cast(void*) e] == "enum E\n{\n};");
}