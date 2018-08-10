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
    import dmd.dstruct : StructDeclaration;

    alias visit = DeclarationVisitor.visit;

    public string render ( )
    {
        return this.converter.render();
    }

    override void visit(FuncDeclaration d)
    {
        import dmd.globals : LINK;

        if (d.linkage == LINK.c)
            this.converter.convertDeclaration(d.type, d.ident);
    }

    private Converter converter;
}