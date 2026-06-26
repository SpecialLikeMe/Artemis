-Add method overloading (and subsequently extern "C" blocks) note that compiler should not mangle names unless it knows the method is overloaded. A non overloaded method shouldn't be name mangled.
-Classes - Simmilar class semantics as C++ (including operator overloading), constructor is named __construct__ instead of being the same as the class name, and the destructor is named __destruct__ instead of ~classname. Inheritance is done through ":" as it is in C++, access modifiers (public, private, protected) are done per member like java instead of "<modifier>:". Virtual fields are explicitly declared through the virtual keyword, and are overriden through the override after the ) and before the {, eg. void bark() override {}. Const is also allowed between ) and { with the same affect as C++. Conversion operators are done through "operator T() const {}", with T being the type being converted to. Operator overloads are through syntax type operator<operator>() {} as they are in C++. : in constructor is allowed for constructor init lists. local keyword allows a prototype declaration, exact same as C++ friend keyword. Methods can be static to belong to the class itself. Virtual methods can always have or not have a base implementation, and by default it is optional for a derived class to implement it, unless it is declared with mandatory, eg. public mandatory virtual void x(); then the derived class MUST implement that function. All things deriving a base are automatically virtual unless declared with the final keyword. Class data, vars, etc can also be virtual, with the same syntax as virtual methods (must be of same type, eg. virtual int). A thing overriding Copy/move and associated are implemented through overloaded constructors/destructors. Class default member access is public, and the keyword for a class is "istruc" instead of "class". Instead of a this pointer, you can take &const self (immut) as a param, or &self (mut). Both are implicitly passed like in rust, but must be in func param decl.
-Add function pointers through returntype(params)* x, and func addr of: eg. void(int y)* x = &myfunc
-Allocators (stub currently in place as smem) # Zig style allocators, user provides a vtable (mmap taking a u128 of amt to alloc and returning memory void*, rmap taking a void* of the allocated memory and a signed int of how many bytes to increase/decrease returning memory void*, deinit taking a void* of memory to be deinited and returning void), and provides the allocator, resize, and free respectively and a metadata void ptr like in zig (.vtable and .ptr). The compiler then exposes a type of the same name with a mmap, rmap, and deinit method. Functions which use the heap must explicitly take &memstr <name> as a paramater, and then they use it as their allocator. An allocator can be directly passed, or the caller can not pass it, in which case it default to malloc/realloc/free as the underlying allocator. There should also be a defer keyword to execute code when the scope ends as in zig. Allocation/deallocaton failiures should be handled automatically. A memstruct deinit fn is also automatically exposed as member uinit(). The ptr metadata field is accessible as self.ptr. Note that the vtable field tells the compiler which functions to expose. Here is an example:

extern int printf(char* fmt, ...);

memstr x {
    .ptr = MYPTR;
    .vtable = {
        .mmap = &MYMMAP;
        .rmap = &MYREALLOC;
        .deinit = &MYFREE;
    };
    void* MYMMAP(u128 size) {
        //ALLOC CODE
    }
    void* MYREALLOC(void* self, i128 size) {
        //ALLOC CODE
    }
    void MYFREE(void* self) {
        //FREE CODE
    }
}

int HEAPALLOCATINGFN(&memstr allocator, int idx) {
    int* bytes = (int*)allocator.mmap(idx);
    defer allocator.deinit(bytes);
    defer {
        printf("DEFER");
    }
    bytes = allocator.rmap(bytes, 1024);
    return 0;
}

int main() {
    x allocator;
    defer allocator.uinit();
    HEAPALLOCATINGFN(1024); // Implicit allocator, defaults to malloc/realloc/free
    HEAPALLOCATINGFN(allocator, 1024);
    return 0;
}

-generics
-Proc macros
-keyword def
-ADT enums
-defer
-add fp256 and fp512
-remove extern std

CHECK:
-ASM is standard (maybe)