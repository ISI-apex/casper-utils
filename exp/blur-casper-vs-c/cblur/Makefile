#CFLAGS?=-O0 -g
CFLAGS?=-O3
CC?=gcc

all: cblur_seq cblur_omp

cblur_seq: cblur.c bmp.c inv.c blur_seq.c
	$(CC) $(CFLAGS) -o $@ $^

cblur_omp: cblur.c bmp.c inv_omp.c blur_omp.c
	$(CC) $(CFLAGS) -fopenmp -o $@ $^

clean:
	rm -f cblur_seq cblur_omp
