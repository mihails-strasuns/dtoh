module dtoh.app;

int main ( string[] args )
{    
    import std.getopt;

    string output_file_path;

    auto info = getopt(
        args,
        "output|o", &output_file_path,
    );

    if (args.length != 2 || info.helpWanted)
    {
        import std.stdio;
        writeln("USAGE: dtoh -o <output path> <D module path>");
        return 1;
    }

    import dmd.globals : global;
    import dmd.frontend;

    initDMD();
    auto ipaths = findImportPaths();
    foreach (ipath; ipaths)
        addImport(ipath);

    auto mod = parseModule(args[1]);
    mod.fullSemantic();

    auto visitor = new CDeclVisitor;
    mod.accept(visitor);

    auto header = visitor.render();

    if (output_file_path.length)
    {
        import std.file;
        write(output_file_path, header);
    }
    else
    {
        import std.stdio;
        writeln(header);
    }
    
    return 0;
}

import dtoh.visitor;
import dtoh.converter;

private extern (C++) class CDeclVisitor : DeclarationVisitor
{
    import dmd.func : FuncDeclaration;
    import dmd.declaration : AliasDeclaration, VarDeclaration;
    import dmd.dstruct : StructDeclaration;

    alias visit = DeclarationVisitor.visit;

    public string render ( )
    {
        return this.converter.render();
    }

    override void visit(FuncDeclaration d)
    {
        import dmd.globals : LINK;
        import dmd.mtype : TypeFunction;

        if (d.linkage == LINK.c)
        {
            this.converter.convertDeclaration(
                cast(TypeFunction) d.type, d.ident);
        }
    }

    override void visit(VarDeclaration d)
    {
        import dmd.globals : LINK;
        import std.exception : enforce;
        import dmd.declaration : STC;

        if (d.linkage == LINK.c)
        {
            enforce(d.storage_class & STC.gshared);
            this.converter.convertDeclaration(d.type, d.ident);
        }
    }

    override void visit(AliasDeclaration d)
    {
        import dmd.globals : LINK;
        import dmd.mtype : ENUMTY, TypeFunction, TypePointer, Type;

        TypeFunction isFunctionPointer (Type t)
        {
            if (t.ty == ENUMTY.Tfunction)
                return t.toTypeFunction();
            if (t.ty == ENUMTY.Tpointer)
            {
                auto tp = cast(TypePointer) t;
                if (tp.next.ty == ENUMTY.Tfunction)
                    return tp.next.toTypeFunction();
            }

            return null;
        }

        if (auto tf = isFunctionPointer(d.getType()))
        {  
            if (tf.linkage == LINK.c)
            {
                this.converter.convertDeclaration(tf, d.ident, true);
            }
        }
    }

    private Converter converter;
}