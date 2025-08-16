TE_FILES  := $(wildcard *.te)
MOD_FILES := $(TE_FILES:.te=.mod)
PP_FILES  := $(TE_FILES:.te=.pp)

all: $(PP_FILES)

move: $(PP_FILES)
	if [[ ! -d /selinux-pp ]]; then mkdir /selinux-pp; fi
ifneq ($(PP_FILES),)
	mv $(PP_FILES) /selinux-pp/
endif

%.mod: %.te
	checkmodule -M -m -o $@ $<

%.pp: %.mod
	semodule_package -o $@ -m $<

clean:
	rm -f $(MOD_FILES) $(PP_FILES)

.PHONY: all clean move
