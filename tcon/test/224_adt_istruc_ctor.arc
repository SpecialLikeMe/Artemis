// 224: ADT enum istruc variant with user-defined __construct__ via x.variant() call
extern i32 strcmp(const i8* a, const i8* b);

enum msg {
    empty,
    text .{
        char* rc;
        void __construct__(msg.text* self, char* a) {
            self.rc = a;
        }
    },
}

i32 main() {
    msg bar = msg.text("Hello world");
    char* s = (*bar).rc;
    if (strcmp(s, "Hello world") != 0) { return 1; }
    return 0;
}
