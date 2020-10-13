Recipe for running OSU Micro-Benchmarks for MPI within Prefix on ANL Theta

Note: to run natively on ANL That (not within Prefix), don't use this folder at
all, instead see `../apps/osubench`.

Within the prefix, the benchmakrs are installed via the
`app-benchmarks/osu-micro-benchmarks` package.

To run on ANL Theta, first export path to the prefix:

    export EPREFIX=/absolute/path/to/prefix/root

Then enqueue a batch job that will by default run
the full benchmark suite on 2 nodes in debuq queue:

    make job

To configure the resources, you may set `NODES`, `MAP_BY`.

    make NODES=2 MAP_BY=node job

To run selective subset of benchmarks, set `PATTERN`, which will filter tests
by a Bash regexp pattern applied to the path to each benchmark executable:

    make PATTERN=hello job

Log files with the output of the executed commands will be in
`bench-prefix-*.log.*`.

To open an interactive job and invoke the `run` target manually:

    make jobi

Then, in the interactive job shell, use the `run` target and
optionally set the configuration variables as described above:

    make run
