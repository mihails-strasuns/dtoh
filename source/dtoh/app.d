/**
    Entry point that binds together calling DMD frontend for parsing
    and semantic analysis of D module with dtoh specific converter which
    generates C header from resulting AST.
 */
module dtoh.app;

///
int main ( string[] args )
{   
    // CLI interface is intentionally simplistic for now

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
        writeln("If not output path is specified, everything is printed to stdout");
        return 1;
    }

    // DMD frontend library will be invoked with the same paths as
    // currently installed `dmd` on the host system. Bundling own druntime
    // and Phobos is possible but including tool itself with compiler
    // distribution would make more sense long-term.

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
import dtoh.exceptions;

/**
    dtoh converts the following symbols found in the supplied module:

    - `extern(C)` functions
    - `__gshared extern(C)` global variables
    - aliases for `extern(C)` function pointer types

    structs and enums will be only converted if they are used as part of
    declaration of the above 3 - it is currently a necessary limitation
    because DMD ignores `extern(C)` applied to `struct` and this information
    is not available in the resulting semantic tree.
 */
private extern (C++) class CDeclVisitor : DeclarationVisitor
{
    import dmd.func : FuncDeclaration;
    import dmd.declaration : AliasDeclaration, VarDeclaration;
    import dmd.dstruct : StructDeclaration;

    alias visit = DeclarationVisitor.visit;

    /// Returns: final C header as a single string
    string render ( )
    {
        return this.converter.render();
    }

    /// e.g. `extern(C) void foo()`
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

    /// e.g. `extern(C) __gshared int x`
    override void visit(VarDeclaration d)
    {
        import dmd.globals : LINK;
        import std.exception : enforce;
        import dmd.declaration : STC;

        if (d.linkage == LINK.c)
        {
            if (!(d.storage_class & STC.gshared))
                throw new VariableTLS(d.type);
            this.converter.convertDeclaration(d.type, d.ident);
        }
    }

    /// e.g. `alias foo_t = extern(C) void function()`
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