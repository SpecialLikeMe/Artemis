struct Stack {
    i32 data[16];
    i32 top;
}

void stack_init(Stack* s) { s->top = 0; }

void stack_push(Stack* s, i32 v) {
    if (s->top < 16) {
        s->data[s->top] = v;
        s->top = s->top + 1;
    }
}

i32 stack_pop(Stack* s) {
    if (s->top == 0) { return -1; }
    s->top = s->top - 1;
    return s->data[s->top];
}

i32 stack_size(Stack* s) { return s->top; }

typedef i32 Result;

enum OpCode { Push = 0, Pop = 1 }

Result run(i32 ops) {
    Stack s;
    stack_init(&s);

    for (i32 i = 1; i <= ops; i++) {
        stack_push(&s, i * i);
    }

    i32 sum = 0;
    while (stack_size(&s) > 0) {
        sum = sum + stack_pop(&s);
    }
    return sum;
}

i32 main() {
    if (run(0) != 0)    { return 1; }
    if (run(1) != 1)    { return 2; }
    if (run(3) != 14)   { return 3; }
    if (run(5) != 55)   { return 4; }

    if (Push != 0) { return 5; }
    if (Pop  != 1) { return 6; }
    return 0;
}
