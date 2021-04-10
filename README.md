Utilities for building CASPER and running experiments.

Step 0. Clone this repository recursively
------------------------------------------

This repository contains references to other repositories as git
submodules. To fetch the whole tree, clone recursively:

    $ git clone --recursive https://github.com/ISI-apex/casper-utils

If you already cloned non-recursively then simply do this:

    $ git submodule init
    $ git submodule update

Later, but before building, you'll need to checkout the latest release tag
appropriate for the system on which you are going to build, and then
update to the latest ebuilds repo (following instructions in the Update
section below). Building master tip branch from scratch is not recommended,
because it moves quickly and not every commit is tested, so it is too likely
for the from-scratch build job to fail. Release tags have been verified to
build successfully to the end on the system mentioned in the tag's release
note. You can checkout a tag with:

    $ cd casper-utils
    $ git checkout TAG_IDENTIFIER
    $ git submodule update --rebase

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

On some supported HPC clusters, the `distfiles/` directory can be copied
from a shared filesystem:
* On USC HPCC/Discovery clusters:

        $ rsync -aq /project/jpwalter_356/distfiles/ casper-utils/distfiles/

* On ANL Theta:

	$ rsync -aq /lus/theta-fs0/projects/CASPER/distfiles/ casper-utils/distfiles/

* On Oak Ridge Summit:

	$ rsync -aq /ccs/proj/csc436/distfiles/ casper-utils/distfiles/

* On the ISI gpuk40 machine:

        $ rsync -aq /home/casper/distfiles/ casper-utils/distfiles/

* On other hosts, the same directory is available as a tar archive, which needs
to be downloaded manually from the link below via a browser (or by using
`gdown` tool, `curl`/`wget` likely will not work due to Google intricacies)
and extracted at root of this repository; `TAG_DATE` should be the date
on the latest release tag:

        $ cd casper-utils
        $ gdown https://drive.google.com/uc?id=1v-4jcsP1VAbWrGGsloh9b07y5IMk_Wfa
        $ tar xf distfiles-TAG_DATE.tar

Regardless of on which system in the above list, make your copy writeable:

	$ chmod -R u+rw casper-utils/distfiles/

### Supplemental information: unfetchable tarballs

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

### Maintaining the shared distfiles directories

The procedure followed is that every prefix build (or at least each user) makes
its own copy of distfiles directory, because rarely but sometimes changes might
happen, e.g. when a download of a new tarball results in an error, files are
left around, need to be removed, or for live ebuilds that build from VCS, the
git repository is clone is kept in distfiles directory, so it gets updated
every time the package is rebuilt, so it's not a good idea to let multiple
prefixes be updating that same git repo concurrently.

The shared directory itself is manually updated when casper-utils is tagged
(signifying a tested end-to-end prefix build from scratch on at least one
system, see notes at the top of this README). The shared directory is usually
updated from a copy in the prefix that had been updated.

To enforce that nothing is written into the shared distfiles directory, the
owner of the files manually changes the permissions to make everything
non-writable to everyone, including the owner. For the update, the owner
temporarily makes the files writable.

For the update, temporarily make the contents of the shared directory writable:

      chmod -R o+w PATH_TO_SHARED/distfiles/

Do the copy from an updated distfiles directory:

      rsync -aq PATH_TO_PRIVATE/distfiles/ PATH_TO_SHARED/distfiles/

Make what you just copied readable for everyone:

      chmod -R a+r PATH_TO_SHARED/distfiles/
      find PATH_TO_SHARED/distfiles/ -type d -exec chmod a+x {} \;

Revert the permisions to read-only for everyone, including you the owner:

      chmod -R a-w PATH_TO_SHARED/distfiles/

Step 2. Run build job
---------------------

In all sections that follow:

* the first argument (`PREFIX_PATH`) is a relative or absolute folder where
  the prefix will be built (ensure several GB of space, and note that after
  prefix is built it cannot be relocated to another path)
* the second argument is a Gentoo profile name specific to the given platform

***NOTE***: before building, remember to checkout the latest release verified
to build on the system that you're building on (see details in Step 0).

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
    $ bash exp/test-prefix/test-cfd.job.sh PREFIX_PATH CLUSTER ARCH:GPU

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

#### On Argonne Theta

Enqueue a job (in this example, in interactive mode):

    qsub -A CASPER -n 2 -t 10 -I

In the job's shell on the "MOM" node, first add the special wrapper scripts to
`PATH`:

    $ export EPREFIX=/absolute/path/to/prefix
    $ export PATH=/absolute/path/to/casper-utils/bin/theta:$PATH

Then procede to run the `test-*.job.sh` test scripts as in the instructions for
USC HPCC above.

#### On a generic host

On a host (compatible with the ARCH for which the prefix was built):

    $ PREFIX_PATH/startprefix 
    $ mkdir -p casper-utils/exp/dat
    $ cd casper-utils/exp/dat
    $ bash ../jobs/test-mpi.sh

The `test-cfd.sh` script takes one optional argument that enables
the test on GPU (besides the non-GPU tests) when non-empty:

    $ bash ../jobs/test-cfd.sh 1


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

    $ PREFIX_PATH/ptools/pstart

To enqueue a job inside the prefix on a USC HPCC worker node:

    $ PREFIX_PATH/ptools/psbatch CLUSTER[:PARTITION] ARCH[:GPU:GPU_COUNT] MAX_MEM_PER_TASK \
	NUM_NODES NUM_TASKS_PER_NODE TIME_LIMIT command arg arg...

for example:

    $ PREFIX_PATH/ptools/psbatch hpcc sandybridge:k20:1 all 1 1 00:10:00 python --version

The keyword 'all' for `MAX_MEM_PER_TASK` grants all memory on the node
("per task" does not apply anymore).

Generic Linux host
------------------

To enter the prefix on a generic Linux host:

    $ PREFIX_PATH/startprefix

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

By default, online fetching is disabled (which is appropriate when running
portage from . To enable it comment out `EVCS_OFFLINE=1` from
`$EPREFIX/etc/portage/make.conf`.

Updating
--------

Not that each Prefix directory is standalone and does not reference the
`casper-utils` directory that was used to build the prefix. Updating an
existing Prefix and pulling new commits to `casper-utils`repo are unrelated
operations.

There are three steps to the update, not all of which need to be done
every time:

1. update the tarballs in the `distfiles/` directory (usually, the prefix will
   point to `casper-utils/distfiles`, but check `DISTDIR` in
`PREFIX/etc/portage/make.conf` to make sure). See earlier sections in this
document for where to get `distfiles` content from, then `rsync` from that
location to get any files that may have been added:

        rsync -aP PATH_TO_DISTFILES/ distfiles/

2. update the Gentoo repo to a known tested snapshot (not any upstream snapshot! upstream moves quickly and we only take updates very rarely). The latest tested
snapshot is in `jobs/gpref-sys.sh` in the `SNAPSHOT_DATE` variable. Note: it
is important to do step 1 above, because upstream servers don't store snapshots
indefinitely. Update to the snapshot given by `YYYYMMDD` date with command:

        emerge-webrsync -v --keep --revert=YYYYMMDD

3. update Casper repo (this you want to do as frequently as possible),
   instructions are below

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

### Generic Linux host

Run emerge to rebuild what needs to be rebuild given the updated ebuilds:

    emerge --ask --update --changed-use --newuse --newrepo \
      --deep --with-bdeps=y @world

Don't continue if there are errors; it may be difficult to diagnose the
problems, but it has to be done, otherwise the prefix will end up in a
chaotic state. The only known errors that are ok, are:
 * `dev-python/randomgen`: versions `>=1.18` are masked, continue with
   installing `1.16.x`

### On Summit

Follow the instructions for Generic Linux host above, on a login machine.

### On USC Discovery

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

    $EPREFIX/ptools/pstart p4port emerge -uDU --keep-going --with-bdeps=y @world

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
and well-orderable):

    $ ln -s package-1.9999.ebuild package-1.0_pYYYYMMDD.ebuild

The convension we use is `1.0_p` suffix to mean that the version includes
everything that is in release `1.0` and commits up to date `YYYYMMDD`, and
the `2.0_pre` suffix to mean that the version is the not yet released `2.0`
with commits up to `YYYYMMDD` (i.e. when upstream bumps the version).
Obviously, any unreleased commit can be described by either `_p` or `_pre`
so use your judgement according to what makes sense with the given upstream.

Note that using the full timestamp `YYYYMMDDHHMMSS` uniquely identifies
a commit. See `git rev-list --count 1 --before=YYYYMMDDTHH:MM:SS HEAD`.

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
