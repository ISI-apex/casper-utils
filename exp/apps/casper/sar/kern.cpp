
#include "PlatformData.h"
#include "ImgPlane.h"
#include "ip.h"
#include "dft.h"

#include <cnpy.h>
#include <halide_image_io.h>

#include <chrono>
#include <iostream>
#include <complex>
#include <cstdint>

using namespace std;
using namespace std::chrono;

extern "C" {

#if 0
void backprojection_dummy(
        float *phs_dat_buf, float *phs_dat, int phs_offset,
		int phs_n0, int phs_s_n0,
		int phs_n1, int phs_s_n1,
		int phs_n2, int phs_s_n2,
        float *k_r_dat_buf, float *k_r_dat, int k_r_offset,
		int k_r_n, int k_r_s_n,
        int64_t taylor,
        int64_t N_fft,
        double delta_r,
        double *u_dat_buf, double *u_dat, int u_offset,
		int u_n, int u_s_n,
        double *v_dat_buf, double *v_dat, int v_offset,
		int v_n, int v_s_n,
        float *pos_dat_buf, float *pos_dat, int pos_offset,
		int pos_n0, int pos_s_n0,
		int pos_n1, int pos_s_n1,
        double *r_dat_buf, double *r_dat, int r_offset,
		int r_n0, int r_s_n0,
		int r_n1, int r_s_n1,
        double *bp_dat_buf, double *bp_dat, int bp_offset,
		int bp_n0, int bp_s_n0,
		int bp_n1, int bp_s_n1,
		int bp_n2, int bp_s_n2
        )
{
}

void post_bp(
        double *bp_dat_buf, double *bp_dat, int bp_offset,
		int bp_n0, int bp_s_n0,
		int bp_n1, int bp_s_n1,
		int bp_n2, int bp_s_n2
        )
{
}

void ip_pixel_locs_dummy(
        double *u_dat_buf, double *u_dat, int u_offset,
		int u_n, int u_s_n,
        double *v_dat_buf, double *v_dat, int v_offset,
		int v_n, int v_s_n,
        double *u_hat_dat_buf, double *u_hat_dat, int u_hat_offset,
		int u_hat_n, int u_hat_s_n,
        double *v_hat_dat_buf, double *v_hat_dat, int v_hat_offset,
		int v_hat_n, int v_hat_s_n,
        double *r_dat_buf, double *r_dat, int r_offset,
		int r_n0, int r_s_n0,
		int r_n1, int r_s_n1
        )
{
}
#endif

#if 1
void load(
        double *d_u, double *d_v,
        float *n_hat_dat_buf, float *n_hat_dat, int n_hat_offset,
		int n_hat_n, int n_hat_s_n,
        float *k_r_dat_buf, float *k_r_dat, int k_r_offset,
		int k_r_n, int k_r_s_n,
        float *R_c_dat_buf, float *R_c_dat, int R_c_offset,
		int R_c_n, int R_c_s_n,
        float *pos_dat_buf, float *pos_dat, int pos_offset,
		int pos_n0, int pos_s_n0,
		int pos_n1, int pos_s_n1,
        float *phs_dat_buf, float *phs_dat, int phs_offset,
		int phs_n0, int phs_s_n0,
		int phs_n1, int phs_s_n1,
		int phs_n2, int phs_s_n2
                ) {
#else
void load(double *d_u, double *d_v) {
#endif

    // TODO: duplicated in main
    string platform_dir = "input_data_dir"; // see CMakeLists.txt

    auto start = high_resolution_clock::now();
    // TODO: remove filling of Halide buffers from this loading procedure
    PlatformData pd = platform_load(platform_dir);
    auto stop = high_resolution_clock::now();
    cout << "Loaded platform data in "
         << duration_cast<milliseconds>(stop - start).count() << " ms" << endl;
    cout << "Number of pulses: " << pd.npulses << endl;
    cout << "Pulse sample size: " << pd.nsamples << endl;

    // TODO: duplicated in main
    int nu;
    int nv;
    bool upsample = true; // TODO
    if (upsample) {
        nu = ip_upsample(pd.nsamples);
        nv = ip_upsample(pd.npulses);
    } else {
        nu = pd.nsamples;
        nv = pd.npulses;
    }

    *d_u = ip_du(pd.delta_r, RES_FACTOR, pd.nsamples, nu);
    *d_v = ip_dv(ASPECT, *d_u);
    cout << "ptr: d_u=" << d_u << "d_v=" << d_v << std::endl;
    cout << "set: d_u=" << *d_u << "d_v=" << *d_v << std::endl;

    const float *n_hat = pd.n_hat.has_value() ? pd.n_hat.value().begin() : &N_HAT[0];
    printf("n_hat_dat: %d, %d, %d \n", n_hat_offset, n_hat_n, n_hat_s_n);
    for (int i = 0; i < 3 /* TODO */; ++i) {
        n_hat_dat[i] = n_hat[i]; /* TODO: offest, strides etc */
    }

    cnpy::NpyArray npy_k_r = cnpy::npy_load(platform_dir + "/k_r.npy");
    if (npy_k_r.shape.size() != 1 || npy_k_r.shape[0] != pd.nsamples) {
        throw runtime_error("Bad shape: k_r");
    }
    if (npy_k_r.word_size == sizeof(float)) {
        memcpy(k_r_dat, npy_k_r.data<float>(), npy_k_r.num_bytes());
    } else if (npy_k_r.word_size == sizeof(double)) {
        cout << "PlatformData: downcasting k_r from double to float" << endl;
        const double *src = npy_k_r.data<double>();
        float *dest = k_r_dat;
        for (size_t i = 0; i < npy_k_r.num_vals; i++) {
            dest[i] = (float)src[i];
        }
    } else {
        throw runtime_error("Bad word size: k_r");
    }

    cnpy::NpyArray npy_R_c = cnpy::npy_load(platform_dir + "/R_c.npy");
    if (npy_R_c.shape.size() != 1 || npy_R_c.shape[0] != 3) {
        throw runtime_error("Bad shape: R_c");
    }
    if (npy_R_c.word_size == sizeof(float)) {
        memcpy(R_c_dat, npy_R_c.data<float>(), npy_R_c.num_bytes());
    } else if (npy_R_c.word_size == sizeof(double)) {
        cout << "PlatformData: downcasting R_c from double to float" << endl;
        const double *src = npy_R_c.data<double>();
        float *dest = R_c_dat;
        for (size_t i = 0; i < npy_R_c.num_vals; i++) {
            dest[i] = (float)src[i];
        }
    } else {
        throw runtime_error("Bad word size: R_c");
    }

    cnpy::NpyArray npy_pos = cnpy::npy_load(platform_dir + "/pos.npy");
    if (npy_pos.shape.size() != 2 || npy_pos.shape[0] != pd.npulses || npy_pos.shape[1] != 3) {
        throw runtime_error("Bad shape: pos");
    }
    if (npy_pos.word_size == sizeof(float)) {
        memcpy(pos_dat, npy_pos.data<float>(), npy_pos.num_bytes());
    } else if (npy_pos.word_size == sizeof(double)) {
        cout << "PlatformData: downcasting pos from double to float" << endl;
        const double *src = npy_pos.data<double>();
        float *dest = pos_dat;
        for (size_t i = 0; i < npy_pos.num_vals; i++) {
            dest[i] = (float)src[i];
        }
    } else {
        throw runtime_error("Bad word size: pos");
    }

    cnpy::NpyArray npy_phs = cnpy::npy_load(platform_dir + "/phs.npy");
    if (npy_phs.shape.size() != 2 || npy_phs.shape[0] != pd.npulses || npy_phs.shape[1] != pd.nsamples) {
        throw runtime_error("Bad shape: phs");
    }
    if (npy_phs.word_size == sizeof(complex<float>)) {
        memcpy(phs_dat, reinterpret_cast<float *>(npy_phs.data<complex<float>>()), npy_phs.num_bytes());
    } else if (npy_phs.word_size == sizeof(complex<double>)) {
        cout << "PlatformData: downcasting phs from complex<double> to complex<float>" << endl;
        const complex<double> *src = npy_phs.data<complex<double>>();
        float *dest = phs_dat;
        for (size_t i = 0; i < npy_phs.num_vals; i++) {
            dest[i * 2] = (float)src[i].real();
            dest[(i * 2) + 1] = (float)src[i].imag();
        }
    } else {
        throw runtime_error("Bad word size: phs");
    }

    cout << "X length: " << nu << endl;
    cout << "Y length: " << nv << endl;

    // Compute FFT width (power of 2)
    int N_fft = static_cast<int>(pow(2, static_cast<int>(log2(pd.nsamples * upsample)) + 1));

}

void init_fft(int N_fft) {
    // FFTW: init shared context
    dft_init_fftw(static_cast<size_t>(N_fft));

}

void destroy_fft() {
    // FFTW: clean up shared context
    dft_destroy_fftw();
}

void save(uint8_t *img_dat_buf, uint8_t *img_dat,
                int img_offset, int img_n, int img_m,
                int img_s_n, int img_s_m) {
    // For the interface of Halide::Tools, reconstruct halide_buffer_t from
    // args and convert to Halide::Buffer.
    const int dims = 2;
    halide_dimension_t dim[dims] = {
        halide_dimension_t{0, img_n, img_s_n},
        halide_dimension_t{0, img_m, img_s_m},
    };
    halide_buffer_t img_hb {

        // TODO: not tracked in casper across memref types
        .device = 0,
        .device_interface = NULL,
        .host = img_dat_buf,
        .flags = 0,

        // from task interface (dat type in func args above)
        .type =  halide_type_t{halide_type_uint, /* bits */ 8, /* lanes*/ 1},
        .dimensions = dims,
        .dim = dim,

        .padding = NULL,
    };
    Halide::Buffer img_b{img_hb};

    std::string output_png{"output_image.png"};
    Halide::Tools::convert_and_save_image(img_b, output_png);
}

#if 1
void load_test_ptr(double *d_u, double *d_v) {
    cout << "get: d_u=" << *d_u << "d_v=" << *d_v << std::endl;
}

void load_test(double d_u, double d_v) {
    cout << "by value: d_u=" << d_u << "d_v=" << d_v << std::endl;
}
#endif

} // extern
