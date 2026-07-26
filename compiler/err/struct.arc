const field = struct {
    let fname: []const u8;
    let ftype: type;
};

const strerr = struct {
    let text: []const u8;
    let lines: [_]const u64;
    let eline: i32;
    let name: []const u8;
    let fields: []field;
};

fn generate_err_message(err: sterr) !?[]const u8 {
    
}

fn main() int {
    return 0;
}