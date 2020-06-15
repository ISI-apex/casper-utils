// This FFT is an implementation of the algorithm described in
// http://research.microsoft.com/pubs/131400/fftgpusc08.pdf
// This algorithm is more well suited to Halide than in-place
// algorithms.

#include "Halide.h"
#include <cmath>  // for log2
#include <cstdio>
#include <vector>

#include <stdio.h>
#include <random>
#include <iostream>
#include <fstream>

#include "fft.h"
#include "halide_benchmark.h"

#ifdef WITH_FFTW
#include <fftw3.h>
#endif

using namespace Halide;
using namespace Halide::Tools;

Var x("x"), y("y");

template<typename T>
Func make_real(const Buffer<T> &re) {
    Func ret;
    ret(x, y) = re(x, y);
    return ret;
}

template<typename T>
ComplexFunc make_complex(const Buffer<T> &re) {
    ComplexFunc ret;
    ret(x, y) = re(x, y);
    return ret;
}

// A helper function to check if OpenCL, Metal or D3D12 is present on the host machine.

Target find_gpu_target() {
    // Start with a target suitable for the machine you're running this on.
    Target target = get_host_target();

    std::vector<Target::Feature> features_to_try;
    if (target.os == Target::Windows) {
        // Try D3D12 first; if that fails, try OpenCL.
        if (sizeof(void*) == 8) {
            // D3D12Compute support is only available on 64-bit systems at present.
            features_to_try.push_back(Target::D3D12Compute);
        }
        features_to_try.push_back(Target::OpenCL);
    } else if (target.os == Target::OSX) {
        // OS X doesn't update its OpenCL drivers, so they tend to be broken.
        // CUDA would also be a fine choice on machines with NVidia GPUs.
        features_to_try.push_back(Target::Metal);
    } else {
        features_to_try.push_back(Target::OpenCL);
    }
    // Uncomment the following lines to also try CUDA:
    features_to_try.push_back(Target::CUDA);

    for (Target::Feature f : features_to_try) {
        Target new_target = target.with_feature(f);
        if (host_supports_target_device(new_target)) {
            return new_target;
        }
    }

    printf("Requested GPU(s) are not supported. (Do you have the proper hardware and/or driver installed?)\n");
    return target;
}

int main(int argc, char **argv) {
    
    int W = 0; // input size TODO
    int H = 0;

    int w = 0;
    int h = 0;

    if (argc != 8) {
        std::cerr << "Usage: " << argv[0] << " <log(width)> <log(height)>"
            << " <iterations> <samples> <reps> <use_gpu> <output_file>"
            << std::endl;
        return 1;
    }
        
    w = atoi(argv[1]);
    h = atoi(argv[2]);

    W = pow(2,w);
    H = pow(2,h);

    int NUM = atoi(argv[3]);
    int SAMPLES = atoi(argv[4]);
    int REPS = atoi(argv[5]);
    int GPU = atoi(argv[6]);
    std::string output_file(argv[7]);

    // Generate a random image to convolve with.
    Buffer<float> in(W, H);
    for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
            in(x, y) = (float)rand() / (float)RAND_MAX;
        }
    }

    // Construct a box filter kernel centered on the origin.
    const int box = 3;
    Buffer<float> kernel(W, H);
    for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
            int u = x < (W - x) ? x : (W - x);
            int v = y < (H - y) ? y : (H - y);
            kernel(x, y) = u <= box / 2 && v <= box / 2 ? 1.0f / (box * box) : 0.0f;
        }
    }

    Target target;
    if (GPU) {
        target = find_gpu_target();
        if (!target.has_gpu_feature()) {
            return 1;
        }
    } else {
        target = get_jit_target_from_environment();
    }
    printf("Target: %s\n", target.to_string().c_str());

    Fft2dDesc fwd_desc;
    Fft2dDesc inv_desc;
    inv_desc.gain = 1.0f / (W * H);

    Func filtered_c2c;
    {
        // Compute the DFT of the input and the kernel.
        ComplexFunc dft_in = fft2d_c2c(make_complex(in), W, H, -1, target, fwd_desc);
        ComplexFunc dft_kernel = fft2d_c2c(make_complex(kernel), W, H, -1, target, fwd_desc);
        dft_in.compute_root();
        dft_kernel.compute_root();

        // Compute the convolution.
        ComplexFunc dft_filtered("dft_filtered");
        dft_filtered(x, y) = dft_in(x, y) * dft_kernel(x, y);

        // Compute the inverse DFT to get the result.
        ComplexFunc dft_out = fft2d_c2c(dft_filtered, W, H, 1, target, inv_desc);
        dft_out.compute_root();

        // Extract the real component and normalize.
        filtered_c2c(x, y) = re(dft_out(x, y));
    }

    Func filtered_r2c;
    {
        // Compute the DFT of the input and the kernel.
        ComplexFunc dft_in = fft2d_r2c(make_real(in), W, H, target, fwd_desc);
        ComplexFunc dft_kernel = fft2d_r2c(make_real(kernel), W, H, target, fwd_desc);
        dft_in.compute_root();
        dft_kernel.compute_root();

        // Compute the convolution.
        ComplexFunc dft_filtered("dft_filtered");
        dft_filtered(x, y) = dft_in(x, y) * dft_kernel(x, y);

        // Compute the inverse DFT to get the result.
        filtered_r2c = fft2d_c2r(dft_filtered, W, H, target, inv_desc);
    }

    Buffer<float> result_c2c = filtered_c2c.realize(W, H, target);
    Buffer<float> result_r2c = filtered_r2c.realize(W, H, target);

    for (int y = 0; y < H; y++) {
        for (int x = 0; x < W; x++) {
            float correct = 0;
            for (int i = -box / 2; i <= box / 2; i++) {
                for (int j = -box / 2; j <= box / 2; j++) {
                    correct += in((x + j + W) % W, (y + i + H) % H);
                }
            }
            correct /= box * box;
            if (fabs(result_c2c(x, y) - correct) > 1e-6f) {
                printf("result_c2c(%d, %d) = %f instead of %f\n", x, y, result_c2c(x, y), correct);
                return -1;
            }
            if (fabs(result_r2c(x, y) - correct) > 1e-6f) {
                printf("result_r2c(%d, %d) = %f instead of %f\n", x, y, result_r2c(x, y), correct);
                return -1;
            }
        }
    }

    // For a description of the methodology used here, see
    // http://www.fftw.org/speed/method.html

    // Take the minimum time over many of iterations to minimize
    // noise.
    const int samples = SAMPLES;
    const int reps = REPS;

    Var rep("rep");

    Buffer<float> re_in = lambda(x, y, 0.0f).realize(W, H);
    Buffer<float> im_in = lambda(x, y, 0.0f).realize(W, H);

    printf("%12s %5s%11s%5s %5s%11s%5s\n", "", "", "Halide", "", "", "FFTW", "");
    printf("%12s %10s %10s %10s %10s %10s\n", "DFT type", "Time (us)", "MFLOP/s", "Time (us)", "MFLOP/s", "Ratio");

/*
    ComplexFunc c2c_in;
    // Read all reps from the same place in memory. This effectively
    // benchmarks taking the FFT of cached inputs, which is a
    // reasonable assumption for a well optimized program with good
    // locality.
    c2c_in(x, y, rep) = {re_in(x, y), im_in(x, y)};
    Func bench_c2c = fft2d_c2c(c2c_in, W, H, -1, target, fwd_desc);
    bench_c2c.compile_to_lowered_stmt(output_file + ".c2c.html", bench_c2c.infer_arguments(), HTML);
    Realization R_c2c = bench_c2c.realize(W, H, reps, target);
    // Write all reps to the same place in memory. This means the
    // output appears to be cached on all but the first
    // iteration. This seems to match the behavior of FFTW's benchmark
    // code, and like the input, it is a reasonable assumption for a well
    // optimized real world system.
    R_c2c[0].raw_buffer()->dim[2].stride = 0;
    R_c2c[1].raw_buffer()->dim[2].stride = 0;

    double halide_t = benchmark(samples, 1, [&]() { bench_c2c.realize(R_c2c); }) * 1e6 / reps;
*/

/*
#ifdef WITH_FFTW
    std::vector<std::pair<float, float>> fftw_c1(W * H);
    std::vector<std::pair<float, float>> fftw_c2(W * H);
    fftwf_plan c2c_plan = fftwf_plan_dft_2d(W, H, (fftwf_complex *)&fftw_c1[0], (fftwf_complex *)&fftw_c2[0], FFTW_FORWARD, FFTW_EXHAUSTIVE);
    double fftw_t = benchmark(samples, reps, [&]() { fftwf_execute(c2c_plan); }) * 1e6;
#else
    double fftw_t = 0;
#endif
    printf("%12s %10.3f %10.2f %10.3f %10.2f %10.3g\n", // output
           "c2c",
           halide_t,
           5 * W * H * (log2(W) + log2(H)) / halide_t,
           fftw_t,
           5 * W * H * (log2(W) + log2(H)) / fftw_t,
           fftw_t / halide_t);
*/

    std::ofstream ofile;
    ofile.open(output_file, std::ios_base::app);

    double halide_t;

    for (int i = 0; i < NUM; i++) {

        int power = w-1;
        
        int p1 = rand() % power + 1; 
        int p2 = rand() % (power+1) + 1; 
        int p3 = rand() % (power+1) + 1; 
        int p4 = rand() % (power+1) + 1;
        int p5 = rand() % (power+1) + 1; 
        int p6 = rand() % (power+1) + 1;  

        int v1 = pow(2,p1);
        int v2 = pow(2,p2);
        int v3 = pow(2,p3);
        int v4 = pow(2,p4);
        int v5 = pow(2,p5);
        int v6 = pow(2,p6);

        if (GPU) {
            target = find_gpu_target();
            if (!target.has_gpu_feature()) {
                std::cout << "No GPU available" << i << std::endl;
            }

            std::cout << "GPU target: "  << target.to_string().c_str() << std::endl;
        }

        std::cout << "iteration: " << i << std::endl;

        Func r2c_in;
        // All reps read from the same input. See notes on c2c_in.
        r2c_in(x, y, rep) = re_in(x, y);
        Func bench_r2c = fft2d_r2c(r2c_in, W, H, target, fwd_desc, v1, v2, v3, v4, v5, v6);
        
        if (GPU) {
            bench_r2c.compile_jit(target);
        } else {
            bench_r2c.compile_to_lowered_stmt(output_file + ".r2c.html",
                    bench_r2c.infer_arguments(), HTML);
        }
        
        Realization R_r2c = bench_r2c.realize(W, H / 2 + 1, reps, target);
        // Write all reps to the same place in memory. See notes on R_c2c.
        R_r2c[0].raw_buffer()->dim[2].stride = 0;
        R_r2c[1].raw_buffer()->dim[2].stride = 0;

        halide_t = benchmark(samples, 1, [&]() { bench_r2c.realize(R_r2c); }) * 1e6 / reps;

        /*
        #ifdef WITH_FFTW
            std::vector<float> fftw_r(W * H);
            fftwf_plan r2c_plan = fftwf_plan_dft_r2c_2d(W, H, &fftw_r[0], (fftwf_complex *)&fftw_c1[0], FFTW_EXHAUSTIVE);
            // should delete double 
            double fftw_t = benchmark(samples, reps, [&]() { fftwf_execute(r2c_plan); }) * 1e6;
        #else
            double fftw_t = 0;

        #endif
        */

        /*
        printf("%12s %10.3f %10.2f %10.3f %10.2f %10.3g\n",
               "r2c",
               halide_t,
               2.5 * W * H * (log2(W) + log2(H)) / halide_t,
               fftw_t,
               2.5 * W * H * (log2(W) + log2(H)) / fftw_t,
               fftw_t / halide_t);
        */
        
        printf("%12s %10.3f \n",
               "r2c",
               halide_t
               );

        ofile << halide_t << "," << W << "," << v1 << "," << v2 << "," << v3 << "," << v4 << "," << v5 << "," << v6 << "," << '\n'; // 1000 times
    }

/*
    ComplexFunc c2r_in;
    // All reps read from the same input. See notes on c2c_in.
    c2r_in(x, y, rep) = {re_in(x, y), im_in(x, y)};
    Func bench_c2r = fft2d_c2r(c2r_in, W, H, target, inv_desc);
    bench_c2r.compile_to_lowered_stmt(output_dir + "c2r.html", bench_c2r.infer_arguments(), HTML);
    Realization R_c2r = bench_c2r.realize(W, H, reps, target);
    // Write all reps to the same place in memory. See notes on R_c2c.
    R_c2r[0].raw_buffer()->dim[2].stride = 0;

    halide_t = benchmark(samples, 1, [&]() { bench_c2r.realize(R_c2r); }) * 1e6 / reps;
*/
/*
#ifdef WITH_FFTW
    fftwf_plan c2r_plan = fftwf_plan_dft_c2r_2d(W, H, (fftwf_complex *)&fftw_c1[0], &fftw_r[0], FFTW_EXHAUSTIVE);
    fftw_t = benchmark(samples, reps, [&]() { fftwf_execute(c2r_plan); }) * 1e6;
#else
    fftw_t = 0;
#endif
    printf("%12s %10.3f %10.2f %10.3f %10.2f %10.3g\n",
           "c2r",
           halide_t,
           2.5 * W * H * (log2(W) + log2(H)) / halide_t,
           fftw_t,
           2.5 * W * H * (log2(W) + log2(H)) / fftw_t,
           fftw_t / halide_t);

#ifdef WITH_FFTW
    fftwf_destroy_plan(c2c_plan);
    fftwf_destroy_plan(r2c_plan);
    fftwf_destroy_plan(c2r_plan);
#endif
*/

    return 0;
}
