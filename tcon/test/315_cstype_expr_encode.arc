// PASS: @cstype(T) in expression position encodes type info as i64.
// Upper 32 bits = kind (0=void,1=int,2=uint,3=float,4=bool,5=ptr,6=struct,7=func_ptr),
// lower 32 bits = bit width.

pub fn main() i32 {
    let c_i32: i64 = @cstype(i32);
    let c_u8:  i64 = @cstype(u8);
    let c_f32: i64 = @cstype(f32);
    let c_ptr: i64 = @cstype(*i32);
    let c_vd:  i64 = @cstype(void);

    // Extract kind (upper 32 bits)
    let k_i32: i64 = c_i32 >> 32;
    let k_u8:  i64 = c_u8  >> 32;
    let k_f32: i64 = c_f32 >> 32;
    let k_ptr: i64 = c_ptr >> 32;
    let k_vd:  i64 = c_vd  >> 32;

    if (k_i32 != 1) { return 1; }  // signed int
    if (k_u8  != 2) { return 2; }  // unsigned int
    if (k_f32 != 3) { return 3; }  // float
    if (k_ptr != 5) { return 4; }  // pointer
    if (k_vd  != 0) { return 5; }  // void

    // Check bit widths (lower 32 bits)
    let w_i32: i64 = c_i32 & 0xffffffff;
    let w_u8:  i64 = c_u8  & 0xffffffff;
    let w_f32: i64 = c_f32 & 0xffffffff;
    let w_ptr: i64 = c_ptr & 0xffffffff;

    if (w_i32 != 32) { return 6; }
    if (w_u8  != 8)  { return 7; }
    if (w_f32 != 32) { return 8; }
    if (w_ptr != 64) { return 9; }

    return 0;
}
