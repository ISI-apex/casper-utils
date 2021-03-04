This is an experiment to run the baseline Cahn-Hilliard app that is to be
compared with the CASPER implementation of the same numerical computation.

Build the baseline Cahn-Hilliard app:

    cd exp/apps/cahnhilliard_2d/cpp
    mkdir build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release ..
    make ch2d

Run the baseline app to generate `C_*.out` datafiles:

    ./ch2d

Plot the computed result:

    cd ../../
    python visualization/plot2d.py

The simulation parameters (mesh size, etc) are in cpp/src/driver.cpp
and in the plot script as well.

Note: for this data, the number of calculated timesteps (`calc_tsteps`)
was set to 1 in `exp/apps/cahnhilliard_2d/cpp/src/driver.cpp`. This is
to match the CASPER app in `exp/apps/casper/cahnhilliard`, which also
does only one iteration. Although the exact correspondence between these
two implementations is not yet confirmed (WIP).
