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
}

import dtoh.visitor;
import dtoh.typeconv;

private extern (C++) class CDeclVisitor : DeclarationVisitor
{
    import dmd.func : FuncDeclaration;

    alias visit = DeclarationVisitor.visit;

    override void visit(FuncDeclaration d)
    {
        import dmd.globals : LINK;
        import dmd.mtype : TypeFunction;
        import std.algorithm : map;
        import std.range : join;    

        if (d.linkage != LINK.c)
            return;

        string params;

        auto t = cast(TypeFunction) d.type;

        if (t.parameters !is null)
        {           
            params = (*t.parameters)[]
                .map!(param => convert(param.type, param.ident))
                .join(", ");
        }

        import std.stdio;

        writefln(
            "%s %s(%s);",
            convert(t.next),
            d.ident.toString(),
            params            
        );
    }
}