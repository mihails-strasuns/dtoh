/**
    Copied from `dmd.hdrgen` and simplified a lot to only care about
    top-level module declarations and descending into templates. Recursive
    processing of aggregates is not necessary because only top-level `extern(C)`
    declarations matter for C binding generation.
 */
module dtoh.visitor;

import dmd.visitor;

///
public extern (C++) class DeclarationVisitor : Visitor
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
        if (d.condition.inc == 1)
        {
            Dsymbols* ds = d.decl ? d.decl : d.elsedecl;
            for (size_t i = 0; i < ds.dim; i++)
            {
                Dsymbol s = (*ds)[i];
                s.accept(this);
            }
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
    }

    override void visit(EnumMember s)
    {
    }

    override void visit(VarDeclaration d)
    {
    }

    override void visit(TemplateMixin d)
    {
        for (size_t i = 0; i < d.members.dim; i++)
        {
            Dsymbol s = (*d.members)[i];
            s.accept(this);
        }
    }
}
