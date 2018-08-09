module dtoh.typeconv;

import dmd.mtype;
import dmd.identifier;
import dmd.dstruct;
import dmd.globals;
import dmd.declaration;
import dmd.init;
import dmd.expression;

import std.format;
import std.exception : enforce;

import dtoh.exceptions;

public string convert (Type t, Identifier ident = null)
{
    if (auto tb = t.isTypeBasic())
        return convert(tb);
    
    switch (t.ty)
    {
        with (ENUMTY)
        {
            case Tpointer: return convert(cast(TypePointer) t);            
            case Tfunction: return convert(cast(TypeFunction) t, ident);
            case Tstruct: return convert(cast(TypeStruct) t);
            case Tenum: return convert(cast(TypeEnum) t);
            case Tnull: return "NULL";
            
            default:
                throw new NotSupported(t);
        }
    }
}

version(unittest)
{
    shared static this ()
    {
        Type.stringtable._init();
    }

    private Loc dummy_loc;
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
            throw new NotSupported(t);

        default:
            assert(false);
    }
}

unittest
{
    assert(convert(new TypeBasic(Tvoid)) == "void");
}

private string convert (TypePointer t)
{
    return convert(t.next) ~ "*";
}

unittest
{
    assert(convert(new TypePointer(
        new TypePointer(new TypeBasic(Tchar)))) == "char**");
}

private string convert (TypeFunction t, Identifier ident)
{
    import std.algorithm : map;
    import std.range : join;

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
        ident.toString(),
        params
    );
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
    
    assert(
        convert(foo, new Identifier("foo")) ==
            "void (*foo)(int16_t, float*)"
    );
}

private string convert (TypeStruct t)
{
    enforce!InformationLoss(
        t.sym.isPOD(),
        "Using non-POD struct as extern(C) can resul in hard to debug" ~
            " difference in behaviour"
    );

    import std.algorithm : map;
    import std.range : join;

    string fieldToString (VarDeclaration field)
    {
        enforce!InformationLoss(
            field._init is null,
            "C does not support explicit field initializers in structs"
        );

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

    return format(
        "struct %s\n{\n%s}",
        t.sym.ident.toString(),
        fields
    );
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

    assert(convert(s) ==
"struct S
{
    int16_t field1;
    void* field2;
}");
}

private string convert (TypeEnum t)
{
    import std.algorithm : map;
    import std.range : join;
    import dmd.dsymbol;

    string fields;
    
    string formatEnumMember (Dsymbol sym)
    {
        auto member = sym.isEnumMember();
        enforce(member !is null);

        return format(
            "%s = %s",
            member.ident.toString(),
            member.value.toChars()
        );
    }

    if (t.sym.members !is null)
    {
        fields = (*t.sym.members)[]
            .map!formatEnumMember
            .join("\n");

        if (fields.length)
            fields ~= "\n";
    }

    return format(
        "enum %s\n{\n%s}",
        t.sym.ident.toString(),
        fields
    );
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

    assert(convert(e) == "enum E\n{\n}");
}