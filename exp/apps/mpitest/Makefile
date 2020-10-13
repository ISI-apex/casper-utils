all: mpitest mpitest_dbg

mpitest: mpitest.c
	mpicc -O0 -g -o $@ $<

mpitest_dbg: mpitest.c
	mpicc -O0 -g -DWAIT_FOR_DEBUGGER -o $@ $<

clean:
	rm -f *.o mpitest mpitest_dbg
