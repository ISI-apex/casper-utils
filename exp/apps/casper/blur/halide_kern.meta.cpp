#include "casper.h"
#include "Halide.h"
#include <stdio.h>
#include <cmath>

using namespace Halide;

class HalideBlur : public Halide::Generator<HalideBlur> {
public:
    GeneratorParam<int> tile_x{"tile_x", /* 32 */ 1};  // X tile.
    GeneratorParam<int> tile_y{"tile_y", /* 8 */ 1};   // Y tile.

#if 0 // not used since tuning is out-of-band (not by the compiler) now
    // TODO: These do not alter schedule, but autotuner code assumes
    // there are input size parameters. This needs to be thought out.
    cac::InputGeneratorParam ph{"ph", 1024};
    cac::InputGeneratorParam pw{"pw", 1024};
#endif
    // TODO: name descriptively
    cac::TunableGeneratorParam p1{"p1", 1};
    cac::TunableGeneratorParam p2{"p2", 1};
    cac::TunableGeneratorParam p3{"p3", 1};
    cac::TunableGeneratorParam p4{"p4", 1};

    Input<Buffer<double>> input{"input", 2};
    Output<Buffer<double>> blur_y{"blur_y", 2};

    // Above 64 takes too long to compile
    static const int BLUR_WIDTH = 16;

    // TODO: it's bad we have to know the width (see comments below)
    static const int IMG_WIDTH = 256; // casper-256x100.bmp
    //static const int IMG_WIDTH = 1695; // casper.bmp
    //static const int IMG_WIDTH = 16950; // casper-tiled10.bmp
    // static const int IMG_WIDTH = 27120; // casper-tiled20.bmp

    void generate() {
        Func blur_x("blur_x");
        Var x("x"), y("y"), xi("xi"), yi("yi");

        Expr e_x{0.0}, e_y{0.0};
        for (int i = 0; i < BLUR_WIDTH; ++i)
             e_x += Expr{1.0/(i+1)} * input(x + i, y);
        blur_x(x, y) = e_x;

        for (int i = 0; i < BLUR_WIDTH; ++i)
            e_y += Expr{1.0/(i+1)} * blur_x(x, y + i);
        blur_y(x, y) = e_y;

        // CPU schedule.
#if 0
        blur_y.split(y, y, yi, 8).parallel(y).vectorize(x, 8);
        blur_x.store_at(blur_y, y).compute_at(blur_y, yi).vectorize(x, 8);
#else
        Var x_i("x_i");
        Var x_i_vi("x_i_vi");
        Var x_i_vo("x_i_vo");
        Var x_o("x_o");
        Var x_vi("x_vi");
        Var x_vo("x_vo");
        Var y_i("y_i");
        Var y_o("y_o");

#if 0
        int v1 = pow(2,p1);
        int v2 = pow(2,p2);
        int v3 = pow(2,p3);
        int v4 = pow(2,p4);
#else
        int v1 = p1;
        int v2 = p2;
        int v3 = p3;
        int v4 = p4;
#endif

        {
            Var x = blur_x.args()[0];
            blur_x
                .compute_at(blur_y, x_o)
                .split(x, x_vo, x_vi, v1)
                .vectorize(x_vi);
        }
        {
            Var x = blur_y.args()[0];
            Var y = blur_y.args()[1];
            blur_y
                .compute_root()
                .split(x, x_o, x_i, v2)
                .split(y, y_o, y_i, v3)
                .reorder(x_i, y_i, x_o, y_o)
                .split(x_i, x_i_vo, x_i_vi, v4)
                .vectorize(x_i_vi)
                .parallel(y_o)
                .parallel(x_o);
        }
#endif
    }
};

HALIDE_REGISTER_GENERATOR(HalideBlur, halide_blur)
