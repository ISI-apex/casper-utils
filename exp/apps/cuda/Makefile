all: add_copy add_managed

define NL


endef
SPACE:=$(subst ,, )

CUDA_GCC_VERSIONS=$(shell cuda-config -s)

GCC_VER=$(word 2,$(shell gcc-config -S $$(gcc-config -c)))
GCC_VER_MAJMIN=$(subst $(SPACE),.,$(wordlist 1,2,$(subst ., ,$(GCC_VER))))
ifeq ($(filter $(GCC_VER_MAJMIN),$(CUDA_GCC_VERSIONS)),)
$(error GCC $(GCC_VER_MAJMIN) not supported by CUDA:$(NL) \
	see supported versions with: cuda-config -s$(NL) \
	see available versions with: gcc-config -l$(NL) \
	select with: gcc-config [index])
endif

ifeq ($(shell echo 'int main() { return 0; }' | gcc -mno-float128 -x c -o /dev/null - 2>/dev/null && echo yes),yes)
	# Workaround for error: _ieee128 undefined (on Summit)
	CXXFLAGS_FLOAT_FIX?=-Xcompiler -mno-float128
endif

add_%: add_%.cu
	nvcc $(CXXFLAGS_FLOAT_FIX) -o $@ $<

clean:
	rm -f add_copy add_managed
