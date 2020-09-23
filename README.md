Utilities for building CASPER and running experiments.

Step 0. Clone this repository recursively
------------------------------------------

This repository contains references to other repositories as git
submodules. To fetch the whole tree, clone recursively:

    $ git --recursive https://github.com/acolinisi/casper-utils

If you already cloned non-recursively then simply do this:

    $ git submodule init
    $ git submodule update

Build Gentoo Prefix with CASPER and dependencies
================================================

A Gentoo Prefix is a way to manage dependencies installed from source with a
full-featured package manager without root on a system, hence particularly
useful on HPC clusters. Conceptually, in essence, it's a wrapper around
`./configure && make && make install`. Binaries built within the prefix may be
called from the host as any other binary (although it's usually useful to work
in a prefix shell, see below), and host binaries may be invoked from within the
prefix seemlessly. A Prefix allows everything to be independent of the host
distribution (prefix bootstrap is very robust and should boostrap on any Linux
system) and thus the versions of any of the software libraries, toolchains, and
applications may be chosen at will. A Prefix is a lot more useful than
Singularity or similar containers based on immutable images. The following
sections describe how to build a prefix on USC HPCC cluster and on other hosts.

Step 1. Prepare source tarballs
------------------------------

To build Gentoo Prefix need to pre-populate `distfiles/` directory
with some special source tarballs (even if the build host is online).

For building on USC HPCC cluster, all source tarballs are on filesystem in
`/scratch/acolin/casper-utils/distfiles/`, so you can just copy
all of it:

	$ rsync -aq /scratch/acolin/casper/casper-utils/distfiles/ casper-utils/distfiles/

On other hosts, the same directory is available as a tar archive, which needs
to be downloaded manually from the link below via a browser (or by using
`gdown` tool, `curl`/`wget` likely will not work due to Google intricacies)
and extracted at root of this repository:

	$ cd casper-utils
	$ gdown https://drive.google.com/uc?id=1nQqWsyeYBwCBA8gUdwSyjryr_OvSQFk1
	$ tar xf distfiles-20200604.tar

Note: Online build hosts will automatically fetch tarballs from upstream (subject to
broken links or server downtime), but some tarballs (listed below) cannot be
fetched from upstream at all. So, even for online hosts, you have to obtain
the tarball directory as described above.

For reference, the special source tarballs that cannot be fetched from upstream:

* `portage-DATE.tar.bz2`
* `gentoo-DATE.tar.bz2`

  The snapshot date is indicated in the job script.  Cannot always be fetched
  from online, because upstream hosts only about 1 month.

* `gentoo-headers{,-base}-KERNEL_VERSION.tar.gz`

  Archives for the kernel version running on the host. The archives for 3.10
  are available in `distfiles/` (see below). To make an archive for other kernel
  versions, see the comments in the ebuild.

* `tetgen` (manually fill out form to get download link)
* `ampi` (manually fill out form to get download link)
* `pyop2` (due to checksum changes in tarball autogenerated by GitHub?)

Note: It is important to use `.tar.gz` archive format (not `.tar.bz2`)
for tarballs used during the stage 1 of bootstrap, because otherwise
the build host needs to have bzip2 installed (an extra dependency). In
the provided distfiles archive and directory, the format is `tar.gz`.

Step 2. Run build job
---------------------
To build Gentoo Prefix on USC HPPC: `jobs/gpref.job.sh`

    $ casper-utils/jobs/gpref.job.sh PREFIX_PATH casper-usc-CLUSTER-ARCH CLUSTER ARCH

To build Gentoo Prefix on other hosts:

    $ casper-utils/jobs/gpref.sh PREFIX_PATH casper-usc-CLUSTER-ARCH

where
* the first argument (`PREFIX_PATH`) is a relative or absolute folder where
  the prefix will be built (ensure several GB of space, and note that after
  prefix is built it cannot be relocated to another path), on USC HPCC you
  most likely want this to be under /scratch or /scratch2 filesystem;
* the second argument is a Gentoo profile name where CLUSTER identifies the
  HPC cluster and ARCH identifies the CPU family for which to optimize via the
  `-march,-mtune` compiler flags (for the generic unoptimized use `amd64`; for
   supported clusters and cpu families see
   `ebuilds/profiles/casper-usc-*-*`),
* the third argument (for USC HPCC only) is the cluster name: either
  `discovery` or `hpcc`.
* the fourth argument (for USC HPCC only) ARCH again, but cannot be `amd64`;
  even if you want a generic (unoptimized) build, you still have to choose a
  CPU family for the build host (`sandybridge` is a reasonable choice for
  building a generic prefix, see notes below).

A useful oneliner for monitoring the log from the latest job invocation
(especially useful when you have to re-invoke the job after fixing failures):

    ls -t PREFIX_PATH/var/log/prefix/*.{out,err} | head -2 | xargs tail -f

The job logs are saved in `PREFIX_PATH/var/log/prefix/`, and logs from
the bootstrap step are also in `PREFIX_PATH/stage{1,2,3}.log`.

Some notes:

* Prefix with all CASPER dependencies takes about 6 hours to build
  on average 16 core box with a normal disk file system. On USC HPCC
  the same exact job takes about 24-48 hours due to slow shared
  filesystem (despite the build working directories being in fast
  local /tmp directory).
* Due to imperfections in the build recipes for some libraries, the
  cpu family of the build host must be the same as that of the target host,
  i.e. if you want a prefix optimized for Sandy Bridge, you have to
  build it on a Sandy Bridge node. (This could be fixed by tracking down
  the offending packages and fixing each to not use target compiler flags
  for tools that need to be run on the build host.)
* Some packages optimize for the build host even if you did not request
  any optimization, so you can't build a generic unoptimized prefix on
  a new CPU family; use Sandy Bridge nodes to build generic prefixes that
  should mostly work on newer CPU families too.
* Builds of numerical libraries on AMD Opteron node appear to be broken
  when optimized for opteron CPU family (even with `-march=native`).
* By default the temporary work directory is removed automatically
  (including when job fails). To keep the dir, set `KEEP_TMPDIR` env
  var to a non-empty value. This is not useful when the build runs on
  a worker node (because not easy to get to the local file system of
  that node after job exists), as is the case on USC HPCC.

Step 3. Test the prefix
------------------------

### Minimal smoke test

The minimal test is to enter the prefix shell (more details on entering the
prefix are in a dedicated section below):

    $ cd PREFIX_PATH
    $ ./startprefix

A new shell should be opened, now try run a program within the prefix:

    $  emerge --version
    Portage 2.3.100 ...

If this smoke test was not successful, check the logs for any errors (see
previous step for log file locations). Errors in later stages, may be fixed by
entering the prefix shell and using portage (`emerge`) to diagnose. Then,
the top-level job may be restarted (as described in previous step), and
it should resume incrementally.

### Application test

The are two tests available:
1. `test-mpi`: a hello-world MPI test on two nodes with two ranks on each
2. `test-cfd`: a CFD benchmark in FEniCS and Firedrake with MPI and GPU.

First, build the `mpitest` application:

    $ cd casper-utils/exp/apps/mpitest
    $ PREFIX_PATH/startprefix
    $ make

Check that it was linked correctly against libraries strictly only within the
prefix path:

    $ ldd ./mpitest


#### On USC HPCC

To launch a job on USC HPCC worker node, run this launcher script
on the login node:

    $ bash exp/test-prefix/test-mpi.job.sh PREFIX_PATH CLUSTER ARCH
    $ bash exp/test-prefix/test-cfd.job.sh PREFIX_PATH CLUSTER ARCH GPU

where `PREFIX_PATH` is the directory with the prefix, CLUSTER is the
name of the compute cluster (e.g. `discovery` see Step 2 above), ARCH is the
CPU Family (e.g. `sandybridge` see Step 2 above) with which the prefix is
compatible and GPU is the GPU model (e.g.  `p100`), run `psfeat` tool from
`casper-utils/bin/` to see the nodes and their GPU resources (do not include
the `gpu:` prefix and do not include the `:N` count suffix).

These scripts will keep running (watching the log files) even after the job
completes (they do not detect job completion), so you have to Ctrl-C when you
see that the job has finished. To check success, check the end of the log for
(but also check for expected output and lack of any errors):

    Leaving Gentoo Prefix with exit status 0

Also, the script just watches the log file, after the job has launched, you
can kill the script with Ctrl-C, and the job will keep running. You can then
manually check the queue with `squeue` and monitor the job log files the
paths to which where printed when the job was run (look for `--output` and
`--error` arguments in the log).

#### On a generic host

On a host (compatible with the ARCH for which the prefix was built):

    $ PREFIX_PATH/startprefix 
    $ mkdir -p casper-utils/exp/dat
    $ cd casper-utils/exp/dat
    $ bash ../jobs/test-mpi.sh
    $ bash ../jobs/test-cfd.sh

Note: As oppsoed on the cluster (see above), on a generic host, the `test-mpi`
will only test one node. Modify the script if you want something different.

Enter the prefix
================

To build and run applications (or anything else) inside the prefix, it is in
theory sufficient to invoke the application by its full path, however it is
usually convenient to "enter" into the prefix, which adds the prefix binary
PATHs to the PATH env var and does other setup.

USC HPCC
--------

To enter the prefix on a USC HPCC host (login or worker with interactive shell):

    $ export PATH=ABSOLUTE_PATH_TO/casper-utils/bin:$PATH
    $ pstart PREFIX_PATH

To enqueue a job inside the prefix on a USC HPCC worker node:

    $ psbatch PREFIX_PATH CLUSTER ARCH GPU:GPU_COUNT MAX_MEM_PER_TASK NUM_NODES NUM_TASKS_PER_NODE TIME_LIMIT command arg arg...

for example:

    $ psbatch /scratch/me/myprefix legacy sandybridge "k20:1" all 1 1 00:10:00 python --version

The keyword 'all' for `MAX_MEM_PER_TASK` grants all memory on the node
("per task" does not apply anymore).

Generic Linux host
------------------

To enter the prefix on a generic Linux host:

    $ PREFIX_PATH/startprefix


Evaluate CASPER Auto-tuner
==========================

Experiments are available for evaluating CASPER Auto-Tuner
by first profiling the application performance and then using
these measurements to train a performance prediction model (as a function of
tunable parameter values) and evaluate the model on
a test subset of the profiling data. The experiments for
the following benchmarks are available:
* `exp/tune-halide`: tune parameters in the Halide schedule for the blur filter
  Halide pipeline, evaluated for both a CPU target and a GPU target,
* `exp/tune-fenics`: tune number of ranks and threads
  in MPI+OpenMP linear solver operator in context of a 2D Lid-Driven Cavity
  Finite Element problem implemented in FEniCS framework.

All the dependencies (LLVM, Halide, OpenCL, etc) of this experiment are
already installed in the Prefix (see first chapter for building a prefix).
The following commands can be run inside the prefix: to enter the Prefix
see the previous chapter. If your system has all the dependencies of
the right versions (with the right patches, etc) installed, then the
following commands should work on your system too (without the Prefix),
but nasty build issues might arise that were already solved in the Prefix.

See `Makefile` in each experiment's directory all available make targets,
including the fine-grained targets for generated intermediate artifacts and for
cleaning; what follows is a brief summary. Multiple targets may be
passed to the same make command where appropriate.

Tune Halide schedule
---------------------

To build and test the binaries for the Halide experiment:

    $ cd casper-utils/exp/tune-halide
    $ make
    $ make test

To perform a quick smoke-test (does not produce a useful model), generate a
small profiling dataset and train the respective prediction models:

    $ make model-small

To generate the large dataset (takes >24 hours) and train the prediction
models:

    $ make model-large

See `tune-halide/Makefile` for fine-grained make targets for generated
intermediate artifacts and for cleaning.

Tune MPI+OpenMP params in linear solver in FEniCS FEM program
--------------------------------------------------------------

The FEniCS benchmark application is in the following directory, and is written
in Python so does not involve an explicit compile step


    $ cd casper-utils/exp/tune-fenics

The perform a quick smoke-test (does not produce a useful model):

    $ make model-small

For larger profiling dataset (takes several hours to collect), there
are two options depending on how the datapoints along the input size
are spread: linearly ({2,4,6,...}), or geometrically ({2,4,16,...}):

    $ make model-lin-large
    $ make model-log-large

Evaluation of the model
-----------------------

When performance prediction models finish training and testing, a few metrics
will be printed:

* MAE: mean absolute error
* MSE: mean squared error
* MAPE(>*x* s): mean absolute percentage error, restricting to data instances
  whose runtime is greater than *x* seconds

*Note: the reason to exclude data instances with small runtime is that
sometimes MAPE gets extremely large (>1000%) when the actual runtime is small.
In addition, we care more about tasks with a large runtime in the scheduling
process.*

* rho: Spearman's rank correlation coefficient (or Spearman's rho), which
  indicates if a higher ranked candidate through prediction also has a higher
ranked true runtime. In short, how well does our model tell about the order of
runtimes.

The speedup from best parameter values over poorest or over average parameter
values can be plotted using scripts in `exp/tune/`, however at the moment, the
raw data output by the previous steps needs to be manually post-processed to
extract aggregated maximum/minimum/etc values.
