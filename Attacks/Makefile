CC=nvcc
STD=c++11
CFLAGS=-std=c++11 -arch=compute_61 -rdc=true -lcudadevrt

CPUCC=g++

all: fermat pollard fermatcpu pollardcpu

fermat: fermat.cu
	$(CC) -std=$(STD) $< -o $@

pollard: pollard.cu
	$(CC) $(CFLAGS) $< -o $@ 

fermatcpu: fermatcpu.cpp
	$(CPUCC) $< -o $@

pollardcpu: pollardcpu.cpp
	$(CPUCC) $< -o $@

clean:
	rm fermat pollard fermatcpu pollardcpu