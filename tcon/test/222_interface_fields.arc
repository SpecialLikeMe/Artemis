// PASS: interface with field stubs — istruc must provide the field.
interface HasId {
    i32 id;
    i8* name = (i8*)0;  // field with default value (optional)
}

istruc User : HasId {
    i32 id;         // required — no default in interface
    i8* name;       // optional — has interface default but we override anyway
    i32 age;
}

i32 main() {
    User u;
    u.id   = 42;
    u.name = (i8*)0;
    u.age  = 30;
    if (u.id != 42) { return 1; }
    return 0;
}
