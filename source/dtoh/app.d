module dtoh.app;

import dmd.frontend;

void main ( string[] args )
{    
    import dmd.globals : global;

    initDMD();
    auto ipaths = findImportPaths();
    foreach (ipath; ipaths)
        addImport(ipath);

    auto mod = parseModule(args[1]);
    mod.fullSemantic();

    auto visitor = new CDeclVisitor;
    mod.accept(visitor);

    import std.stdio;
    writeln(visitor.render());
}

import dtoh.visitor;
import dtoh.converter;

private extern (C++) class CDeclVisitor : DeclarationVisitor
{
    import dmd.func : FuncDeclaration;
    import dmd.declaration : VarDeclaration;
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

    private Converter converter;
}