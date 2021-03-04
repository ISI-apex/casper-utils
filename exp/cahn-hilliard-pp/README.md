Performace-Portability and Performance-Efficiency between CASPER and C++
baseline implementations of the Cahn-Hilliard application

The data for baseline is from `exp/cahn-hilliard-baseline/` experiment.

The data for CASPER app is from `exp/cahn-hilliard/` experiment, but the
aggregated data files (with the relevant subset of datapoints) have been moved
into the present subfolder: `ch-casper-mesh-256.csv`.

All datapoints used for PE and PP calculation are for single node.

The PE is calculated as: `min_over_threads(casper_time) / min_over_threads(baseline_time)`
The PP is calculated as: `(baseline_theta_time / baseline_summit_time) / (casper_theta_time / casper_summit_time)`
