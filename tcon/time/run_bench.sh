#!/usr/bin/env bash
# Benchmark harness: Arc run times vs C, Arc compile times vs Go.
#
# Run from the repo root:  ./tcon/time/run_bench.sh
#
# Every benchmark prints a checksum, and the harness refuses to time anything whose
# three implementations disagree — an "optimised" run that computed something else is
# not a faster run.
set -u
cd "$(dirname "$0")"
ROOT=../..
ARC=$ROOT/build/artemis.exe
BENCHES="sieve fib matmul nbody"
REPS=${REPS:-5}
mkdir -p bin

# Median of REPS wall-clock timings, in milliseconds.
timeit() {
    local times=()
    for _ in $(seq 1 "$REPS"); do
        local s=$(date +%s%N)
        "$@" >/dev/null 2>&1
        local e=$(date +%s%N)
        times+=( $(( (e - s) / 1000000 )) )
    done
    printf '%s\n' "${times[@]}" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}'
}

echo "=== build ==="
for b in $BENCHES; do
    (cd $ROOT && build/artemis.exe tcon/time/$b.arc -O2 -o tcon/time/bin/${b}_arc.exe) >/dev/null 2>&1 \
        || echo "  arc build FAILED: $b"
    # Two C builds. Arc's target machine is created with LLVMGetHostCPUName/Features,
    # so an Arc -O2 build is effectively -march=native; comparing it against a baseline
    # x86-64 C build would flatter Arc for reasons that have nothing to do with Arc.
    clang -O2 "$b.c" -o "bin/${b}_c.exe" -lm 2>/dev/null || echo "  c build FAILED: $b"
    clang -O2 -march=native "$b.c" -o "bin/${b}_cn.exe" -lm 2>/dev/null || echo "  c native build FAILED: $b"
    go build -o "bin/${b}_go.exe" "$b.go" 2>/dev/null      || echo "  go build FAILED: $b"
done

echo
echo "=== correctness (all three must agree) ==="
ok=1
for b in $BENCHES; do
    a=$(./bin/${b}_arc.exe 2>/dev/null | head -1)
    c=$(./bin/${b}_c.exe   2>/dev/null | head -1)
    n=$(./bin/${b}_cn.exe  2>/dev/null | head -1)
    g=$(./bin/${b}_go.exe  2>/dev/null | head -1)
    if [ "$a" = "$c" ] && [ "$c" = "$g" ] && [ "$c" = "$n" ]; then
        printf "  %-8s %s\n" "$b" "$a"
    else
        printf "  %-8s MISMATCH arc=[%s] c=[%s] go=[%s]\n" "$b" "$a" "$c" "$g"
        ok=0
    fi
done
[ $ok = 1 ] || { echo "outputs disagree — not timing"; exit 1; }

echo
echo "=== run time (median of $REPS, ms) ==="
echo "  arc = Arc -O2 (host CPU);  c = clang -O2 (baseline);  cn = clang -O2 -march=native"
printf "  %-8s %7s %7s %7s %7s   %s\n" BENCH ARC C CN GO "arc/cn"
for b in $BENCHES; do
    ta=$(timeit ./bin/${b}_arc.exe)
    tc=$(timeit ./bin/${b}_c.exe)
    tn=$(timeit ./bin/${b}_cn.exe)
    tg=$(timeit ./bin/${b}_go.exe)
    ratio=$(awk -v a="$ta" -v c="$tn" 'BEGIN{ if (c>0) printf "%.2fx", a/c; else print "n/a" }')
    printf "  %-8s %7s %7s %7s %7s   %s\n" "$b" "$ta" "$tc" "$tn" "$tg" "$ratio"
done

echo
echo "=== compile time (median of $REPS, ms) — source to executable ==="
echo "  Go builds are cache-busted: rebuilding unchanged source is a cache hit in Go and"
echo "  measures nothing. Arc has no build cache, so it is always cold."
printf "  %-12s %10s %10s   %s\n" TARGET ARC GO "arc/go"
compile_pair() {
    local b="$1" src_go="$2" src_arc="$3" arcflags="$4"
    local at=() gt=()
    for i in $(seq 1 "$REPS"); do
        printf '// cache-buster %s\n' "$i" > .bust
        cat .bust "$src_go" > "tb_$b.go"
        local s=$(date +%s%N); go build -o "bin/tb_${b}_go.exe" "tb_$b.go" >/dev/null 2>&1; local rc=$?; local e=$(date +%s%N)
        [ $rc = 0 ] || { echo "  go build failed for $b"; return 1; }
        gt+=( $(( (e-s)/1000000 )) )
        cat .bust "$src_arc" > "tb_$b.arc"
        s=$(date +%s%N)
        (cd $ROOT && ./build/artemis.exe "tcon/time/tb_$b.arc" $arcflags -o "tcon/time/bin/tb_${b}_arc.exe") >/dev/null 2>&1
        e=$(date +%s%N)
        at+=( $(( (e-s)/1000000 )) )
    done
    rm -f .bust "tb_$b.go" "tb_$b.arc" "bin/tb_${b}_go.exe" "bin/tb_${b}_arc.exe"
    local ca=$(printf '%s\n' "${at[@]}" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
    local cg=$(printf '%s\n' "${gt[@]}" | sort -n | awk '{a[NR]=$1} END{print a[int((NR+1)/2)]}')
    local ratio=$(awk -v a="$ca" -v g="$cg" 'BEGIN{ if (g>0) printf "%.2fx", a/g; else print "n/a" }')
    printf "  %-12s %10s %10s   %s\n" "$b" "$ca" "$cg" "$ratio"
}
for b in $BENCHES; do compile_pair "$b" "$b.go" "$b.arc" "-O2"; done

echo
echo "=== compile throughput on a large source ==="
if [ -f gen_big.py ]; then
    python gen_big.py 2000 >/dev/null
    compile_pair big big.go big.arc ""
    caf=$(timeit env -C $ROOT ./build/artemis.exe tcon/time/big.arc -S -o tcon/time/bin/big.ll)
    la=$(wc -l < big.arc); lg=$(wc -l < big.go)
    printf "  (arc %s lines, go %s lines; arc frontend alone: %s ms)\n" "$la" "$lg" "$caf"
fi
