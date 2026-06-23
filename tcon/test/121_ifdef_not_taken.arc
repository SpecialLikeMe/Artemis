@ifdef UNDEFINED_FLAG
i32 bad() { return 1; }
@else
i32 good() { return 0; }
@endif

i32 main() {
    return good();
}
