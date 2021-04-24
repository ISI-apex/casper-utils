Utilities for building CASPER and running experiments.

Clone this repository
=====================

This repository needs to be cloned carefully, because it makes use of:
* submodules to depend on repositories that need to be separate
* git LFS (Large File Storage) to store source tarballs
* some tarballs stored in git LFS need to be unpacked (repos for VCS packages)

The cloning proceedure is:
1. clone the repository non-recursively from the "closest" clone (aka. mirror)
2. run the bootstrap script that initializes submodules and git lfs objects

On supported HPC clusters, this repository along with LFS storage is available
on respective shared file systems, and it should be cloned from there, so that
the tarballs are copied quickly rather than downloaded.

The clone commands below select a release rather than master tip. The workflow
is: (1) build a release, (2) update to master tip (accoding to instructions
in the Update section below). This is necessary because only releases
have been tested to build without errors, while the master tip is very
likely to be broken (because it moves quickly and is not tested on all
platforms on every commit). Not all releases have been tested on all
platforms, select the release tested on your platform from the ones available
on [releases page on GitHub](https://github.com/ISI-apex/casper-utils/releases).

In the following commands, replace `RELEASE_ID` with the tag name chosen above.

Take care to include the `file://` URI prefix, since required by `git-lfs`.

* On ***OLCF Summit***:

        $ git clone -b RELEASE_ID file:///gpfs/alpine/csc436/proj-shared/repos/casper-utils.git
        $ ./bootstrap.sh

* On ***ANL Theta***:

        $ git clone -b RELEASE_ID file:///lus/theta-fs0/projects/CASPER/repos/casper-utils.git
        $ ./bootstrap.sh

* On ***ISI gpuk40***:

        $ git clone -b RELEASE_ID file:///home/pub/casper/repos/casper-utils.git
        $ ./bootstrap.sh

* On ***Generic Linux system*** (TODO: no public LFS server available yet, so
  can only clone the repo without LFS objects, won't be able to build the
  Prefix!):

        $ GIT_LFS_SKIP_SMUDGE=1
        $ git clone -b RELEASE_ID https://github.com/ISI-apex/casper-utils.git
        $ ./bootstrap.sh

Note: The bootstrapped git-lsf is inaccessible outside the bootstrap script
deliberately. After you build the Prefix, do all git operations from within the
Prefix to use the git and git-lfs that's installed in the Prefix. This has the
added benefit of a recent git version that works faster with submodules than
the ancient git versions installed on HPC clusters.

Build Gentoo Prefix with CASPER and dependencies
================================================

A Gentoo Prefix is a way to manage dependencies installed from source with a
full-featured package manager without root on a system, hence particularly
useful on HPC clusters. Conceptually, in essence, it's a wrapper around
`./configure && make && make install`. Binaries built within the prefix may be
called from the host as any other binary (although it's usually useful to work
in a prefix shell, see below), and host binaries may be invoked from within the
prefix seemlessly.

A Prefix allows everything to be independent of the host distribution (prefix
bootstrap is very robust and should boostrap on any Linux system) and thus the
versions of any of the software libraries, toolchains, and applications may be
chosen at will. A Prefix is a lot more useful than Singularity or similar
containers based on immutable images. The following sections describe how to
build a prefix on USC HPCC cluster and on other hosts.

***NOTE***: Never run `make install` or similar in the prefix, because this
will write and override files everywhere without any way to track then nor
remove them, which will brake your prefix in the strangest ways imaginable,
without any simple way to recover (you are not protected by root, since all
paths in the prefix are user-writable, so be careful what commands you run). To
install software into the prefix, it must be packaged in an `.ebuild`. It is
usually very quick and easy to write a new `.ebuild` for some new software
library or app, starting from an existing `.ebuild` as a template, and there
are tens of thousands of packages already available (see `eix searchstring`).

Run build job
-------------

In all sections that follow:

* the first argument (`PREFIX_PATH`) is a relative or absolute folder where
  the prefix will be built (ensure several GB of space, and note that after
  prefix is built it cannot be relocated to another path)
* the second argument is a Gentoo profile name specific to the given platform

***NOTE***: before building, remember to checkout the latest release verified
to build on the system that you're building on (see details in Step 0).

The build script is incremental, so in case of errors, troubleshoot them, and
then simply restart the build job by the same method you used to start it.

### USC HPCC or Discovery

Use this wrapper script to launch the build job on worker nodes:

    $ casper-utils/jobs/usc/gpref.job.sh PREFIX_PATH casper-usc-CLUSTER-ARCH CLUSTER[:PARTITION] ARCH

* the second argument is a Gentoo profile name where CLUSTER identifies the
  HPC cluster (usc-hpcc or usc-discovery) and ARCH identifies the CPU family
  for which to optimize via the `-march,-mtune` compiler flags (for the generic
  unoptimized use `amd64`; for supported clusters and cpu families see
  `ebuilds/profiles/casper-usc-*-*`),
* the third argument is the cluster name: either `discovery` or `hpcc`,
  optionally followed by colon and a partition name, e.g. `oneweek`.
* the fourth argument ARCH again, but cannot be `amd64`;
  even if you want a generic (unoptimized) build, you still have to choose a
  CPU family for the build host (`sandybridge` is a reasonable choice for
  building a generic prefix, see notes below).

### ANL Theta

On ANL Theta, the build can be done on a login machine:

    $ casper-utils/jobs/gpref.sh PREFIX_PATH casper-anl-theta-knl

### OLCF Summit

On OLCF Summit, choose `PREFIX_PATH` to be in the project work area backed by
the Spectrum Scale parallel filesystem (aka. "scratch"), not project or user
home file systems backed by NFS. This is because the work area has massive
amounts of space, and because NFS (used for home) creates problems with stale
`.nfsX` files and may not be the fastest when accessed from worker nodes.

The project work area has a 90 day file retention period, which means files are
deleted after they haven't been accessed for this long. To refresh file access
times and thus prevent the purge, run this every couple of months:

    $ find PREFIX_PATH -execdir touch -a {} \;

The build can be done on a worker node (preferred), run this command
on the login machine to submit the job:

    $ casper-utils/jobs/olcf-summit/gpref.job.sh PREFIX_PATH casper-olcf-summit

Once the job starts (see `bjobs`), you can monitor the log with:

    $ ls -t PREFIX_PATH/var/log/prefix/gpref-*.*.log | head -1 | xargs tail -f

Note that there are two parts to the job, each with its own log file, so after
the first half completes, re-run the above command to start monitoring the
second log.

The build job is submitted to Summit's `killable` queue, which is the only
queue that can support single-node reservations of several hours. Jobs in this
queue may be pre-empted by Summit's job scheduler (which terminates the job
with a `SIGTERM` but automatically re-enqueues it). The build job is written
such that is incremental, so it's ok if it is preempted and restarted.

Or, the build can also be done directly on the login macine:

        $ casper-utils/jobs/gpref.sh PREFIX_PATH casper-olcf-summit

### Other Linux hosts

You might want to override the default for number of processors to use (the
default is what `nproc` returns).

    $ export NPROC=16

You may also want to override the default temporary build directory (the
default is the first one that has enough space from the list: `/tmp`,
`/dev/shm`):

    $ export TMPDIR=/path/to/custom/temp/dir

Run the build script directly:

    $ casper-utils/jobs/gpref.sh PREFIX_PATH casper-generic-ARCH

where the second argument is a Gentoo profile name where ARCH identifies the
CPU family for which to optimize via the `-march,-mtune` compiler flags. For
the generic unoptimized use `amd64`; for gpuk40 (Xeon E5-2670) use
`sandybridge`; for supported cpu families see
`ebuilds/profiles/casper-generic-*`).

### Tips and notes

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

Enter the prefix
================

To build and run applications (or anything else) inside the prefix, it is in
theory sufficient to invoke the application by its full path, however it is
usually convenient to "enter" into the prefix, which adds the prefix binary
PATHs to the PATH env var and does other setup.

Generic Linux host
------------------

To enter the prefix on a generic Linux host:

    $ PREFIX_PATH/startprefix

USC HPCC
--------

To enter the prefix on a USC HPCC host (login or worker with interactive shell):

    $ PREFIX_PATH/ptools/pstart

To enqueue a job inside the prefix on a USC HPCC worker node:

    $ PREFIX_PATH/ptools/psbatch CLUSTER[:PARTITION] ARCH[:GPU:GPU_COUNT] MAX_MEM_PER_TASK \
	NUM_NODES NUM_TASKS_PER_NODE TIME_LIMIT command arg arg...

for example:

    $ PREFIX_PATH/ptools/psbatch hpcc sandybridge:k20:1 all 1 1 00:10:00 python --version

The keyword 'all' for `MAX_MEM_PER_TASK` grants all memory on the node
("per task" does not apply anymore).

Test the prefix
===============

Minimal smoke test
------------------

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

MPI hello-world test
--------------------

First, build the `mpitest` application in the prefix:

    $ cd casper-utils/exp/apps/mpitest
    $ PREFIX_PATH/startprefix
    $ make

Check that it was linked correctly against libraries strictly only within the
prefix path:

    $ ldd ./mpitest

Then, while your shell is still in the prefix, run the app with
the following test scripts.

### On a generic host

On a host (compatible with the ARCH for which the prefix was built):

    $ cd casper-utils/exp/test-prefix
    $ bash test-mpi.sh

Note: On a generic host, `test-mpi.sh` will only test multiple ranks on a
single node. Modify the script if you want something different.

### On USC HPCC and Discovery

To launch a job on USC HPCC worker node, run this launcher script
on the login node:

    $ bash exp/test-prefix/usc/test-mpi.job.sh PREFIX_PATH CLUSTER ARCH

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

### On Argonne Theta

Enqueue a job for an in interactive mode:

    qsub -A CASPER -n 2 -t 10 -q debug-cache-quad -I

In the job's shell on the "MOM" node, enter the prefix and run the script
as you would on a generic host, see instructions above.

### On Summit

Enqueue a job for an in interactive mode:

    bsub -P csc436 -nnodes 2 -W 10 -q debug -Is /bin/bash

In the job's shell on the "batch" node, enter the prefix and run the script as
you would on a generic host, see instructions above.

CUDA smoke test
---------------

First, check that the CUDA compiler is installed:

    $ nvcc --version
    nvcc: NVIDIA (R) Cuda compiler driver

There is a hello-world CUDA application in `exp/apps/cuda`: It has currently
been tested only on a generic Linux host (with an Nvidia K40 GPU), not
on any HPC clusters.

    $ cd exp/apps/cuda
    $ make
    $ ./add_cuda
    $ ./add_managed

### Known issues

* Only one of {`add_copy`, `add_managed`} ever worked. I can't remember which
one.

* The app that did work on a generic Linux host with an earlier version of
CUDA now segfaults with CUDA v11.

CFD application test: Cahn-Hilliard
-----------------------------------

The Cahn-Hilliard application in Firedrake can be invoked via a
Makefile-based infrastructure, either directly in the shell or
through launching a job.

First, enter the directory for the relevant `CLUSTER`:

    $ cd exp/cahn-hilliard/CLUSTER

To invoke directly on the node, either a geneirc linux host, or, in interactive
job (on Theta this would be the MOM node, and on Summit the batch node):

1. Launch the persistent PRRTE DVM on all the nodes in your job allocation:

        $ prte --daemonize

2. Invoke the application (you may change the parameters in the target name to
   execute for a different mesh size, ranks, etc.; application output and
   time info will be in `dat/test-1/` directory):

        $ make IN=1 dat/test-1/ch_mesh-64_ranks-4_tpn-16.csv

3. Terminate the DVM (you may invoke multiple jobs without restarting the DVM;
   the invocations may even be concurrent in theory, but this is broken in
   practice, so run only one job at a time):

        $ pterm

CFD application test: Lid-Driven cavity (old scripts)
-----------------------------------------------------

There is a script that runs a CFD application in

* Firedrake FEM framework
* FEniCS (aka. DOLFIN) FEM framework [ currently disabled ]

The script cycles through several direct solvers to test them.

Instructions are similar to the MPI hello-world test:

    $ cd casper-utils/exp/test-prefix
    $ bash test-cfd.sh

The `test-cfd.sh` script takes one optional argument that enables
the test on GPU (besides the non-GPU tests) when non-empty.

### On USC HPCC and Discovery

For USC HPCC or Discovery clusters, there's a script that
submits the test script as a job:

    $ bash exp/test-prefix/usc/test-cfd.job.sh PREFIX_PATH CLUSTER ARCH:GPU

### On Theta and Summit

You must set `NOLOCAL` environment variable so that the launch node (`MOM` on
Theta, `batch` on Summit) is not used:

   $ NOLOCAL=1 bash test-cfd.sh

CASPER compiler test
--------------------

Enter the prefix, if you're not already in the prefix:

    $ PREFIX_PATH/startprefix

### Build the CASPER compiler:

    $ cd casper-utils/compiler
    $ mkdir build
    $ cd build
    $ CC=clang CXX=clang++ cmake ..
    $ make -j6

### SAR app

Build the SAR app:

    $ cd casper-utils/exp/apps/casper/sar
    $ mkdir build
    $ cd build
    $ CC=clang CXX=clang++ cmake ..

On Summit, a manual workaround is required to compensate for some
unimplemented functionality:

    $ cp ../tuned-params-summit.ini tuned-params.ini

Continue with the build:

    $ make -j6

Run the SAR app (On Theta, must be on a worker node (not login, not MOM
node)!):

    $ make sarbp.run

### CFD app

On Theta, the following build (not run) steps must be done on a worker node,
because CASPER compiler does not support cross-compiling for apps that use
the Firedrake/UFL DSL yet. To get a shell on a worker node on Theta, first get
an interactive session:

    $ qsub -A CASPER -n 2 -t 30 -q debug-cache-quad -I --attrs enable_ssh=1

Then, from the MOM node, get the hostname of a worker node and login to it (if
this hangs, you can also check `qstat debug-cache-quad` output for node names):

    $ aprun -n 1 hostname
    nidXXXXX
    $ ssh nidXXXXX

Build the CFD app (On Theta, must do this on worker node! On Summit, must do
tihs on the batch node!):

    $ cd casper-utils/exp/apps/casper/cahnhilliard
    $ mkdir build
    $ cd build
    $ CC=clang CXX=clang++ cmake ..
    $ make -j6

Run the CFD app (On Theta, must do this on the MOM node! On Sumit, must do this
on the batch node!):

    $ RANKS=2 MAPBY=slot make ch.mpirun

Run without MPI (this might work on a generic Linux host, but not
on HPC clusters, because MPI is imported within Python, and hence
the app must be invoked via the mpi launcher):

    $ make ch.run

You can add `make VERBOSE=1` to the make command to see the invoked command line.

#### Known Issues

The app is likely to fail on Theta with `DIVERGED_LINEAR_SOLVE` error.
This is a problem related to floating point differences introduced by the Xeon
Phi architecture, it is an open issue that needs resolving.

On Summit, runs with more than one rank hang in the `mass` task. This
is a new open issue and needs to be debugged.

Running experiments
===================

The above section on testing covers some experiments, but this section goes
into more detail about the infrastructure available for invoking apps
in order to collect measurements.

So far, not all experiments are using this infrastructure:

* The experiment that does use this infrastructure is the one for collecing
  scaling data for the CFD app implemented in Firedrake, it lives in
  `exp/cahnilliard`, and there is a subdirectory per platform, with a makefile
  that has useful functionality for submitting jobs described next.

* The experiments that do not, exist in `exp/some-experiment` subdiectories,
  and use ad-hoc scripts or are completely manual -- each such and has its own
  README with instructions.

This infrastructure allows to invoke apps (on various input sizes, with various
rank counts) by specifying parameters on in a target name and invoking that
target. The infrastructure also makes it easy to enqueue the target invocations
into jobs on the supported HPC clusters.

The general idea is that you can time a particular run of an application
with a command like:

    $ cd casper-utils/exp/cahn-hilliard/CLUSTER
    $ make dat/test-1/ch_mesh-64_ranks-2_tpn-16_trial-1.csv

This command would create this file, if it doesn't already exist. The
underlying command for the app is specified in each `Makefile` and determines
how this file is created and what it contains (e.g. timings), and what other
files might be created along with it (e.g. `.sol` with solution data).

The path must start with two levels of subdirectories `dat/test-1`. The
file name is a key-value map (e.g. `{mesh=64, ranks=1, ....}` above) and
this map is used to construct the command by which the app is invoked.
Any keys can be added, but some keys are required, depending on the
`Makefile` for an individual experiment.

Some job parameters may be specified via make variables:

       $ make MAX_TIME=60 QUEUE=debug dat/test-1/ch_mesh-64_ranks-2_tpn-16.csv

There are two main usage modes:

A. wrapped into a job and enqueued to the job manager
B. direct invocation in the current shell (enabled by `IN=1` make var)

Mode A makes sense only on HPC clusters with a job manager. Mode B makes sense
only on in an interactive job session on a "MOM" node on Theta cluster or a
"batch" node on Summit, or on a generic host without a resource manager.

The infrastructure uses the persistent DVM (Distributed Virtual Machine)
provided by the OpenMPI stack. This sets up the OpenMPI daemons on each
node in the job allocation only onces, and allows jobs to be invoked
without having to redo this setup for each job.

In Mode A, launching of the DVM is part of the job. To submit a job,
you would just run:

    $ make IN=1 dat/test-12/ch_mesh-64_ranks-2_tpn-16_trial-1.csv

But, in Mode B, you need to launch the DVM before invoking the target:

    $ prte --daemonize
    $ make IN=1 dat/test-12/ch_mesh-64_ranks-2_tpn-16_trial-1.csv
    $ make IN=1 dat/test-12/ch_mesh-64_ranks-2_tpn-16_trial-2.csv
    $ pterm

In Mode B, in theory, you can invoke multiple jobs in the same DVM in parallel
(e.g. the two make commands above might be put into background with `&`), but
this doesn't always work due to bugs in PRRTE/OpenMPI, so prefer
to run one job at a time.

In Mode A, in theory, you can invoke multiple targets (one job per each) and
let them run concurrently. However, due to bugs in PRRTE/OpenMPI, when a job in
one DVM dies it takes down the other DVMs with it (observed on Summit). So,
prefer to have only one job running at a time. This is very annoying, since HPC
clusters do let users submit and run at least several jobs concurrently. But,
the only way is to fix the bugs.

Some useful features (but beware of the bugs mentioned above!) (dry-mode
`make -n ...` is useful to see what exactly each command woudl do):

* When multiple targets are specified in the make command, a separate job
  is enqued for each target (Mode A) or a separate prun is invoked for each
  target (Mode B), for example using shell globbing you can collect
  data for two rank counts:

        $ make dat/test-1/ch_mesh-64_ranks-{2,4}_tpn-16_trial-1.csv

* If you want to create one job that will invoke two prun instances, combine
  the targets with a `+` sign (can't use globbing anymore):

        $ make dat/test-1/ch_mesh-64_ranks-2_tpn-16_trial-1.csv+dat/test-1/ch_mesh-64_ranks-2_tpn-16_trial-1.csv

* Inside `Makefile` sets of targets can be defined using the `target-set`
  function so that they may be invoked by the name of the set (by default,
  all targets will be executed within one job):

        $ make dat/test-1/ch_test-2

* If you want to invoke a set of targets with one job per target, suffix with
  `^split`:

        $ make dat/test-1/ch_test-2^split

For the commands that result in more than one job, the jobs are submitted
concurrently to the job manager, unless `QUEUE=debug` is specified (which
supports only one job at a time). If you want to force multiple jobs to
run in sequence use `make -j1`. Currently there is not yet a way to
force sequential execution `prun`s invoke bia a target set (see above).

This infrastructure is implemented in GNU Make by makefiles in
`prefix-tools/make/Makefile.job` and `prefix-tools/clusters/*/make/Makefile`.
Note that these makefiles are installed into the prefix by the
`app-portage/prefix-tools*` packages, so if you want to change them, the
process is to commit the changes, bump the package versions, and re-emerge the
package (you could also temporarily edit the installed copies in
`$EPREFIX/usr/lib/prefix-tools`, but be careful to not lose your edits upon
package re-builds). The makefiles installed in the prefix are included by
per-experiment makefiles that exist outside the prefix and define actual
app commands (e.g. `exp/cahn-hilliard/Makefile`).

Tips for maintaining the Prefix
===============================

On a cluster, Portage (the package manager) tools (`emerge`, `equery`,
`ebuild` `eix`) can be used from login machine if the prefix was built
unoptimized for a particular architecture (i.e. the `*-amd64` profile), and
if some care is taken as described below.

On USC Discovery cluster, invoke portage tools through the wrapper `p4port` on
the login machine and `pport` on the worker nodes, like so:

    p4port emerge app-portage/prefix-tools

The wrapper takes care of setting the build directory to a temporary
directory in tmpfs (for speed and for working around inability to build
on BeegFS due to lacking hard link support), and of setting number of
parallel processes to use appropriately.

Fetching sources
----------------

Whether the package manager is allowed to access the Internet to download
tarballs or update VCS repositories (for packages built directly from repos),
is controlled by `EVCS_OFFLINE` variable in`$EPREFIX/etc/portage/make.conf`.

By default, when prefix is built from scratch, online fetching starts disabled
and is kept disabled until the very end of the build, at which point it is
automatically turned on. It is turned on, because otherwise updating VCS packages, 
won't work intutitively. In offline mode, the VCS packages end up updated only
up to the version stored in the package's repo clone in `distfiles/`, regardless
of the snapshot timestamp in the package version.

For example, if you have version (snapshot) 20210101 of a VCS package A
installed, and the recipe for A in the casper repo gets updated to snapshot
20210102, and you pull that update, and rebuild in offline mode, you'll end up
rebuilding the old 20210101 snapshot, despite the version you'll see being the
new one 20210102. This is because the way snapshot is implemented is using `git
rev-list --before=TIMESTAMP`, so if the repo clone in `distfiles/` is out of
date, and emerge is disallowed to check online, it won't ever see new commits,
and the `before` will evaluate to the same top commit, despite `TIMESTAMP`
having increased.

### Unfetchable tarballs

Online build hosts will automatically fetch tarballs from upstream (subject to
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

Updating
--------

Not that each Prefix directory is standalone and does not reference the
`casper-utils` directory that was used to build the prefix. Updating an
existing Prefix and pulling new commits to `casper-utils`repo are unrelated
operations.

First, you need to decide what kind of update you need:
A. "passively" track changes made by others to the prefix: you want to pull
latest changes to the package recipes in the casper repo,
B. like A, but you know that the snapshot on top of which the overlay
is based has been updated (you can tell by reading the git log of the
casper overlay repo, and by checking the `SNAPSHOT_DATE` variable in
`casper-utils/jobs/gpref-sys.sh`)
C. "actively" change the prefix for others: you want to "rebase" the
casper overlay repo onto a new version of gentoo repo.

### (For Cases B and C  only) Update the gentoo repo to a new snapshot

1. Update the tarballs in the `distfiles/` directory (usually, the prefix will
   point to `casper-utils/distfiles`, but check `DISTDIR` in
`PREFIX/etc/portage/make.conf` to make sure). See earlier sections in this
document for where to get `distfiles` content from, then `rsync` from that
location to get any files that may have been added:

        rsync -aP PATH_TO_DISTFILES/ distfiles/

2. Update the Gentoo repo to a known tested snapshot (not any upstream
   snapshot! upstream moves quickly and we only take updates very rarely). The
latest tested snapshot is in `jobs/gpref-sys.sh` in the `SNAPSHOT_DATE`
variable. Note: it is important to do step 1 above, because upstream servers
don't store snapshots indefinitely. Update to the snapshot given by `YYYYMMDD`
date with command:

        emerge-webrsync -v --keep --revert=YYYYMMDD

3. Rebuild the packages in casper overlay, by following the subsection below
(this will usually require a lot of fixing and very careful attention to
forked packages, which may need to be re-forked (re-based) if they had been
updated upstream, or at least their version needs to be pinned)

4. Edit `casper-utils/jobs/gpref-sys.sh` and set `SNAPSHOT_DATE` variable to
the new date, so that when a prefix is built from scratch, it is built on
the new snapshot that you just updated to.

### Update casper overlay repo

To update the casper overlay, which involves rebuilding any packages that
have changed (and their downstream dependencies requering a rebuild),
enter the overlay directory:

    cd $EPREFIX/var/db/repos/casper

The first time, add the remote for convenience (note: the remote pointing
into casper-utils/ebuilds is needed only for boostrap, and if you want
to commit a new snapshot of ebuilds to casper-utils):

    git remote add up git@github.com:ISI-apex/casper-ebuilds.git

Pull the changes:

    git pull --ff-only up master

#### Generic Linux host

Run emerge to rebuild what needs to be rebuild given the updated ebuilds:

    emerge --ask --update --changed-use --changed-slot --newuse --newrepo \
      --deep --with-bdeps=y @world

Don't continue if there are errors; it may be difficult to diagnose the
problems, but it has to be done, otherwise the prefix will end up in a
chaotic state. The only known errors that are ok, are:
 * `dev-python/randomgen`: versions `>=1.18` are masked, continue with
   installing `1.16.x`

After the emerge finishes, exit and re-enter the prefix, for any updated config
files that set environment variables to be re-applied.

#### On Summit

Follow the instructions for Generic Linux host above, on a login machine.

#### On USC Discovery

On a login machine, first enable online fetching (see subsection above), then
tell portage to figure out what needs to be rebuilt and fetch the sources,
replace `...` with the arguments given for the generic Linux host):

    p4port emerge ...

On USC Discovery, the build should be done on a worker node, not on the
shared login machine where CPU usage limits are enforced. To schedule
a job:

    $EPREFIX/ptools/psbatch discovery ARCH 1 16 02:00:00 pport emerge ...

where ARCH is the architecture for which the prefix was built (or `any`
for an unoptimized prefix). Partition may be specified by appending a suffix
to the first argument like `discovery:oneweek`.

The job will remain in SLURM queue even if the `psbatch` script is killed
(including even if the login node is rebooted).

If your prefix is not optimized for a particular architecture, and if when you
do the first `emerge -f` on the login machine, you see that the packages
that are being updated are quick to build (e.g. python packages without a
compilation step at all, or small packages quick to compile), then you can
just run the second `emerge` on the login machine too:

    $EPREFIX/ptools/pstart p4port emerge ...

After the emerge finishes, exit and re-enter the prefix, for any updated config
files that set environment variables to be re-applied.

Live package versions
---------------------

Package recipes (`.ebuild`s) usually have versions corresponding to releases
from upstrea.  However, there are special recipes called "live" of the form
`package-VER.9999.ebuild`, where `VER` is some components of the version. These
build the tip of the master branch in the upstream repository.

To enable "live" versions a package (master tip from VCS, which will change
every time you re-emerge the package), which may be useful for some packages
provided by the casper overlay, add to
`$EPREFIX/etc/portage/package.accept_keywords` packages in the following
format:

    app-portage/prefix-tools **

There are two (solved) issues with live ebuilds:
1. once installed it's not possible to tell which commit was installed
(without having saved the build log, and then it is painful anyway)
2. once you tested a commit that you bulit via a live ebuild, there's
no way to pin it into the package repository as the latest version to
be installed by default.

Both of these are solved by the custom `snapshot.eclass`. To use it, ebuilds
needs to inherit it and invoke it explicitly, so not all packages use it yet.

This eclass installs a file as part of the installation of the live ebuild
into `PREFIX/etc/snapshot/category/package` with the commit hash in the file.

Also, this eclass supports easy way of pinning by creating a symlink to the
live ebuild with a name that identifies the commit (the commit can only
be identified by a date or date+time, in order for the version to be valid
and well-ordered):

    $ ln -s package-1.9999.ebuild package-1.0.YYYYMMDD.hhmmss_p.ebuild

The `.hhmmss` can be ommitted, in which case it is interpreted as time
`00:00:00+0000` (UTC). The convension we use is `_p` suffix means that the
version includes everything that is in release `1.0` and commits up to date
`YYYYMMDD`, and the `_pre` suffix means that the version is the not yet
released `2.0` with commits up to `YYYYMMDD` (i.e. when upstream has bumped the
version in the repository but doesn't yet realeased a new tarball).

Note that using the timestamp uniquely identifies a commit:

    git rev-list --first-parent --max-count 1 --before=YYYYMMDDThh:mm:ss+0000 HEAD

If you want to see the commit timestamps with a date that you'd use to set
this snapshot timestamp, then use:

    TZ=UTC git log --date=iso-local

Note that this snapshot functionality needs extra care in offline
mode (`EVCS_OFFLINE=1` in `$PREFIX/etc/portage/make.conf`): updating
the timestamp in the package version is not enough in offline mode, you also 
need to make sure that the clone of the package's repo in `distfiles/git-r3/`
is update to date (the way to pull latest commits into that clone is to turn
online mode and simply emerge the package; regardless of version). See
section on `Fetching sources` in this README for more details. You normally
don't have to worry about this because the prefix build script switches the
prefix into online mode at the end of the build.

Forking package recipes
-----------------------

Whenever you need to make a change to the build recipe for a package
you need to fork it from the `gentoo` repo into the `casper` repo. The
procedure is:

1. `cd $EPREFIX/var/db/repos`
2. Check the the package hasn't already been forked:

        $ ls casper/category/package

3. Copy the package directory:

        $ cp -a gentoo/category/package casper/category/

4. Commit the unmodified copy, so that your later diffs are easy to see,
recording the latest version in the commit message:

        $ git add casper/category/package
        $ git commit -m `category/package: LATEST VERSION (gentoo)`

5. Pin the package version, so that when the package gets updated
in Gentoo, and you update the Gentoo snapshot in your prefix, the
package manager doesn't replace your forked version with the
updated version. Add to `casper/profiles/casper/package.mask`:

        >category/package-VERSION

However, pinning is not necessary in some cases. For example, if
you change something about dependencies that enables the package
to be pulled in successfully by the package manager, then your forked
version will be the only one that would work regardless of
updates available in `gentoo` repo, or if those updates are also
fixed to start working then you want to pull them in. An example
where pinning is not needed is when your change is just to relax
the minimum version of the kernel in the dependency list.

Also, note that this pinning guideline has not been followed in
the past, so a lot of currently forked packages are not pinned,
but should be ideally.

### Maintaining the fork

Once a package is forked into `casper` repo, you need to keep
an eye on the updates that may happen to it in the `gentoo`
repo, and whenever possible either unfork (by simply removing the package from
the `casper` repo), or rebase your changes onto the updated version.
Upstream moves quickly, but the `gentoo` repo in your prefix is
only updated manually (see the update section earlier in this README), so the
fork maintainance is something that needs attention only every time after you
update the `gentoo` snapshot.

The rebase is a manual process:

1. Look at the list of patches that you've made to your fork, relative to the
   time when the copy was made from the `gentoo`:

    $ cd casper
    $ git log category/package

2. Then, copy the new version from `gentoo` repo (you may also need to copy
   patches in `files/`):

    $ cp gentoo/category/package/package-UPDATED_VERSION.ebuild \
        casper/category/package/

3. Commit the unmodified updated version:

    $ git add casper/category/package/package-UPDATED_VERSION.ebuild
    $ git commit -m 'category/package: UPDATED_VERSION (gentoo)

4. Apply the patches you've noted in Step 1. This can be done
   either by manually editting the new `.ebuild` file, or exporting
   the patch with `git format-patch HASH^..HEAD` and applying it manually
   with `patch -p1 package-UPDATED_VERSION.ebuild patch_file.patch`.


Troubleshooting: errors about manifests
---------------------------------------

If `emerge` complains about a manifest file (the warning is non-fatal, but do
not ignore it, do not procede with the operation if get warning), this means
that whoever committed a change to a package ebuild recipe did not regenerate
the manifest (bad). To regenerate the manifest, run a command like so for the
respective package:

    p4port ebuild app-portage/prefix-tools/prefix-tools-9999.ebuild manifest

Troubleshooting: emerge/ebuild hangs
------------------------------------

If emerge is waiting for a lock to be released (it will say so), then
it might be due to a previous emerge/ebuild not having completed cleanly,
so try manually cleanup the lock file (after checking for any portage
processes that might still be running):

    rm $EPREFIX/var/db/.pkg.portage_lockfile

If emerge or ebuild hangs at the very end of a merge without any relevant
output, it may be due to file system issues (especially when running on
networked filesystems of various kinds). Try disable the `sync` that is called
after merging (and has been observed to hang on NFS):

    FEATURES="-merge-sync" emerge ...

Troubleshooting: strange errors after prefix was built from scratch
-------------------------------------------------------------------

If you built a prefix from scratch, from a release tag (which means
the prefix was tested on the systems mentioned in the tag name), and
you're seeing strange failures when testing, then the first quick
thing to try is to re-build the package that appears in the stack
traces, if you get one: `emerge category/package`.

This is especially relevant if the build job experienced a failure (and you
restarted it) -- for example, on Theta, occassional spurious filesystem errors
have been observed to cause the build job to fail with a spurious "no space
left on device" error. Simply restarting the job would let it continue, but
the interruption damaged some package installation, so they cause errors
later on. Simply re-emerging the package fixes these kinds of issues.

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

Build applications
===================

There are several applications written in CASPER in `exp/apps/casper/`.
To build and run them, first enter the Prefix as described in an earlier
section (builds have not been tested on other systems, i.e. outside of the
Prefix).

To build, first build the CASPER compiler (must use Clang for all builds):

    cd compiler
    mkdir build && cd build
    CXX=clang++ CC=clang cmake ..
    make

Then, build an app against this build of CASPER, for example for the SAR app:

    cd exp/apps/casper/halide-sar-app/casper
    mkdir build && cd build
    CXX=clang++ CC=clang cmake ..
    make
    make sarbp.run

The app is a separate CMake project, and it contains a relative path to the
CASPER compiler directory assuming the structure of this parent repository.
The CASPER installation in the system/prefix takes precedence over this hint.
