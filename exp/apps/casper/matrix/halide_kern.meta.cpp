// Halide tutorial lesson 15: Generators part 1

// This lesson demonstrates how to encapsulate Halide pipelines into
// reusable components called generators.

// On linux, you can compile and run it like so:
// g++ lesson_15*.cpp ../tools/GenGen.cpp -g -std=c++11 -fno-rtti -I ../include -L ../bin -lHalide -lpthread -ldl -o lesson_15_generate
// bash lesson_15_generators_usage.sh

// On os x:
// g++ lesson_15*.cpp ../tools/GenGen.cpp -g -std=c++11 -fno-rtti -I ../include -L ../bin -lHalide -o lesson_15_generate
// bash lesson_15_generators_usage.sh

// If you have the entire Halide source tree, you can also build it by
// running:
//    make tutorial_lesson_15_generators
// in a shell with the current directory at the top of the halide
// source tree.

#include "Halide.h"
#include <stdio.h>

using namespace Halide;

// Generators are a more structured way to do ahead-of-time
// compilation of Halide pipelines. Instead of writing an int main()
// with an ad-hoc command-line interface like we did in lesson 10, we
// define a class that inherits from Halide::Generator.
class MyFirstGenerator : public Halide::Generator<MyFirstGenerator> {
public:
    // We declare the Inputs to the Halide pipeline as public
    // member variables. They'll appear in the signature of our generated
    // function in the same order as we declare them.
    Input<uint8_t> offset{"offset"};
    Input<Buffer<double>> input{"input", 2};

    // We also declare the Outputs as public member variables.
    Output<Buffer<double>> brighter{"brighter", 2};

    // Typically you declare your Vars at this scope as well, so that
    // they can be used in any helper methods you add later.
    Var i, j;

    // We then define a method that constructs and return the Halide
    // pipeline:
    void generate() {
        // In lesson 10, here is where we called
        // Func::compile_to_file. In a Generator, we just need to
        // define the Output(s) representing the output of the pipeline.

        // For our 3x2 matrix example, the strides are {2, 1} and the code
        // below will iterate: for(rows){for(columns)}.

        brighter(i, j) = input(i, j) + offset;

        // Schedule it.
        // brighter.vectorize(x, 16).parallel(y);

        // The runtime buffers will be laid out in the same way as the
        // memref objects are (the base type of Casper Dat objects), which
        // defaults to row-major, i.e. matrix[i, j] is element
        // at row i and column j where elements in one row are consecutive in
        // memory. The buffers declared here must match that layout, but
        // Halide's default does not match this memref default, unfortunately
        // -- Halide's default is column-major matrix(x, y) is element in row y
        // column x (which makes sense in context of images and X/Y coordinate
        // system). So, we either need to change layout of the Dat objects
        // declared in the Casper metaprogram, or change the layout of the
        // Halide buffers declared here, we do the latter.

        // TODO: why exactly does Halide compiler need to know the strides at
        // compilation time? At runtime the strides in the passed buffer are
        // checked against the strides specified here at compile time -- but
        // are the strides used at compile time? Having to declare strides
        // here makes the kernel not generic across matrix sizes (at least
        // regarding the last n-1 dimensions).
        int mat_cols = 2; // sucks that not agnostic, but how else?
        input.dim(0).set_stride(mat_cols);
        input.dim(1).set_stride(1);
        brighter.dim(0).set_stride(mat_cols);
        brighter.dim(1).set_stride(1);
    }
};

// We compile this file along with tools/GenGen.cpp. That file defines
// an "int main(...)" that provides the command-line interface to use
// your generator class. We need to tell that code about our
// generator. We do this like so:
HALIDE_REGISTER_GENERATOR(MyFirstGenerator, halide_bright)
