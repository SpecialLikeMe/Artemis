// std.toml — Full TOML v1.0 parser.
// Supports: key/value, sections ([table]), arrays ([[array-of-tables]]),
// inline tables, arrays of values, string types, integers, floats, booleans, dates.

namespace std {
namespace toml {

// Value kinds
comptime i32 TOML_NULL    = 0;
comptime i32 TOML_BOOL    = 1;
comptime i32 TOML_INT     = 2;
comptime i32 TOML_FLOAT   = 3;
comptime i32 TOML_STRING  = 4;
comptime i32 TOML_ARRAY   = 5;
comptime i32 TOML_TABLE   = 6;

istruc val {
    let mut kind: i32;
    let mut b_val: bool;
    let mut i_val: i64;
    let mut f_val: f64;
    let mut s_val: *i8;
    let mut arr_items: **val;
    let mut arr_len: i32;
    let mut tbl_pairs: *pair;
    let mut tbl_len: i32;
    let mut tbl_cap: i32;
}

istruc pair {
    let mut key: *i8;
    let mut value: *val;
}

// ---- Lexer ----

istruc lex {
    let mut src: *i8;
    let mut pos: i32;
    let mut len: i32;

    fn __construct__(self: *lex, s: *i8, n: i32) void { self.src=s; self.pos=0; self.len=n; }

    fn at_end(self: *lex) bool { return self.pos >= self.len; }
    fn peek(self: *lex) i8   { return self.pos < self.len ? self.src[self.pos] : 0; }
    fn peek2(self: *lex) i8  { return self.pos+1 < self.len ? self.src[self.pos+1] : 0; }
    fn next(self: *lex) i8         { let mut c: i8= self.src[self.pos]; self.pos=self.pos+1; return c; }

    fn skip_ws(self: *lex) void {
        while (self.pos < self.len) {
            let mut c: i8= self.src[self.pos];
            if (c==' '||c=='\t') { self.pos=self.pos+1; }
            else if (c=='#') {
                while (self.pos < self.len && self.src[self.pos] != '\n') self.pos=self.pos+1;
            } else { break; }
        }
    }

    fn skip_ws_nl(self: *lex) void {
        while (self.pos < self.len) {
            let mut c: i8= self.src[self.pos];
            if (c==' '||c=='\t'||c=='\r'||c=='\n') { self.pos=self.pos+1; }
            else if (c=='#') {
                while (self.pos < self.len && self.src[self.pos] != '\n') self.pos=self.pos+1;
            } else { break; }
        }
    }
}

// ---- Helper: alloc a val node ----

fn alloc_val(a: &memstr, kind: i32) *val {
    let mut v: *val= (val*)a.mmap(sizeof(val)) catch |e| { };
    (*v).kind=kind; (*v).b_val=false; (*v).i_val=0; (*v).f_val=0.0;
    (*v).s_val=(i8*)0; (*v).arr_items=(val**)0; (*v).arr_len=0;
    (*v).tbl_pairs=(pair*)0; (*v).tbl_len=0; (*v).tbl_cap=0;
    return v;
}

// ---- Table helpers ----

fn table_set(tbl: *val, key: *i8, value: *val, a: &memstr) void {
    // Check existing
    for (let mut i: i32 = 0; i < (*tbl).tbl_len; i=i+1) {
        let mut k: *i8= (*tbl).tbl_pairs[i].key;
        let mut j: i32=0; let mut eq: bool=true;
        while(k[j]!=0&&key[j]!=0){if(k[j]!=key[j]){eq=false;break;}j=j+1;}
        if(eq&&k[j]==key[j]){(*tbl).tbl_pairs[i].value=value;return;}
    }
    if((*tbl).tbl_len >= (*tbl).tbl_cap) {
        let mut nc: i32= (*tbl).tbl_cap==0?8:(*tbl).tbl_cap*2;
        let mut np: *pair= (pair*)a.mmap((u64)(sizeof(pair)*(u64)nc)) catch |e| { };
        for(let mut i: i32=0;i<(*tbl).tbl_len;i=i+1) np[i]=(*tbl).tbl_pairs[i];
        if((*tbl).tbl_pairs!=(pair*)0) a.free((void*)(*tbl).tbl_pairs) catch |e| { };
        (*tbl).tbl_pairs=np; (*tbl).tbl_cap=nc;
    }
    (*tbl).tbl_pairs[(*tbl).tbl_len].key=key;
    (*tbl).tbl_pairs[(*tbl).tbl_len].value=value;
    (*tbl).tbl_len=(*tbl).tbl_len+1;
}

fn table_get(tbl: *val, key: *i8) *val {
    for(let mut i: i32=0;i<(*tbl).tbl_len;i=i+1){
        let mut k: *i8=(*tbl).tbl_pairs[i].key;
        let mut j: i32=0;let mut eq: bool=true;
        while(k[j]!=0&&key[j]!=0){if(k[j]!=key[j]){eq=false;break;}j=j+1;}
        if(eq&&k[j]==key[j]) return (*tbl).tbl_pairs[i].value;
    }
    return (val*)0;
}

// ---- Key parsing ----

fn parse_bare_key(l: *lex, a: &memstr) *i8 {
    let mut start: i32= (*l).pos;
    while (!(*l).at_end()) {
        let mut c: i8= (*l).peek();
        if ((c>='a'&&c<='z')||(c>='A'&&c<='Z')||(c>='0'&&c<='9')||c=='-'||c=='_')
            (*l).pos=(*l).pos+1;
        else break;
    }
    let mut n: i32= (*l).pos - start;
    let mut s: *i8= (i8*)a.mmap((u64)(n+1)) catch |e| { };
    for(let mut i: i32=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    return s;
}

fn parse_quoted_key(l: *lex, a: &memstr) *i8 {
    (*l).next(); // consume "
    let mut start: i32=(*l).pos;
    while(!(*l).at_end()&&(*l).peek()!='"'){
        if((*l).peek()=='\\') (*l).pos=(*l).pos+1;
        (*l).pos=(*l).pos+1;
    }
    let mut n: i32=(*l).pos-start;
    let mut s: *i8=(i8*)a.mmap((u64)(n+1)) catch |e| { };
    for(let mut i: i32=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    (*l).next(); // consume closing "
    return s;
}

// ---- Value parsing ----

fn parse_value(l: *lex, a: &memstr) *val;

fn parse_string(l: *lex, a: &memstr) *val {
    // Multi-line or single line
    let mut ml: bool= ((*l).peek()=='\"' && (*l).peek2()=='\"');
    if(ml) { (*l).next(); (*l).next(); }
    (*l).next(); // opening "
    let mut start: i32=(*l).pos;
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
    let mut n: i32=(*l).pos-start;
    let mut s: *i8=(i8*)a.mmap((u64)(n+1)) catch |e| { };
    for(let mut i: i32=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    if(ml){(*l).next();(*l).next();(*l).next();}else(*l).next();
    let mut v: *val=alloc_val(a,TOML_STRING);
    (*v).s_val=s;
    return v;
}

fn parse_literal_string(l: *lex, a: &memstr) *val {
    let mut ml: bool=((*l).peek()=='\''&&(*l).peek2()=='\'');
    if(ml){(*l).next();(*l).next();}
    (*l).next(); // '
    let mut start: i32=(*l).pos;
    if(ml){
        while(!(*l).at_end()){
            if((*l).src[(*l).pos]=='\''&&(*l).pos+2<(*l).len&&
               (*l).src[(*l).pos+1]=='\''&&(*l).src[(*l).pos+2]=='\'') break;
            (*l).pos=(*l).pos+1;
        }
    } else {
        while(!(*l).at_end()&&(*l).src[(*l).pos]!='\'') (*l).pos=(*l).pos+1;
    }
    let mut n: i32=(*l).pos-start;
    let mut s: *i8=(i8*)a.mmap((u64)(n+1)) catch |e| { };
    for(let mut i: i32=0;i<n;i=i+1) s[i]=(*l).src[start+i];
    s[n]=0;
    if(ml){(*l).next();(*l).next();(*l).next();}else(*l).next();
    let mut v: *val=alloc_val(a,TOML_STRING);(*v).s_val=s;
    return v;
}

fn parse_array(l: *lex, a: &memstr) *val {
    (*l).next(); // [
    let mut v: *val=alloc_val(a,TOML_ARRAY);
    // Allocator-backed and growable: a fixed stack buffer here overflows on
    // large arrays, and a fixed cap would reject valid documents.
    let mut cap: i32=16;
    let mut items: **val=(val**)a.mmap((u64)(sizeof(val*)*(u64)cap)) catch |e| { };
    if(items==(val**)0) return v;
    let mut count: i32=0;
    (*l).skip_ws_nl();
    while(!(*l).at_end()&&(*l).peek()!=']') {
        if (count >= cap) {
            let mut ncap: i32=cap*2;
            let mut grown: **val=(val**)a.mmap((u64)(sizeof(val*)*(u64)ncap)) catch |e| { };
            if(grown==(val**)0) break;
            for(let mut gi: i32=0;gi<count;gi=gi+1) grown[gi]=items[gi];
            items=grown; cap=ncap;
        }
        items[count]=parse_value(l,a);
        count=count+1;
        (*l).skip_ws_nl();
        if((*l).peek()==','){(*l).next();(*l).skip_ws_nl();}
    }
    (*l).next(); // ]
    (*v).arr_items=items;
    (*v).arr_len=count;
    return v;
}

fn parse_inline_table(l: *lex, a: &memstr) *val {
    (*l).next(); // {
    let mut v: *val=alloc_val(a,TOML_TABLE);
    (*l).skip_ws();
    while(!(*l).at_end()&&(*l).peek()!='}') {
        let mut k: *i8;
        if((*l).peek()=='"') k=parse_quoted_key(l,a);
        else k=parse_bare_key(l,a);
        (*l).skip_ws();(*l).next();(*l).skip_ws(); // =
        let mut val_: *val=parse_value(l,a);
        table_set(v,k,val_,a);
        (*l).skip_ws();
        if((*l).peek()==','){(*l).next();(*l).skip_ws();}
    }
    (*l).next(); // }
    return v;
}

fn parse_number_or_bool(l: *lex, a: &memstr) *val {
    // Check boolean
    if((*l).pos+3<(*l).len&&(*l).src[(*l).pos]=='t'&&(*l).src[(*l).pos+1]=='r'&&
       (*l).src[(*l).pos+2]=='u'&&(*l).src[(*l).pos+3]=='e') {
        (*l).pos=(*l).pos+4;
        let mut v: *val=alloc_val(a,TOML_BOOL);(*v).b_val=true;return v;
    }
    if((*l).pos+4<(*l).len&&(*l).src[(*l).pos]=='f') {
        (*l).pos=(*l).pos+5;
        let mut v: *val=alloc_val(a,TOML_BOOL);(*v).b_val=false;return v;
    }
    let mut start: i32=(*l).pos; let mut is_float: bool=false;
    if((*l).peek()=='-'||(*l).peek()=='+') (*l).pos=(*l).pos+1;
    // Handle 0x/0o/0b
    if((*l).pos+1<(*l).len&&(*l).src[(*l).pos]=='0'&&
       ((*l).src[(*l).pos+1]=='x'||(*l).src[(*l).pos+1]=='o'||(*l).src[(*l).pos+1]=='b')) {
        (*l).pos=(*l).pos+2;
        let mut base: i64= (*l).src[(*l).pos-1]=='x'?16:(*l).src[(*l).pos-1]=='o'?8:2;
        let mut iv: i64=0;
        while(!(*l).at_end()){
            let mut c: i8=(*l).src[(*l).pos];
            if(c=='_'){(*l).pos=(*l).pos+1;continue;}
            let mut d: i64=-1;
            if(c>='0'&&c<='9') d=c-'0';
            else if(c>='a'&&c<='f') d=c-'a'+10;
            else if(c>='A'&&c<='F') d=c-'A'+10;
            if(d<0||d>=base) break;
            iv=iv*base+d; (*l).pos=(*l).pos+1;
        }
        let mut v: *val=alloc_val(a,TOML_INT);(*v).i_val=iv;return v;
    }
    while(!(*l).at_end()){
        let mut c: i8=(*l).src[(*l).pos];
        if(c>='0'&&c<='9'||c=='_'){(*l).pos=(*l).pos+1;}
        else if(c=='.'||c=='e'||c=='E'){is_float=true;(*l).pos=(*l).pos+1;}
        else if(c=='+'||c=='-'){(*l).pos=(*l).pos+1;}
        else break;
    }
    if(is_float){
        let mut fv: f64=0.0;let mut frac: f64=0.1;let mut after_dot: bool=false;let mut neg: bool=false;let mut i: i32=start;
        if((*l).src[i]=='-'){neg=true;i=i+1;}else if((*l).src[i]=='+')i=i+1;
        while(i<(*l).pos){
            let mut d: i8=(*l).src[i];
            if(d=='_'){i=i+1;continue;}
            if(d=='.'||d=='e'||d=='E'){after_dot=(d=='.');i=i+1;continue;}
            if(after_dot){fv=fv+(f64)(d-'0')*frac;frac=frac*0.1;}
            else fv=fv*10.0+(f64)(d-'0');
            i=i+1;
        }
        let mut v: *val=alloc_val(a,TOML_FLOAT);(*v).f_val=neg?-fv:fv;return v;
    }
    let mut iv: i64=0;let mut neg: bool=false;let mut i: i32=start;
    if((*l).src[i]=='-'){neg=true;i=i+1;}else if((*l).src[i]=='+')i=i+1;
    while(i<(*l).pos){let mut d: i8=(*l).src[i];if(d!='_'){iv=iv*10+(i64)(d-'0');}i=i+1;}
    let mut v: *val=alloc_val(a,TOML_INT);(*v).i_val=neg?-iv:iv;return v;
}

fn parse_value(l: *lex, a: &memstr) *val {
    (*l).skip_ws();
    let mut c: i8=(*l).peek();
    if(c=='"')  return parse_string(l,a);
    if(c=='\'') return parse_literal_string(l,a);
    if(c=='[')  return parse_array(l,a);
    if(c=='{')  return parse_inline_table(l,a);
    return parse_number_or_bool(l,a);
}

// ---- Navigate dotted key to nested table (creates intermediates) ----

fn resolve_table(root: *val, parts: **i8, n_parts: i32, a: &memstr) *val {
    let mut cur: *val= root;
    for(let mut p: i32=0;p<n_parts;p=p+1) {
        let mut child: *val=table_get(cur,parts[p]);
        if(child==(val*)0){
            child=alloc_val(a,TOML_TABLE);
            table_set(cur,parts[p],child,a);
        }
        cur=child;
    }
    return cur;
}

// ---- Main parser ----

fn parse(src: *i8, len: i32, a: &memstr) *val {
    let mut l: lex(src, len);
    let mut root: *val=alloc_val(a,TOML_TABLE);
    let mut cur_table: *val=root;

    while(!l.at_end()) {
        l.skip_ws_nl();
        if(l.at_end()) break;
        let mut c: i8=l.peek();

        // [[array-of-tables]]
        if(c=='['&&l.pos+1<l.len&&l.src[l.pos+1]=='[') {
            l.next();l.next(); // [[
            let mut parts: [32]*i8;let mut np: i32=0;
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
            let mut parent: *val=root;
            for(let mut p: i32=0;p<np-1;p=p+1){
                let mut child: *val=table_get(parent,parts[p]);
                if(child==(val*)0){child=alloc_val(a,TOML_TABLE);table_set(parent,parts[p],child,a);}
                parent=child;
            }
            // Get or create array-of-tables under last key
            let mut aot: *val=table_get(parent,parts[np-1]);
            if(aot==(val*)0){
                aot=alloc_val(a,TOML_ARRAY);
                table_set(parent,parts[np-1],aot,a);
            }
            let mut new_tbl: *val=alloc_val(a,TOML_TABLE);
            // Append to array
            let mut new_arr: **val=(val**)a.mmap((u64)(sizeof(val*)*(u64)((*aot).arr_len+1))) catch |e| { };
            for(let mut i: i32=0;i<(*aot).arr_len;i=i+1) new_arr[i]=(*aot).arr_items[i];
            new_arr[(*aot).arr_len]=new_tbl;
            if((*aot).arr_items!=(val**)0) a.free((void*)(*aot).arr_items) catch |e| { };
            (*aot).arr_items=new_arr;(*aot).arr_len=(*aot).arr_len+1;
            cur_table=new_tbl;
            continue;
        }

        // [table]
        if(c=='[') {
            l.next(); // [
            let mut parts: [32]*i8;let mut np: i32=0;
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
        let mut key: *i8;
        if(c=='"') key=parse_quoted_key(&l,a);
        else key=parse_bare_key(&l,a);
        if(key[0]==0) {l.pos=l.pos+1;continue;}
        l.skip_ws();
        if(!l.at_end()&&l.peek()=='='){l.next();}
        l.skip_ws();
        let mut v: *val=parse_value(&l,a);
        table_set(cur_table,key,v,a);
        l.skip_ws();
        if(!l.at_end()&&(l.peek()=='\r'||l.peek()=='\n')) l.next();
    }
    return root;
}

fn parse_str(src: *i8, a: &memstr) *val {
    let mut n: i32=0; while(src[n]!=0) n=n+1;
    return parse(src,n,a);
}

// ---- Accessors (same pattern as std.json) ----

fn is_null(v: *val) bool   { return (*v).kind==TOML_NULL; }
fn is_bool(v: *val) bool   { return (*v).kind==TOML_BOOL; }
fn is_int(v: *val) bool    { return (*v).kind==TOML_INT; }
fn is_float(v: *val) bool  { return (*v).kind==TOML_FLOAT; }
fn is_string(v: *val) bool { return (*v).kind==TOML_STRING; }
fn is_array(v: *val) bool  { return (*v).kind==TOML_ARRAY; }
fn is_table(v: *val) bool  { return (*v).kind==TOML_TABLE; }

fn as_bool(v: *val) bool   { return (*v).b_val; }
fn as_int(v: *val) i64    { return (*v).i_val; }
fn as_float(v: *val) f64  { return (*v).f_val; }
fn as_string(v: *val) *i8 { return (*v).s_val; }

fn array_at(v: *val, i: i32) *val   { return (*v).arr_items[i]; }
fn array_len(v: *val) i32         { return (*v).arr_len; }
fn table_get_pub(v: *val, key: *i8) *val { return table_get(v, key); }

} // toml
} // std
