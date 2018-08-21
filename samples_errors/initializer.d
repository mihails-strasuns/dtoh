module initializer;

struct S
{
    int x = 42;
}

extern(C) __gshared S try_me;
