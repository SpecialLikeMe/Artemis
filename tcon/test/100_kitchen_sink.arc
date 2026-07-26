struct Stack {
    let data: [16]i32;
    let top: i32;
}

fn stack_init(s: *Stack) void { (*s).top = 0; }

fn stack_push(s: *Stack, v: i32) void {
    if ((*s).top < 16) {
        (*s).data[(*s).top] = v;
        (*s).top = (*s).top + 1;
    }
}

fn stack_pop(s: *Stack) i32 {
    if ((*s).top == 0) { return -1; }
    (*s).top = (*s).top - 1;
    return (*s).data[(*s).top];
}

fn stack_size(s: *Stack) i32 { return (*s).top; }

using Result = i32;

enum OpCode { Push = 0, Pop = 1 }

fn run(ops: i32) Result {
    let mut s: Stack;
    stack_init(&s);

    for (let mut i: i32 = 1; i <= ops; i++) {
        stack_push(&s, i * i);
    }

    let mut sum: i32= 0;
    while (stack_size(&s) > 0) {
        sum = sum + stack_pop(&s);
    }
    return sum;
}

pub fn main() i32 {
    if (run(0) != 0)    { return 1; }
    if (run(1) != 1)    { return 2; }
    if (run(3) != 14)   { return 3; }
    if (run(5) != 55)   { return 4; }

    if (Push != 0) { return 5; }
    if (Pop  != 1) { return 6; }
    return 0;
}
