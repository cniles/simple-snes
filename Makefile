.PHONY: simple.obj

build: simple.smc

simple.obj: simple.asm 
	wla-65816 -o simple.obj simple.asm

simple.smc: simple.obj
	wlalink -v -r linkitems simple.smc
