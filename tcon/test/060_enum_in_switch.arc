enum Dir { North, South, East, West }

i32 opposite(i32 d) {
    switch (d) {
        case North: return South;
        case South: return North;
        case East:  return West;
        case West:  return East;
        default:    return -1;
    }
}

i32 main() {
    if (opposite(North) != South) { return 1; }
    if (opposite(East)  != West)  { return 2; }
    if (opposite(South) != North) { return 3; }
    return 0;
}
