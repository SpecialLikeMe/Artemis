// Function pointers: multiple function pointer parameters, complex dispatch
i32 add(i32 a, i32 b) { return a + b; }
i32 mul(i32 a, i32 b) { return a * b; }
i32 sub(i32 a, i32 b) { return a - b; }

i32 combine(i32(i32, i32)* op1, i32(i32, i32)* op2, i32 x, i32 y) {
    return op1(x, y) + op2(x, y);
}

i32 apply_twice(i32(i32, i32)* op, i32 x, i32 y) {
    return op(op(x, y), y);
}

i32 select_and_call(i32 sel, i32(i32, i32)* fa, i32(i32, i32)* fb, i32 x, i32 y) {
    i32(i32, i32)* chosen;
    if (sel == 0) { chosen = fa; } else { chosen = fb; }
    return chosen(x, y);
}

i32 main() {
    // add(3,4)+mul(3,4) = 7+12 = 19
    if (combine(&add, &mul, 3, 4) != 19) { return 1; }
    // sub(3,4)+add(3,4) = -1+7 = 6
    if (combine(&sub, &add, 3, 4) != 6)  { return 2; }

    // apply_twice add: add(add(1,2),2) = add(3,2) = 5
    if (apply_twice(&add, 1, 2) != 5)  { return 3; }
    // apply_twice mul: mul(mul(2,3),3) = mul(6,3) = 18
    if (apply_twice(&mul, 2, 3) != 18) { return 4; }

    if (select_and_call(0, &add, &mul, 4, 5) != 9)  { return 5; }
    if (select_and_call(1, &add, &mul, 4, 5) != 20) { return 6; }
    return 0;
}
