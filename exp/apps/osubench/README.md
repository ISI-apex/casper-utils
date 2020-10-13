Recipe for building and running OSU Micro-Benchmarks for MPI on ANL Theta

Note: to run inside the CASPER Prefix, don't use this folder at all,
instead see `casper-utils/exp/osubench`.

Build
-----

To fetch the tarball and build on ANL Theta using the default Cray
toolchain:

    make

If needed, the following step-by-step targets exist: `fetch`, `config`,
`build`, `install`.

Run
---

To run on ANL Theta, enqueue a batch job that will by default run
the full benchmark suite on 2 nodes in debuq queue:

    make job

To configure the resources, you may set `NODES`, `NODES_PER_RANK`.

    make NODES=2 NODES_PER_RANK=1 job

To run selective subset of benchmarks, set `PATTERN`, which will filter tests
by a Bash regexp pattern applied to the path to each benchmark executable:

    make PATTERN=hello job

Log files with the output of the executed commands will be in `bench-*.log.*`.

To open an interactive job and invoke the `run` target manually:

    make jobi

Then, in the interactive job shell, use the `run` target and
optionally set the configuration variables as described above:

    make run
