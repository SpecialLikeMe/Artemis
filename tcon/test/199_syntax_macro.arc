const_resolve create {
    () => {},
    ($val:expr) => {
        auto x = $val;
    },
    ["let", $name:ident, $eq("=", $val:expr)?] => {
        auto $name = $eq?;
    }
}

int main() {
    create(4+1);
    let y = 4-4;
    return y;
}
