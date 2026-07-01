// std.debug — Panic handler, stack trace, DWARF symbol parsing, and assertion helpers.
// On POSIX: uses backtrace()/backtrace_symbols() from execinfo.h.
// On Windows: uses CaptureStackBackTrace + SymFromAddr from DbgHelp.
// DWARF parsing provides source-level information from .debug_info/.debug_line.

namespace std {
namespace debug {

// ---- Platform declarations ----

@ifdef _WIN32
extern void*  GetCurrentProcess();
extern i32    SymInitialize(void* proc, i8* path, i32 invade);
extern i32    SymFromAddr(void* proc, u64 addr, u64* disp, void* sym);
extern u16    CaptureStackBackTrace(u32 frames_to_skip, u32 frames_to_capture,
                                    void** backtrace, u32* hash);
@else
extern i32    backtrace(void** buf, i32 size);
extern i8**   backtrace_symbols(void** buf, i32 n);
extern void   free(void* p);
extern i32    dladdr(void* addr, void* info);  // Dl_info equivalent via raw ptr
@endif

extern void*  malloc(u64 n);
extern i32    printf(i8* fmt, ...);
extern i32    fprintf(void* f, i8* fmt, ...);
extern void   abort();
extern void*  stderr_ptr();  // returns FILE* stderr

// ---- Stack trace ----

constexpr i32 MAX_FRAMES = 64;

istruc frame {
    void* addr;
    i8*   symbol;   // null if unavailable
    u64   offset;
}

istruc stack_trace {
    frame  frames[64];
    i32    depth;

    void capture(&self, i32 skip) {
        void* addrs[64];
        self.depth = 0;
@ifdef _WIN32
        u32 hash = 0;
        u16 n = CaptureStackBackTrace((u32)(skip+1), (u32)MAX_FRAMES, addrs, &hash);
        self.depth = (i32)n;
        void* proc = GetCurrentProcess();
        SymInitialize(proc, (i8*)0, 1);
        // SYMBOL_INFO is 88 bytes + name
        u8 sym_buf[512];
        void* sym = (void*)sym_buf;
        // lay sym->MaxNameLen = 255, sym->SizeOfStruct = 88 via raw writes
        u32* si = (u32*)sym_buf;
        si[0] = 88u;       // SizeOfStruct at offset 0
        si[21] = 255u;     // MaxNameLen at offset 84 (= 21*4)
        for(i32 i=0;i<self.depth;i=i+1) {
            self.frames[i].addr   = addrs[i];
            self.frames[i].symbol = (i8*)0;
            self.frames[i].offset = 0;
            u64 disp = 0;
            if(SymFromAddr(proc, (u64)(void*)addrs[i], &disp, sym)) {
                // Name starts at offset 88 in the struct
                self.frames[i].symbol = (i8*)(sym_buf + 88);
                self.frames[i].offset = disp;
            }
        }
@else
        void* buf[64];
        i32 n = backtrace(buf, MAX_FRAMES);
        if(skip+1 < n) n = n; else { self.depth=0; return; }
        self.depth = n - (skip+1);
        i8** syms = backtrace_symbols(buf + skip + 1, self.depth);
        for(i32 i=0;i<self.depth;i=i+1) {
            self.frames[i].addr   = buf[skip+1+i];
            self.frames[i].symbol = syms!=0 ? syms[i] : (i8*)0;
            self.frames[i].offset = 0;
        }
        if(syms!=(i8**)0) { free(syms); }
@endif
    }

    void print(&self) {
        printf("Stack trace (%d frames):\n", self.depth);
        for(i32 i=0;i<self.depth;i=i+1) {
            if(self.frames[i].symbol != (i8*)0)
                printf("  #%d  %p  %s+%llu\n", i, self.frames[i].addr,
                       self.frames[i].symbol, self.frames[i].offset);
            else
                printf("  #%d  %p  (unknown)\n", i, self.frames[i].addr);
        }
    }
}

// ---- Panic handler ----

stack_trace g_panic_trace;

void panic(i8* msg) {
    printf("\nPANIC: %s\n", msg);
    g_panic_trace.capture(1);
    g_panic_trace.print();
    abort();
}

void panic_fmt(i8* fmt, i32 val) {
    printf("\nPANIC: ");
    printf(fmt, val);
    printf("\n");
    g_panic_trace.capture(1);
    g_panic_trace.print();
    abort();
}

// ---- Bounds-check helpers ----

void bounds_check(i32 idx, i32 len, i8* context) {
    if(idx < 0 || idx >= len) {
        printf("\nPANIC: bounds check failed in %s: index %d out of bounds [0,%d)\n",
               context, idx, len);
        g_panic_trace.capture(1);
        g_panic_trace.print();
        abort();
    }
}

void null_check(void* p, i8* context) {
    if(p == (void*)0) {
        printf("\nPANIC: null pointer dereference in %s\n", context);
        g_panic_trace.capture(1);
        g_panic_trace.print();
        abort();
    }
}

// ---- DWARF minimal reader ----
// Provides source file + line number resolution from .debug_line section.
// This is a simplified reader that handles DWARFv4 line programs.

istruc dwarf_line_entry {
    u64  address;
    u32  line;
    u32  col;
    i32  file_idx;
}

constexpr i32 MAX_LINE_ENTRIES = 8192;
constexpr i32 MAX_SOURCE_FILES = 256;

istruc dwarf_reader {
    dwarf_line_entry entries[8192];
    i32              entry_count;
    i8*              files[256];
    i32              file_count;

    void __construct__(&self) { self.entry_count=0; self.file_count=0; }

    // Load from in-memory .debug_line section bytes (DWARFv4).
    void load_line_section(&self, u8* data, u64 len) {
        u64 pos = 0;
        while(pos + 4 < len) {
            u32 unit_len = (u32)data[pos]|((u32)data[pos+1]<<8)|
                           ((u32)data[pos+2]<<16)|((u32)data[pos+3]<<24);
            if(unit_len == 0 || unit_len > len - pos - 4) break;
            u64 unit_end = pos + 4 + (u64)unit_len;
            pos = pos + 4;
            u16 version = (u16)data[pos]|((u16)data[pos+1]<<8); pos=pos+2;
            u32 hdr_len = (u32)data[pos]|((u32)data[pos+1]<<8)|
                          ((u32)data[pos+2]<<16)|((u32)data[pos+3]<<24); pos=pos+4;
            u64 prog_start = pos + (u64)hdr_len;
            // minimum_instruction_length
            u8 min_il = data[pos]; pos=pos+1;
            if(version >= 4) pos=pos+1; // max_ops_per_insn
            u8 default_is_stmt = data[pos]; pos=pos+1;
            u8 line_base_u = data[pos]; pos=pos+1;
            i8 line_base   = (i8)line_base_u;
            u8 line_range  = data[pos]; pos=pos+1;
            u8 opcode_base = data[pos]; pos=pos+1;
            // skip standard opcode lengths
            for(i32 i=1;i<(i32)opcode_base;i=i+1) pos=pos+1;
            // include dirs (null-terminated strings)
            while(pos < unit_end && data[pos] != 0) {
                while(pos < unit_end && data[pos] != 0) pos=pos+1;
                pos=pos+1;
            }
            pos=pos+1; // terminating null
            // file names
            while(pos < unit_end && data[pos] != 0) {
                i32 start_=(i32)pos;
                while(pos < unit_end && data[pos] != 0) pos=pos+1;
                i32 n=(i32)pos-start_;
                if(self.file_count < MAX_SOURCE_FILES) {
                    i8* fn=(i8*)malloc((u64)(n+1));
                    for(i32 i=0;i<n;i=i+1) fn[i]=(i8)data[start_+i];
                    fn[n]=0; self.files[self.file_count]=fn; self.file_count=self.file_count+1;
                }
                pos=pos+1;
                // dir index + mtime + size as ULEB128
                while(pos<unit_end&&(data[pos]&0x80)) pos=pos+1; pos=pos+1;
                while(pos<unit_end&&(data[pos]&0x80)) pos=pos+1; pos=pos+1;
                while(pos<unit_end&&(data[pos]&0x80)) pos=pos+1; pos=pos+1;
            }
            pos=pos+1;
            pos=prog_start;
            // Execute line number program
            u64 addr=0; u32 line_=1; i32 file_=1;
            while(pos < unit_end) {
                u8 op = data[pos]; pos=pos+1;
                if(op == 0) {
                    // extended opcode
                    u64 ext_len=0; i32 shift=0;
                    while((data[pos]&0x80)){ext_len|=(u64)(data[pos]&0x7F)<<shift;pos=pos+1;shift=shift+7;}
                    ext_len|=(u64)data[pos]<<shift; pos=pos+1;
                    u8 eop=data[pos]; pos=pos+1;
                    if(eop==1){ // DW_LNE_end_sequence
                        pos=pos+(u64)ext_len-1;
                    } else if(eop==2){ // DW_LNE_set_address (8 bytes)
                        addr=*(u64*)(void*)(data+pos); pos=pos+8;
                    } else { pos=pos+(u64)ext_len-1; }
                } else if(op < opcode_base) {
                    // standard opcodes
                    if(op==1){
                        // DW_LNS_copy — emit row
                        if(self.entry_count < MAX_LINE_ENTRIES) {
                            self.entries[self.entry_count].address=(u64)addr;
                            self.entries[self.entry_count].line=line_;
                            self.entries[self.entry_count].col=0;
                            self.entries[self.entry_count].file_idx=file_-1;
                            self.entry_count=self.entry_count+1;
                        }
                    } else if(op==2){ // DW_LNS_advance_pc
                        u64 adv=0;i32 s=0;
                        while(data[pos]&0x80){adv|=(u64)(data[pos]&0x7F)<<s;pos=pos+1;s=s+7;}
                        adv|=(u64)data[pos]<<s;pos=pos+1;
                        addr=addr+adv*(u64)min_il;
                    } else if(op==3){ // DW_LNS_advance_line
                        i64 adv=0;i32 s=0;
                        while(data[pos]&0x80){adv|=(i64)(data[pos]&0x7F)<<s;pos=pos+1;s=s+7;}
                        adv|=(i64)data[pos]<<s;pos=pos+1;
                        line_=(u32)((i64)line_+adv);
                    } else if(op==4){ // DW_LNS_set_file
                        u64 fv=0;i32 s=0;
                        while(data[pos]&0x80){fv|=(u64)(data[pos]&0x7F)<<s;pos=pos+1;s=s+7;}
                        fv|=(u64)data[pos]<<s;pos=pos+1;
                        file_=(i32)fv;
                    } else {
                        // skip (consume ULEB128 args per standard opcode table)
                        pos=pos+1;
                    }
                } else {
                    // special opcode
                    u32 adj = (u32)op - (u32)opcode_base;
                    addr = addr + (u64)((adj / (u32)line_range) * (u32)min_il);
                    line_ = (u32)((i32)line_ + (i32)line_base + (i32)(adj % (u32)line_range));
                    // emit row
                    if(self.entry_count < MAX_LINE_ENTRIES) {
                        self.entries[self.entry_count].address=(u64)addr;
                        self.entries[self.entry_count].line=line_;
                        self.entries[self.entry_count].col=0;
                        self.entries[self.entry_count].file_idx=file_-1;
                        self.entry_count=self.entry_count+1;
                    }
                }
            }
            pos = unit_end;
        }
    }

    // Binary search for the entry with the largest address <= target.
    dwarf_line_entry* find(&self, u64 target_addr) {
        i32 lo=0; i32 hi=self.entry_count-1; i32 best=-1;
        while(lo<=hi) {
            i32 mid=(lo+hi)/2;
            if(self.entries[mid].address<=target_addr){best=mid;lo=mid+1;}
            else hi=mid-1;
        }
        if(best<0) return (dwarf_line_entry*)0;
        return self.entries+best;
    }

    i8* file_name(&self, i32 idx) {
        if(idx<0||idx>=self.file_count) return (i8*)"?";
        return self.files[idx];
    }

    void resolve_and_print(&self, u64 addr) {
        dwarf_line_entry* e = self.find(addr);
        if(e == (dwarf_line_entry*)0) { printf("  ??? at %p\n", (void*)addr); return; }
        printf("  %p  %s:%u\n", (void*)addr, self.file_name((*e).file_idx), (*e).line);
    }
}

// ---- Memory poison helpers (debug only) ----

// Fill memory with 0xDEADBEEF pattern to catch use-after-free.
void poison(void* p, u64 n) {
    u8* b = (u8*)p;
    for(u64 i=0;i<n;i=i+1) b[i] = (u8)(0xDE ^ (u8)(i & 0xFF));
}

// Check whether a block looks poisoned (heuristic).
bool is_poisoned(void* p, u64 n) {
    u8* b = (u8*)p;
    i32 hits=0;
    for(u64 i=0;i<n;i=i+1) {
        if(b[i]==(u8)(0xDE^(u8)(i&0xFF))) hits=hits+1;
    }
    return hits > (i32)(n/2);
}

// ---- Debug assert (no-op in release builds) ----

void assert(bool cond, i8* msg) {
@ifdef DEBUG
    if(!cond) { panic(msg); }
@endif
}

// ---- Breakpoint ----

void breakpoint() {
@ifdef _WIN32
    __asm { int 3 }
@else
    __asm("int $3");
@endif
}

} // debug
} // std
