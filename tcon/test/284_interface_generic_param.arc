// PASS: interface with generics in function parameters (interface bar<T>)
interface Getter {
    let mut value: i32;
}
interface Adder<T> {
    let mut addend: T;
}
istruc MyGetter : Getter {
    let mut value: i32 = 10;
}
istruc MyAdder : Adder<i32> {
    let mut addend: i32 = 5;
}
pub fn combine(g: interface Getter, a: interface Adder<i32>) i32 {
    return g.value + a.addend;
}
pub fn main() i32 {
    let mut g: MyGetter();
    let mut a: MyAdder();
    let mut r: i32 = combine(g, a);
    if (r != 15) { return 1; }
    return 0;
}
