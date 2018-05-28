module app;

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

    auto visitor = new Generator;
    mod.accept(visitor);
}

import dmd.visitor;
import dmd.astcodegen;
import dmd.statement;

///
private extern (C++) final class Generator : Visitor
{
    import dmd.dmodule;
    import dmd.dsymbol;
    import dmd.dimport;
    import dmd.declaration;
    import dmd.attrib;
    import dmd.aggregate;
    import dmd.func;
    import dmd.dtemplate;
    import dmd.denum;
    import dmd.arraytypes;

public:  

    alias visit = Visitor.visit;

    override void visit(Dsymbol s)
    {
    }

    override void visit(Module s)
    {
        for (size_t i = 0; i < s.members.dim; i++)
        {
            (*s.members)[i].accept(this);
        }        
    }

    override void visit(Import s)
    {
    }

    override void visit(AttribDeclaration d)
    {
        Dsymbols* ds = d.include(null);
        if (ds)
        {
            for (size_t i = 0; i < ds.dim; i++)
            {
                Dsymbol s = (*ds)[i];
                s.accept(this);
            }
        }
    }

    override void visit(ConditionalDeclaration d)
    {
        if (d.condition.inc)
        {
            visit(cast(AttribDeclaration)d);
        }
        Dsymbols* ds = d.decl ? d.decl : d.elsedecl;
        for (size_t i = 0; i < ds.dim; i++)
        {
            Dsymbol s = (*ds)[i];
            s.accept(this);
        }
    }

    override void visit(TypeInfoDeclaration d)
    {
    }

    override void visit(PostBlitDeclaration d)
    {
    }

    override void visit(Declaration d)
    {
    }

    override void visit(AggregateDeclaration d)
    {
        if (d.members)
        {
            for (size_t i = 0; i < d.members.dim; i++)
            {
                Dsymbol s = (*d.members)[i];
                s.accept(this);
            }
        }
    }

    override void visit(FuncDeclaration d)
    {
        import dmd.globals : LINK;
        
        if (d.linkage != LINK.c)
            return;

        import std.stdio;
        writeln(parse(d.toChars()));
    }

    override void visit(TemplateDeclaration d)
    {
        for (size_t i = 0; i < d.members.dim; i++)
        {
            Dsymbol s = (*d.members)[i];
            s.accept(this);
        }
    }

    override void visit(EnumDeclaration d)
    {
        if (d.isAnonymous())
        {
            if (d.members)
            {
                for (size_t i = 0; i < d.members.dim; i++)
                {
                    Dsymbol s = (*d.members)[i];
                    s.accept(this);
                }
            }
            return;
        }
 
        if (d.members)
        {
            for (size_t i = 0; i < d.members.dim; i++)
            {
                Dsymbol s = (*d.members)[i];
                s.accept(this);
            }
        }
    }

    override void visit(EnumMember s)
    {
    }

    override void visit(VarDeclaration d)
    {
    }

    override void visit(TemplateMixin d)
    {
    }
}

private string parse ( in char* s )
{
    import core.stdc.string : strlen;
    auto len = strlen(s);
    return s[0 .. len].idup;
}