Compare implementation of Invert+Blur application in C vs in CASPER.

Works on `casper-tiled10.bmp`. See compiler/apps/blur/README.md.

Data manually collected by editting `blur_omp.c` and rebuilding
for each thread count and each tile size.

Build:

    cd cblur
    make

Run (`casper.bmp` must exist, see above):

    time ./cblur_seq
    time ./cblur_omp

The CASPER version, is in `compiler/apps/blur/`.

Plots:

    python blur-casper-vs-c.py blur-casper-vs-c2.csv blur-casper-vs-c2.svg

To insert into Microsoft products:

    inkscape blur-casper-vs-c2.svg --export-filename blur-casper-vs-c2.emf
