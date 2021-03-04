# Scaling of Cahn-Hilliard CASPER CFD application

There is a datafile committed in this folder with the subset
of measurements used for plots in the demo/report. To re-measure,
see the section below.

To generate the plots:

	make

Re-measure the data
-------------------

To re-measure the data, use the experiments in
`exp/cahn-hilliard/{theta,summit}/`.

You'd want the following dataset (the datapoints in the `ch-scaling` set are
defined in `exp/cahn-hilliard/{theta,summit}/Makefile`):

	export EPREFIX=~/pc/gpref/gp-knl
	command make dat/scaling/ch-scaling

Then, to aggregate the data:

	command make dat/scaling/ch_agg_part.csv

Copy the `ch_agg_part.csv` files to this directory, then re-generate plots:

	make
