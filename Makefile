# Use "make DEBUG=1" for a debug build

# The build artifacts are put in the "build-release" subfolder (or "build-debug" for a debug build).

# On Windows invoke with "make exe" or "make all"

# Uncomment below as desired to set a particular compiler or force a debug build:
# CXX = g++-12
# DEBUG = 1

ifeq ($(DEBUG), 1)

BIN=build-debug

CXXFLAGS = -Wall -g -Og -std=gnu++17
STRIP=

else

BIN=build-release
CXXFLAGS = -Wall -O2 -DNDEBUG -std=gnu++17
STRIP=-s

endif

# CPPFLAGS = -I$(BIN)

SRCS1 = gpuid.cpp File.cpp ProofCache.cpp Proof.cpp Memlock.cpp log.cpp Worktodo.cpp common.cpp main.cpp Gpu.cpp clwrap.cpp clbundle.cpp Task.cpp Saver.cpp timeutil.cpp Args.cpp state.cpp Signal.cpp FFTConfig.cpp AllocTrac.cpp sha3.cpp md5.cpp version.cpp

SRCS=$(addprefix src/, $(SRCS1))

OBJS = $(SRCS1:%.cpp=$(BIN)/%.o)
DEPDIR := $(BIN)/.d
$(shell mkdir -p $(DEPDIR) >/dev/null)
DEPFLAGS = -MT $@ -MMD -MP -MF $(DEPDIR)/$*.Td
COMPILE.cc = $(CXX) $(DEPFLAGS) $(CXXFLAGS) $(CPPFLAGS) $(TARGET_ARCH) -c
POSTCOMPILE = @mv -f $(DEPDIR)/$*.Td $(DEPDIR)/$*.d && touch $@

LIBS = $(LIBPATH)

$(BIN)/prpowl: ${OBJS}
	$(CXX) $(CXXFLAGS) -o $@ ${OBJS} $(LIBS) -lOpenCL ${STRIP}

# Instead of linking with libOpenCL, link with libamdocl64
$(BIN)/prpowl-amd: ${OBJS}
	$(CXX) $(CXXFLAGS) -o $@ ${OBJS} $(LIBS) -lamdocl64 -L/opt/rocm/lib ${STRIP}

prpowl: $(BIN)/prpowl

exe: $(BIN)/prpowl
	mv $(BIN)/prpowl $(BIN)/prpowl.exe
        
amd: $(BIN)/prpowl-amd

all: prpowl amd

clean:
	rm -rf build-debug build-release

$(BIN)/%.o : src/%.cpp $(DEPDIR)/%.d
	$(COMPILE.cc) $(OUTPUT_OPTION) $<
	$(POSTCOMPILE)

$(DEPDIR)/%.d: ;
.PRECIOUS: $(DEPDIR)/%.d

src/version.cpp : src/version.inc

src/version.inc: FORCE
	echo \"`git describe --tags --long --dirty --always`\" > $(BIN)/version.new
	diff -q -N $(BIN)/version.new $@ >/dev/null || mv $(BIN)/version.new $@
	echo Version: `cat $@`

# clbundle.cpp is just a wrapping of the OpenCL sources (*.cl) as a C string.
# If any of the src/*.cl files have been updated, this rule regenerates clbundle.cpp
src/clbundle.cpp: src/*.cl
	python3 tools/expand.py src/gpuowl.cl src/clbundle.cpp

FORCE:

include $(wildcard $(patsubst %,$(DEPDIR)/%.d,$(basename $(SRCS1))))
