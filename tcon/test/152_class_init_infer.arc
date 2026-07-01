istruc Vec2 {
    i32 x;
    i32 y;
    i32 sum(&const self) { return self.x + self.y; }
}
i32 main() {
    Vec2 v = .{ .x = 1, .y = 2 };
    if (v.sum() != 3) { return 1; }
    return 0;
}
