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
#incDir=-Iinc
incDir=
srcDstDir=$(outDir)/$(srcDir)
binDir=$(HOME)/prgs/llvmwasm-builder/dist/bin
# Make srcDstDir
$(shell mkdir -p $(srcDstDir) >/dev/null)

bugpoint.wasm=$(binDir)/bugpoint
cc.wasm=$(binDir)/clang
llc.wasm=$(binDir)/llc
s2wasm=$(binDir)/s2wasm
wast2wasm=$(binDir)/wast2wasm
wasm2wast=$(binDir)/wasm2wast
wasm-link=$(binDir)/wasm-link

CC=clang
CFLAGS=-O3 -Weverything -Werror -std=c11 $(incDir) -DDBG=$(_DBG)

OD=objdump
ODFLAGS=-S -M x86_64,intel

LNK=$(CC)
LNKFLAGS=-lm

COMPILE.c = $(CC) $(CFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -g -c

# wasm suffix rules for srcDir
.PRECIOUS: $(srcDstDir)/%.c.bc
$(srcDstDir)/%.c.bc: $(srcDir)/%.c Makefile package.json
	@mkdir -p $(@D)
	$(cc.wasm) -emit-llvm --target=wasm32 $(CFLAGS) $< -c -o $@

.PRECIOUS: $(srcDstDir)/%.c.s
$(srcDstDir)/%.c.s: $(srcDstDir)/%.c.bc
	$(llc.wasm) -asm-verbose=false $< -o $@

S2WASMFLAGS=
.PRECIOUS: $(srcDstDir)/%.c.wast
$(srcDstDir)/%.c.wast: $(srcDstDir)/%.c.s
	$(s2wasm) $(S2WASMFLAGS) $< -o $@

.PRECIOUS: $(srcDstDir)/%.c.wasm
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

# wasm via clang
$(srcDstDir)/%.wasm: $(srcDir)/%.c
	$(cc.wasm) --target=wasm32-unknown-unknown-wasm $(CFLAGS) $< -c -o $@
	$(wasm2wast) $@ -o $(basename $@).wast

all: build.ainit.wasm build.ainit.c.wasm build.wasm build.c.wasm

# [Here](http://llvm.org/docs/HowToSubmitABug.html#incorrect-code-generation) was
# where I got the suggestion to use `bugpoint`.
#
# The below does NOT work, it errors with:
#     "Sorry, I can't automatically select a safe interpreter!".
#
# Bugpoint docs [here](http://llvm.org/docs/Bugpoint.html)
# and [here](http://llvm.org/docs/CommandGuide/bugpoint.html) but not much help.
#
# [This](http://llvm.1065342.n5.nabble.com/bugpoint-question-td63783.html)
# is tiny bit of info suggesting -llc-safe but that didn't work either.
build.ainit.wasm.bugpoint:
	$(bugpoint.wasm) -run-llc $(srcDstDir)/ainit.bc --tool-args --target=wasm32-unknown-unknown-wasm $(CFLAGS)

build.ainit.c.wasm: \
	$(srcDstDir)/ainit.c.wasm

build.ainit.wasm: \
	$(srcDstDir)/ainit.wasm

build.wasm: \
	$(srcDstDir)/mem.wasm

build.c.wasm: \
 $(srcDstDir)/mem.c.wasm

clean:
	@rm -rf $(outDir)
