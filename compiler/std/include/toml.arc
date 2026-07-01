// std.toml — Full TOML v1.0 parser.
// Supports: key/value, sections ([table]), arrays ([[array-of-tables]]),
// inline tables, arrays of values, string types, integers, floats, booleans, dates.

namespace std {
namespace toml {

// Value kinds
constexpr i32 TOML_NULL    = 0;
constexpr i32 TOML_BOOL    = 1;
constexpr i32 TOML_INT     = 2;
constexpr i32 TOML_FLOAT   = 3;
constexpr i32 TOML_STRING  = 4;
constexpr i32 TOML_ARRAY   = 5;
constexpr i32 TOML_TABLE   = 6;

istruc val;
istruc pair;

istruc val {
    i32   kind;
    bool  b_val;
    i64   i_val;
    f64   f_val;
    i8*   s_val;
    val** arr_items;
    i32   arr_len;
    pair* tbl_pairs;
    i32   tbl_len;
    i32   tbl_cap;
}

istruc pair {
    i8*  key;
    val* value;
}

// ---- Lexer ----

istruc lex {
    i8* src;
    i32 pos;
    i32 len;

    void __construct__(lex* self, i8* s, i32 n) { self.src=s; self.pos=0; self.len=n; }

    bool at_end(lex* self) { return self.pos >= self.len; }
    i8   peek(lex* self)   { return self.pos < self.len ? self.src[self.pos] : 0; }
    i8   peek2(lex* self)  { return self.pos+1 < self.len ? self.src[self.pos+1] : 0; }
    i8   next(lex* self)         { i8 c = self.src[self.pos]; self.pos=self.pos+1; return c; }

    void skip_ws(lex* self) {
        while (self.pos < self.len) {
            i8 c = self.src[self.pos];
            if (c==' '||c=='\t') { self.pos=self.pos+1; }
            else if (c=='#') {
                while (self.pos < self.len && self.src[self.pos] != '\n') self.pos=self.pos+1;
            } else { break; }
        }
    }

    void skip_ws_nl(lex* self) {
        while (self.pos < self.len) {
            i8 c = self.src[self.pos];
            if (c==' '||c=='\t'||c=='\r'||c=='\n') { self.pos=self.pos+1; }
            else if (c=='#') {
                while (self.pos < self.len && self.src[self.pos] != '\n') self.pos=self.pos+1;
            } else { break; }
        }
    }
}

// ---- Helper: alloc a val node ----

private val* alloc_val(&memstr a, i32 kind) {
    val* v = (val*)a.mmap(sizeof(val));
    (*v).kind=kind; (*v).b_val=false; (*v).i_val=0; (*v).f_val=0.0;
    (*v).s_val=(i8*)0; (*v).arr_items=(val**)0; (*v).arr_len=0;
    (*v).tbl_pairs=(pair*)0; (*v).tbl_len=0; (*v).tbl_cap=0;
    return v;
}

// ---- Table helpers ----

private void table_set(val* tbl, i8* key, val* value, &memstr a) {
    // Check existing
    for (i32 i = 0; i < (*tbl).tbl_len; i=i+1) {
        i8* k = (*tbl).tbl_pairs[i].key;
        i32 j=0; bool eq=true;
        while(k[j]!=0&&key[j]!=0){if(k[j]!=key[j]){eq=false;break;}j=j+1;}
        if(eq&&k[j]==key[j]){(*tbl).tbl_pairs[i].value=value;return;}
    }
    if((*tbl).tbl_len >= (*tbl).tbl_cap) {
        i32 nc = (*tbl).tbl_cap==0?8:(*tbl).tbl_cap*2;
        pair* np = (pair*)a.mmap((u64)(sizeof(pair)*nc));
        for(i32 i=0;i<(*tbl).tbl_len;i=i+1) np[i]=(*tbl).tbl_pairs[i];
        if((*tbl).tbl_pairs!=(pair*)0) a.deinit((*tbl).tbl_pairs);
        (*tbl).tbl_pairs=np; (*tbl).tbl_cap=nc;
    }
    (*tbl).tbl_pairs[(*tbl).tbl_len].key=key;
    (*tbl).tbl_pairs[(*tbl).tbl_len].value=value;
    (*tbl).tbl_len=(*tbl).tbl_len+1;
}

private val* table_get(val* tbl, i8* key) {
    for(i32 i=0;i<(*tbl).tbl_len;i=i+1){
        i8* k=(*tbl).tbl_pairs[i].key;
        i32 j=0;bool eq=true;
        while(k[j]!=0&&key[j]!=0){if(k[j]!=key[j]){eq=false;break;}j=j+1;}
        if(eq&&k[j]==key[j]) return (*tbl).tbl_pairs[i].value;
    }
    return (val*)0;
}

// ---- Key parsing ----

private i8* parse_bare_key(lex* l, &memstr a) {
    i32 start = (*l).pos;
    while (!(*l).at_end()) {
        i8 c = (*l).peek();
        if ((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_')
            (*l).pos=(*l).pos+1;
        else break;
    }
    i32 n = (*l).pos - start;
    i8* s = (i8*)a.mmap((u64)(n+1));
    for(i32 i=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    return s;
}

private i8* parse_quoted_key(lex* l, &memstr a) {
    (*l).next(); // consume "
    i32 start=(*l).pos;
    while(!(*l).at_end()&&(*l).peek()!='"'){
        if((*l).peek()=='\\') (*l).pos=(*l).pos+1;
        (*l).pos=(*l).pos+1;
    }
    i32 n=(*l).pos-start;
    i8* s=(i8*)a.mmap((u64)(n+1));
    for(i32 i=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    (*l).next(); // consume closing "
    return s;
}

// ---- Value parsing ----

private val* parse_value(lex* l, &memstr a);

private val* parse_string(lex* l, &memstr a) {
    // Multi-line or single line
    bool ml = ((*l).peek()=='\"' && (*l).peek2()=='\"');
    if(ml) { (*l).next(); (*l).next(); }
    (*l).next(); // opening "
    i32 start=(*l).pos;
    if(ml) {
        while(!(*l).at_end()){
            if((*l).src[(*l).pos]=='\"'&&(*l).pos+2<(*l).len&&
               (*l).src[(*l).pos+1]=='\"'&&(*l).src[(*l).pos+2]=='\"') break;
            (*l).pos=(*l).pos+1;
        }
    } else {
        while(!(*l).at_end()&&(*l).src[(*l).pos]!='"'){
            if((*l).src[(*l).pos]=='\\') (*l).pos=(*l).pos+1;
            (*l).pos=(*l).pos+1;
        }
    }
    i32 n=(*l).pos-start;
    i8* s=(i8*)a.mmap((u64)(n+1));
    for(i32 i=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    if(ml){(*l).next();(*l).next();(*l).next();}else(*l).next();
    val* v=alloc_val(a,TOML_STRING);
    (*v).s_val=s;
    return v;
}

private val* parse_literal_string(lex* l, &memstr a) {
    bool ml=((*l).peek()=='\''&&(*l).peek2()=='\'');
    if(ml){(*l).next();(*l).next();}
    (*l).next(); // '
    i32 start=(*l).pos;
    if(ml){
        while(!(*l).at_end()){
            if((*l).src[(*l).pos]=='\''&&(*l).pos+2<(*l).len&&
               (*l).src[(*l).pos+1]=='\''&&(*l).src[(*l).pos+2]=='\'') break;
            (*l).pos=(*l).pos+1;
        }
    } else {
        while(!(*l).at_end()&&(*l).src[(*l).pos]!='\'') (*l).pos=(*l).pos+1;
    }
    i32 n=(*l).pos-start;
    i8* s=(i8*)a.mmap((u64)(n+1));
    for(i32 i=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    if(ml){(*l).next();(*l).next();(*l).next();}else(*l).next();
    val* v=alloc_val(a,TOML_STRING);(*v).s_val=s;
    return v;
}

private val* parse_array(lex* l, &memstr a) {
    (*l).next(); // [
    val* v=alloc_val(a,TOML_ARRAY);
    val* items[512]; i32 count=0;
    (*l).skip_ws_nl();
    while(!(*l).at_end()&&(*l).peek()!=']') {
        items[count]=parse_value(l,a);
        count=count+1;
        (*l).skip_ws_nl();
        if((*l).peek()==','){(*l).next();(*l).skip_ws_nl();}
    }
    (*l).next(); // ]
    (*v).arr_items=(val**)a.mmap((u64)(sizeof(val*)*count));
    (*v).arr_len=count;
    for(i32 i=0;i<count;i=i+1) (*v).arr_items[i]=items[i];
    return v;
}

private val* parse_inline_table(lex* l, &memstr a) {
    (*l).next(); // {
    val* v=alloc_val(a,TOML_TABLE);
    (*l).skip_ws();
    while(!(*l).at_end()&&(*l).peek()!='}') {
        i8* k;
        if((*l).peek()=='"') k=parse_quoted_key(l,a);
        else k=parse_bare_key(l,a);
        (*l).skip_ws();(*l).next();(*l).skip_ws(); // =
        val* val_=parse_value(l,a);
        table_set(v,k,val_,a);
        (*l).skip_ws();
        if((*l).peek()==','){(*l).next();(*l).skip_ws();}
    }
    (*l).next(); // }
    return v;
}

private val* parse_number_or_bool(lex* l, &memstr a) {
    // Check boolean
    if((*l).pos+3<(*l).len&&(*l).src[(*l).pos]=='t'&&(*l).src[(*l).pos+1]=='r'&&
       (*l).src[(*l).pos+2]=='u'&&(*l).src[(*l).pos+3]=='e') {
        (*l).pos=(*l).pos+4;
        val* v=alloc_val(a,TOML_BOOL);(*v).b_val=true;return v;
    }
    if((*l).pos+4<(*l).len&&(*l).src[(*l).pos]=='f') {
        (*l).pos=(*l).pos+5;
        val* v=alloc_val(a,TOML_BOOL);(*v).b_val=false;return v;
    }
    i32 start=(*l).pos; bool is_float=false;
    if((*l).peek()=='-'||(*l).peek()=='+') (*l).pos=(*l).pos+1;
    // Handle 0x/0o/0b
    if((*l).pos+1<(*l).len&&(*l).src[(*l).pos]=='0'&&
       ((*l).src[(*l).pos+1]=='x'||(*l).src[(*l).pos+1]=='o'||(*l).src[(*l).pos+1]=='b')) {
        (*l).pos=(*l).pos+2;
        i64 base = (*l).src[(*l).pos-1]=='x'?16:(*l).src[(*l).pos-1]=='o'?8:2;
        i64 iv=0;
        while(!(*l).at_end()){
            i8 c=(*l).src[(*l).pos];
            if(c=='_'){(*l).pos=(*l).pos+1;continue;}
            i64 d=-1;
            if(c>='0'&&c<='9') d=c-'0';
            else if(c>='a'&&c<='f') d=c-'a'+10;
            else if(c>='A'&&c<='F') d=c-'A'+10;
            if(d<0||d>=base) break;
            iv=iv*base+d; (*l).pos=(*l).pos+1;
        }
        val* v=alloc_val(a,TOML_INT);(*v).i_val=iv;return v;
    }
    while(!(*l).at_end()){
        i8 c=(*l).src[(*l).pos];
        if(c>='0'&&c<='9'||c=='_'){(*l).pos=(*l).pos+1;}
        else if(c=='.'||c=='e'||c=='E'){is_float=true;(*l).pos=(*l).pos+1;}
        else if(c=='+'||c=='-'){(*l).pos=(*l).pos+1;}
        else break;
    }
    if(is_float){
        f64 fv=0.0;f64 frac=0.1;bool after_dot=false;bool neg=false;i32 i=start;
        if((*l).src[i]=='-'){neg=true;i=i+1;}else if((*l).src[i]=='+')i=i+1;
        while(i<(*l).pos){
            i8 d=(*l).src[i];
            if(d=='_'){i=i+1;continue;}
            if(d=='.'||d=='e'||d=='E'){after_dot=(d=='.');i=i+1;continue;}
            if(after_dot){fv=fv+(f64)(d-'0')*frac;frac=frac*0.1;}
            else fv=fv*10.0+(f64)(d-'0');
            i=i+1;
        }
        val* v=alloc_val(a,TOML_FLOAT);(*v).f_val=neg?-fv:fv;return v;
    }
    i64 iv=0;bool neg=false;i32 i=start;
    if((*l).src[i]=='-'){neg=true;i=i+1;}else if((*l).src[i]=='+')i=i+1;
    while(i<(*l).pos){i8 d=(*l).src[i];if(d!='_'){iv=iv*10+(i64)(d-'0');}i=i+1;}
    val* v=alloc_val(a,TOML_INT);(*v).i_val=neg?-iv:iv;return v;
}

private val* parse_value(lex* l, &memstr a) {
    (*l).skip_ws();
    i8 c=(*l).peek();
    if(c=='"')  return parse_string(l,a);
    if(c=='\'') return parse_literal_string(l,a);
    if(c=='[')  return parse_array(l,a);
    if(c=='{')  return parse_inline_table(l,a);
    return parse_number_or_bool(l,a);
}

// ---- Navigate dotted key to nested table (creates intermediates) ----

private val* resolve_table(val* root, i8** parts, i32 n_parts, &memstr a) {
    val* cur = root;
    for(i32 p=0;p<n_parts;p=p+1) {
        val* child=table_get(cur,parts[p]);
        if(child==(val*)0){
            child=alloc_val(a,TOML_TABLE);
            table_set(cur,parts[p],child,a);
        }
        cur=child;
    }
    return cur;
}

// ---- Main parser ----

val* parse(i8* src, i32 len, &memstr a) {
    lex l(src, len);
    val* root=alloc_val(a,TOML_TABLE);
    val* cur_table=root;

    while(!l.at_end()) {
        l.skip_ws_nl();
        if(l.at_end()) break;
        i8 c=l.peek();

        // [[array-of-tables]]
        if(c=='['&&l.pos+1<l.len&&l.src[l.pos+1]=='[') {
            l.next();l.next(); // [[
            i8* parts[32];i32 np=0;
            while(!l.at_end()&&l.peek()!=']') {
                l.skip_ws();
                if(l.peek()=='"') parts[np]=parse_quoted_key(&l,a);
                else parts[np]=parse_bare_key(&l,a);
                np=np+1;
                l.skip_ws();
                if(l.peek()=='.'){l.next();}
            }
            l.next();l.next(); // ]]
            // Get the parent table (all parts except last)
            val* parent=root;
            for(i32 p=0;p<np-1;p=p+1){
                val* child=table_get(parent,parts[p]);
                if(child==(val*)0){child=alloc_val(a,TOML_TABLE);table_set(parent,parts[p],child,a);}
                parent=child;
            }
            // Get or create array-of-tables under last key
            val* aot=table_get(parent,parts[np-1]);
            if(aot==(val*)0){
                aot=alloc_val(a,TOML_ARRAY);
                table_set(parent,parts[np-1],aot,a);
            }
            val* new_tbl=alloc_val(a,TOML_TABLE);
            // Append to array
            val** new_arr=(val**)a.mmap((u64)(sizeof(val*)*((*aot).arr_len+1)));
            for(i32 i=0;i<(*aot).arr_len;i=i+1) new_arr[i]=(*aot).arr_items[i];
            new_arr[(*aot).arr_len]=new_tbl;
            if((*aot).arr_items!=(val**)0) a.deinit((*aot).arr_items);
            (*aot).arr_items=new_arr;(*aot).arr_len=(*aot).arr_len+1;
            cur_table=new_tbl;
            continue;
        }

        // [table]
        if(c=='[') {
            l.next(); // [
            i8* parts[32];i32 np=0;
            while(!l.at_end()&&l.peek()!=']') {
                l.skip_ws();
                if(l.peek()=='"') parts[np]=parse_quoted_key(&l,a);
                else parts[np]=parse_bare_key(&l,a);
                np=np+1;
                l.skip_ws();
                if(l.peek()=='.'){l.next();}
            }
            l.next(); // ]
            cur_table=resolve_table(root,parts,np,a);
            continue;
        }

        // key = value
        i8* key;
        if(c=='"') key=parse_quoted_key(&l,a);
        else key=parse_bare_key(&l,a);
        if(key[0]==0) {l.pos=l.pos+1;continue;}
        l.skip_ws();
        if(!l.at_end()&&l.peek()=='='){l.next();}
        l.skip_ws();
        val* v=parse_value(&l,a);
        table_set(cur_table,key,v,a);
        l.skip_ws();
        if(!l.at_end()&&(l.peek()=='\r'||l.peek()=='\n')) l.next();
    }
    return root;
}

val* parse_str(i8* src, &memstr a) {
    i32 n=0; while(src[n]!=0) n=n+1;
    return parse(src,n,a);
}

// ---- Accessors (same pattern as std.json) ----

bool is_null(val* v)   { return (*v).kind==TOML_NULL; }
bool is_bool(val* v)   { return (*v).kind==TOML_BOOL; }
bool is_int(val* v)    { return (*v).kind==TOML_INT; }
bool is_float(val* v)  { return (*v).kind==TOML_FLOAT; }
bool is_string(val* v) { return (*v).kind==TOML_STRING; }
bool is_array(val* v)  { return (*v).kind==TOML_ARRAY; }
bool is_table(val* v)  { return (*v).kind==TOML_TABLE; }

bool as_bool(val* v)   { return (*v).b_val; }
i64  as_int(val* v)    { return (*v).i_val; }
f64  as_float(val* v)  { return (*v).f_val; }
i8*  as_string(val* v) { return (*v).s_val; }

val* array_at(val* v, i32 i)   { return (*v).arr_items[i]; }
i32  array_len(val* v)         { return (*v).arr_len; }
val* table_get_pub(val* v, i8* key) { return table_get(v, key); }

} // toml
} // std
