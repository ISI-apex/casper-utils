Datapoints for productivity calculation, based on time-to-tune fan-out factor,
which can be either OMP threads or MPI ranks.

CASPER vs ch2d baseline
single node

There are two variants of the CASPER dataset:
A. execution time on one node as a function of number of OpenMP threads
B. execution time on one node as a function of number of MPI ranks (1 OpenMP thread per rank)

The B variant is practically more relevant; once the programmer establishes that
the MPI parallelism is much more useful than OpenMP parallelism in this implementation.
