Example image-processing application that inverts colors and blurs.
Works on grayscale images in BMP format.

The resulting image will be saved in `apps/blur/casper_blurred.bmp`.

Dimensions are currently hardcoded to correspond to one of a couple of
`casper-*.bmp` test images (download manually or using `gdown` tool):
  
    $ gdown -O apps/blur/casper.bmp https://drive.google.com/uc?id=1TgfuSwNMFSbzrbFT0-kSkoJlfhz8L088
    $ gdown -O apps/blur/casper-tiled10.bmp https://drive.google.com/uc?id=1FosXvMlCaEZrdJ-kOD7y7c64ZY-YYfQ7
    $ gdown -O apps/blur/casper-tiled20.bmp https://drive.google.com/uc?id=17vQcx4xx67Bdye86PeryojnL4BgSw7Vb

Copy to build directory (assumes you've built the compiler and example apps,
see readme in compiler/ directory):

    $ cp ../apps/blur/casper.bmp build/apps/blur/

To run the app:

    $ cd build
    $ make blur_run
