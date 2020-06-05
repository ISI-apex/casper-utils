Utilities for building CASPER and running experiments.

NOTES
-----

Job to build Gentoo Prefix on USC HPPC: `jobs/gpref.job.sh`
Job to build Gentoo Prefix on other hosts: `jobs/gpref.sh`

To build Gentoo Prefix need to have snapshot archives in `distfiles/`
that cannot be fetched from online (because upstream hosts only about 1 month
worth of snapshot archives): `portage-DATE.tar.bz2` and `gentoo-DATE.tar.bz2`.
The snapshot date is indicated in the job script.

The archives for the currently-selected date are on USC HPCC filesystem in
`/scratch/acolin/casper-utils/distfiles/`. For online build hosts, while not
strictly necessary, it is helpful to grab all of `distfiles/` to reduce amount
of downloads from the internet. For USC HPCC, whose worker nodes are offline,
this is required.
