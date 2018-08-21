module funcs;

extern(C):

void foo_simple ();
void foo_with_body () { }
void foo_anon_params (int, double, char);
alias foo_t = long function(void*);
void hofoo1(foo_t);
void hofoo2(int function() param);
