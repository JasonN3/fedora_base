TE_FILES  := $(wildcard *.te)
MOD_FILES := $(TE_FILES:.te=.mod)
PP_FILES  := $(TE_FILES:.te=.pp)

all: $(PP_FILES)

%.mod: %.te
	echo "Compiling $< module"
	checkmodule -M -m -o $@ $<

%.pp: %.mod
	echo "Packaging $< module"
	semodule_package -o $@ -m $<

clean:
	rm -f $(MOD_FILES) $(PP_FILES)

.PHONY: all clean
