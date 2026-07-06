// PASS: typedef auto creates a type alias that works like the underlying type.

typedef auto Meter = i32;
typedef auto Speed = i32;

Speed velocity(Meter dist, i32 time) {
    return dist / time;
}

i32 main() {
    Meter d = 100;
    Speed v = velocity(d, 10);
    return v - 10;  // expect 0
}
