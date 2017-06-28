# Test wasm compile time array initialization

There is a bug initializing arrays with structures such as `gBd` below:
```
struct bd {
  char d;
};

static struct bd gBd[2] = {{1}, {2}};

static char gU8[2] = {3, 4};
```
When compiling `mem.c` is complied with clang with `--target=wasm32` and using the
clang -> llc -> s2wasm -> wast2wasm toolchain the data section is the expected
output in the mem.c.wast file. Specifically the byte values are in consecutive
addresses:
```
 (data (i32.const 16) "\01\02")
 (data (i32.const 32) "\03\04")
```
If `mem.c` is compiled with `--target=wasm32-unknown-unknown-wasm` then `clang`
outputs a wasm file directly. Doing this output is wrong, you can see it by looking
at the resulting `mem.wasm` file looking and you'll see that the values 01 and 02
are not adjacent to each other for `gBd` but are for `gU8`:
```
  (data (i32.const 0) "\01\00\00\02\00\00\03\04"))
```

If you follow the instructions below and run `yarn install` and
then `yarn mem` you'll see the `mem.ts` output further showing
the bug. When running `out/src/mem.c.wasm` we see correct output
for both `gBd` and `gU8`:
```
load_IMem: out/src/mem.c.wasm

get_gBdAddr: val
16:           get_gBd(0)=1
17:           get_gBd(1)=2
18:           get_gBd(2)=0
19:           get_gBd(3)=0
get_gU8Addr: val
32:           get_gU8(0)=3
33:           get_gU8(1)=4
34:           get_gU8(2)=0
35:           get_gU8(3)=0
```

But running `out/src/mem.wasm` the output is *incorrect* for `gBd` but
good for `gU8`:
```
load_IMem: out/src/mem.wasm

get_gBdAddr: val
0:           get_gBd(0)=1
1:           get_gBd(1)=0
2:           get_gBd(2)=0
3:           get_gBd(3)=2
get_gU8Addr: val
6:           get_gU8(0)=3
7:           get_gU8(1)=4
8:           get_gU8(2)=0
9:           get_gU8(3)=0
```

# Simpler example

I've created simpler example, `src/ainit.c` you can run
`make build.ainit.c.wasm` and see the correct output:
```
$ make build.ainit.c.wasm
/home/wink/prgs/llvmwasm-builder/dist/bin/clang -emit-llvm --target=wasm32 -O3 -Weverything -Werror -std=c11  -DDBG=0 src/ainit.c -c -o out/src/ainit.c.bc
/home/wink/prgs/llvmwasm-builder/dist/bin/llc -asm-verbose=false out/src/ainit.c.bc -o out/src/ainit.c.s
/home/wink/prgs/llvmwasm-builder/dist/bin/s2wasm  out/src/ainit.c.s -o out/src/ainit.c.wast
/home/wink/prgs/llvmwasm-builder/dist/bin/wast2wasm out/src/ainit.c.wast -o out/src/ainit.c.wasm
```
And the `out/src/ainit.c.wast` file is:
```
$ cat out/src/ainit.c.wast
(module
 (table 0 anyfunc)
 (memory $0 1)
 (data (i32.const 16) "\01\02")
 (export "memory" (memory $0))
)

```
If you then run `make build.ainit.wasm`
```
$ make build.ainit.wasm
/home/wink/prgs/llvmwasm-builder/dist/bin/clang --target=wasm32-unknown-unknown-wasm -O3 -Weverything -Werror -std=c11  -DDBG=0 src/ainit.c -c -o out/src/ainit.wasm
/home/wink/prgs/llvmwasm-builder/dist/bin/wasm2wast out/src/ainit.wasm -o out/src/ainit.wast
```
You'll see the incorrect results in `out/src/ainit.wast`
```
$ cat out/src/ainit.wast
(module
  (table (;0;) 0 anyfunc)
  (memory (;0;) 1)
  (global (;0;) i32 (i32.const 0))
  (export "gBd" (global 0))
  (data (i32.const 0) "\01\00\00\02\00\00"))
```

# Prerequistes
- clang
- node
- yarn
- [llvmwasm-builder](https://github.com/winksaville/llvmwasm-builder) installed at ../llvmwasm-builder

# Install
```
$ yarn install
yarn install v0.24.6
[1/4] Resolving packages...
[2/4] Fetching packages...
[3/4] Linking dependencies...
[4/4] Building fresh packages...
$ yarn postcleanup
yarn postcleanup v0.24.6
$ mkdir -p build out 
Done in 0.10s.
Done in 0.53s.
```

# Run mem
```
$ yarn mem
yarn mem v0.24.6
$ yarn build
yarn build v0.24.6
$ make S2WASMFLAGS=--import-memory build.c.wasm && make build.wasm && tsc -p src/utils.tsconfig.json && tsc -p src/mem.tsconfig.json 
/home/wink/prgs/llvmwasm-builder/dist/bin/clang -emit-llvm --target=wasm32 -O3 -Weverything -Werror -std=c11 -Iinc -DDBG=0 src/mem.c -c -o out/src/mem.c.bc
/home/wink/prgs/llvmwasm-builder/dist/bin/llc -asm-verbose=false out/src/mem.c.bc -o out/src/mem.c.s
/home/wink/prgs/llvmwasm-builder/dist/bin/s2wasm --import-memory out/src/mem.c.s -o out/src/mem.c.wast
/home/wink/prgs/llvmwasm-builder/dist/bin/wast2wasm out/src/mem.c.wast -o out/src/mem.c.wasm
rm out/src/mem.c.bc out/src/mem.c.s
/home/wink/prgs/llvmwasm-builder/dist/bin/clang --target=wasm32-unknown-unknown-wasm -O3 -Weverything -Werror -std=c11 -Iinc -DDBG=0 src/mem.c -c -o out/src/mem.wasm
/home/wink/prgs/llvmwasm-builder/dist/bin/wasm2wast out/src/mem.wasm -o out/src/mem.wast
Done in 3.96s.
$ node build/mem.js 
load_IMem: out/src/mem.c.wasm

get_gBdAddr: val
16:           get_gBd(0)=1
17:           get_gBd(1)=2
18:           get_gBd(2)=0
19:           get_gBd(3)=0
get_gU8Addr: val
32:           get_gU8(0)=3
33:           get_gU8(1)=4
34:           get_gU8(2)=0
35:           get_gU8(3)=0

load_IMem: out/src/mem.wasm

get_gBdAddr: val
0:           get_gBd(0)=1
1:           get_gBd(1)=0
2:           get_gBd(2)=0
3:           get_gBd(3)=2
get_gU8Addr: val
6:           get_gU8(0)=3
7:           get_gU8(1)=4
8:           get_gU8(2)=0
9:           get_gU8(3)=0
Done in 4.26s.
```

