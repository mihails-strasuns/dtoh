# Building

```
git submodule update --init
dub build
```

# Usage

```
./dtoh -o header.h path/to/mod.d
```

# Important features

`dtoh` is built on top of actual DMD compiler frontend and does full semantical
analysis of passed in module. That allows D module to use all power of CTFE
and template meta-programming when definining C bindings, greatly reducing
manual boilerplate requires.

For example, this D module:

```D
import std.meta : AliasSeq;

static foreach (int i, T; AliasSeq!(long, int))
    mixin("extern(C) __gshared " ~ T.stringof ~ " global" ~ i.stringof ~ ";");
```

.. when converted, will result in the following C header:

```C
int64_t global0;
int32_t global1;
```


# Known limitations

This `dtoh` implementations does not try to do everything possible for
conversion to succeed and is intended to be used with D modules intentionally
crafted as target for C binding generation and not just any D module.

Because of that it will:

- Reject suspicious D code that could have been somehow converted (for example,
    non-POD structs)
- Expect converted D declarations to be written with C conversion in mind, for
  example, defining all function pointer aliases afront.
- Not try to do any overly magical magic.
