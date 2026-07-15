#Automated build script

#Configure
cmake -B build -DCMAKE_BUILD_TYPE=Release

#build all support tools
cmake --build build --config Release

build/artemis_bootstrap_cxx.exe compiler/main.arc --unsafe -S -I compiler/std/include -o build/artemis_boot.ll

llc -O2 -filetype=obj -o build/artemis_boot.o build/artemis_boot.ll

g++ build/artemis_boot.o build/llvm_init.o -o build/artemis.exe -LC:/msys64/mingw64/lib -lLLVM-22 -lstdc++ -lm