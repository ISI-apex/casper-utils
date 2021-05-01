CC=mpicc
CFLAGS=-O0 -g
LIBS=

all: mpitest mpitest_dbg mpitest_sleep

mpitest: mpitest.c
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

mpitest_dbg: mpitest.c
	$(CC) $(CFLAGS) -DWAIT_FOR_DEBUGGER -o $@ $< $(LIBS)

mpitest_sleep: mpitest.c
	$(CC) $(CFLAGS) -DSLEEP -o $@ $< $(LIBS)

clean:
	rm -f *.o mpitest mpitest_dbg mpitest_sleep
