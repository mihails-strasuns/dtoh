module enums;

enum A { one = 42 }
enum B { one = 1, two = A.one }
enum C { a, b, c }

extern(C) __gshared B var1 = B.two;
extern(C) __gshared A var2;

extern(C) B foo (B x) { return x; }
extern(C) void baz (C);
