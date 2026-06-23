@define <SAFE> <>

@ifdef SAFE
i32 ok() { return 0; }
@else
@error <This branch must never be reached>
@endif

i32 main() {
    return ok();
}
