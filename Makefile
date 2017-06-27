# Makefile for test-wasm-mem
# Parameters:
#   DBG=0 or 1 (default = 0)

# Remove builtin suffix rules
#.SUFFIXES:

# _DBG will be 0 if DBG isn't defined on the command line
_DBG = +$(DBG)
ifeq ($(_DBG), +)
  _DBG = 0
endif

outDir=out
srcDir=src
incDir=inc
srcDstDir=$(outDir)/$(srcDir)

# Make srcDstDir
$(shell mkdir -p $(srcDstDir) >/dev/null)

cc.wasm=$(HOME)/prgs/llvmwasm-builder/dist/bin/clang
llc.wasm=$(HOME)/prgs/llvmwasm-builder/dist/bin/llc
s2wasm=$(HOME)/prgs/llvmwasm-builder/dist/bin/s2wasm
wast2wasm=$(HOME)/prgs/llvmwasm-builder/dist/bin/wast2wasm
wasm2wast=$(HOME)/prgs/llvmwasm-builder/dist/bin/wasm2wast
wasm-link=$(HOME)/prgs/llvmwasm-builder/dist/bin/wasm-link

CC=clang
CFLAGS=-O3 -Weverything -Werror -std=c11 -I$(incDir) -DDBG=$(_DBG)

OD=objdump
ODFLAGS=-S -M x86_64,intel

LNK=$(CC)
LNKFLAGS=-lm

COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -g -c

# wasm suffix rules for srcDir
$(srcDstDir)/%.c.bc: $(srcDir)/%.c Makefile package.json
	@mkdir -p $(@D)
	$(cc.wasm) -emit-llvm --target=wasm32 $(CFLAGS) $< -c -o $@

$(srcDstDir)/%.c.s: $(srcDstDir)/%.c.bc
	$(llc.wasm) -asm-verbose=false $< -o $@

S2WASMFLAGS=
.PRECIOUS: $(srcDstDir)/%.c.wast
$(srcDstDir)/%.c.wast: $(srcDstDir)/%.c.s
	$(s2wasm) $(S2WASMFLAGS) $< -o $@

$(srcDstDir)/%.c.wasm: $(srcDstDir)/%.c.wast
	$(wast2wasm) $< -o $@

# wasm suffix rules for libDir
$(libDstDir)/%.c.bc: $(libDir)/%.c Makefile package.json
	@mkdir -p $(@D)
	$(cc.wasm) -emit-llvm --target=wasm32 $(CFLAGS) $< -c -o $@

$(libDstDir)/%.c.s: $(libDstDir)/%.c.bc
	$(llc.wasm) -asm-verbose=false $< -o $@

.PRECIOUS: $(libDstDir)/%.c.wast
$(libDstDir)/%.c.wast: $(libDstDir)/%.c.s
	$(s2wasm) $(S2WASMFLAGS) $< -o $@

$(libDstDir)/%.c.wasm: $(libDstDir)/%.c.wast
	$(wast2wasm) $< -o $@

all: build.wasm build.c.wasm

$(srcDstDir)/mem.wasm: $(srcDir)/mem.c
	$(cc.wasm) --target=wasm32-unknown-unknown-wasm $(CFLAGS) $< -c -o $@
	$(wasm2wast) $@ -o $(basename $@).wast

build.wasm: \
	$(srcDstDir)/mem.wasm

build.c.wasm: \
 $(srcDstDir)/mem.c.wasm

clean:
	@rm -rf $(outDir)
