all: mpitest mpitest_dbg mpitest_sleep

mpitest: mpitest.c
	mpicc -O0 -g -o $@ $<

mpitest_dbg: mpitest.c
	mpicc -O0 -g -DWAIT_FOR_DEBUGGER -o $@ $<

mpitest_sleep: mpitest.c
	mpicc -O0 -g -DSLEEP -o $@ $<

clean:
	rm -f *.o mpitest mpitest_dbg mpitest_sleep
