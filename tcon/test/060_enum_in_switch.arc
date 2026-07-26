enum Dir { North, South, East, West }

fn opposite(d: i32) i32 {
    switch (d) {
        case North: return South;
        case South: return North;
        case East:  return West;
        case West:  return East;
        default:    return -1;
    }
}

pub fn main() i32 {
    if (opposite(North) != South) { return 1; }
    if (opposite(East)  != West)  { return 2; }
    if (opposite(South) != North) { return 3; }
    return 0;
}
