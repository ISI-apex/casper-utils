#include "ip.h"

#include <casper.h>
#include <cnpy.h>

#include <vector>

using namespace cac;

namespace {

} // namespace anon

int main(int argc, char **argv) {
	Options opts; // metaprogram can add custom options
	opts.parseOrExit(argc, argv);

        std::string platform_dir = "input_data_dir"; // see CMakeLists.txt
        int upsample = 2;
        int nu, nv;

	TaskGraph tg("sarbp"); // must match target name in CMake script

        cnpy::NpyArray npy_nsamples = cnpy::npy_load(platform_dir + "/nsamples.npy");
        int nsamples;
        if (npy_nsamples.word_size == sizeof(int)) {
            nsamples = *npy_nsamples.data<int>();
        } else if (npy_nsamples.word_size == sizeof(int64_t)) {
            // no need to warn of downcasting
            nsamples = (int)*npy_nsamples.data<int64_t>();
        } else {
            throw std::runtime_error("Bad word size: nsamples");
        }

        cnpy::NpyArray npy_npulses = cnpy::npy_load(platform_dir + "/npulses.npy");
        int npulses;
        if (npy_npulses.word_size == sizeof(int)) {
            npulses = *npy_npulses.data<int>();
        } else if (npy_npulses.word_size == sizeof(int64_t)) {
            // no need to warn of downcasting
            npulses = (int)*npy_npulses.data<int64_t>();
        } else {
            throw std::runtime_error("Bad word size: npulses");
        }

        cnpy::NpyArray npy_delta_r = cnpy::npy_load(platform_dir + "/delta_r.npy");
        if (npy_delta_r.word_size != sizeof(double)) {
            throw std::runtime_error("Bad word size: delta_r");
        }
        double delta_r_p = *npy_delta_r.data<double>();

        if (upsample) {
            nu = ip_upsample(nsamples);
            nv = ip_upsample(npulses);
        } else {
            nu = nsamples;
            nv = npulses;
        }

        // TODO: is there a way to get sizes without loading the data?

#if 1
        // Compute FFT width (power of 2)
        int N_fft_val = static_cast<int>(pow(2,
                    static_cast<int>(log2(nsamples * upsample)) + 1));
	IntScalar *N_fft = &tg.createIntScalar(64, N_fft_val);

#endif
	//DoubleScalar *res_factor = &tg.createDoubleScalar(RES_FACTOR);
        // TODO: constructor without a value
	DoubleScalar *d_u = &tg.createDoubleScalar(0);
	DoubleScalar *d_v = &tg.createDoubleScalar(0);

        PtrScalar *d_u_p = &tg.createPtrScalar(d_u);
        PtrScalar *d_v_p = &tg.createPtrScalar(d_v);

        Dat *n_hat = &tg.createFloatDat(1, {3}); // float, d=1
        Dat *k_r = &tg.createFloatDat(1, {nsamples}); // float
        Dat *R_c = &tg.createFloatDat(1, {3}); // float, d=1
        Dat *pos = &tg.createFloatDat(2, {3, npulses}); // float, dim 2
        Dat *phs = &tg.createFloatDat(3, {2, nsamples, npulses}); // float, d=3
        Task& task_load = tg.createTask(CKernel("load"), {d_u_p, d_v_p, n_hat, k_r, R_c, pos, phs});
#if 1
        Task& task_load_test_ptr = tg.createTask(CKernel("load_test_ptr"),
                {d_u_p, d_v_p}, {&task_load});
        Task& task_load_test = tg.createTask(CKernel("load_test"), {d_u, d_v},
                        {&task_load});
#endif

#if 1
	IntScalar *s_nu = &tg.createIntScalar(64, nu);
	IntScalar *s_nv = &tg.createIntScalar(64, nv);

	Dat *u = &tg.createDoubleDat(1, {nu});
	Dat *v = &tg.createDoubleDat(1, {nv});
	Dat *k_u = &tg.createDoubleDat(1, {nu});
	Dat *k_v = &tg.createDoubleDat(1, {nv});

        Task& task_ip_uv_u = tg.createTask(HalideKernel("ip_uv"),
                {s_nu, d_u, u}, {&task_load});
        Task& task_ip_uv_v = tg.createTask(HalideKernel("ip_uv"),
                {s_nv, d_v, v}, {&task_load});
        Task& task_ip_k_u = tg.createTask(HalideKernel("ip_k"),
                {s_nu, d_u, k_u}, {&task_load});
        Task& task_ip_k_v = tg.createTask(HalideKernel("ip_k"),
                {s_nv, d_v, k_v}, {&task_load});

	Dat *u_hat = &tg.createDoubleDat(1, {3});
	Dat *v_hat = &tg.createDoubleDat(1, {3});

        Task& task_ip_v_hat = tg.createTask(HalideKernel("ip_v_hat"),
                {n_hat, R_c, v_hat}, {&task_load});
        Task& task_ip_u_hat = tg.createTask(HalideKernel("ip_u_hat"),
                {v_hat, n_hat, u_hat}, {&task_ip_v_hat});

	Dat *r = &tg.createDoubleDat(2, {nu*nv, 3}); // double, dim 2
#if 1
        Task& task_ip_pixel_locs = tg.createTask(HalideKernel("ip_pixel_locs"),
                {u, v, u_hat, v_hat, r},
                {&task_ip_u_hat, &task_ip_uv_u, &task_ip_uv_v});
#else
	Task& task_ip_pixel_locs = tg.createTask(CKernel("ip_pixel_locs_dummy"),
                {u, v, u_hat, v_hat, r},
                {&task_ip_u_hat, &task_ip_uv_u, &task_ip_uv_v});
#endif

        Task& task_init_fft = tg.createTask(CKernel("init_fft"), {N_fft},
			{&task_ip_pixel_locs});

#endif

	IntScalar *taylor = &tg.createIntScalar(64, 17);
	DoubleScalar *delta_r = &tg.createDoubleScalar(delta_r_p);
	Dat *bp = &tg.createDoubleDat(3, {2, nu, nv});

#if 1
	Task& task_bp = tg.createTask(HalideKernel("backprojection"),
                        {phs, k_r, taylor, N_fft, delta_r, u, v, pos, r, bp},
			{&task_init_fft});
#else
	Task& task_bp = tg.createTask(CKernel("backprojection_dummy"),
                        {phs, k_r, taylor, N_fft, delta_r, u, v, pos, r, bp},
			{&task_init_fft});
#endif

#if 0
	Task& task_post_bp = tg.createTask(CKernel("post_bp"),
                        {bp}, {&task_bp});
#endif

#if 1
        Task& task_destroy_fft = tg.createTask(CKernel("destroy_fft"), {},
		{&task_bp});
#endif

#if 1
	Dat *bp_dB = &tg.createDoubleDat(2, {nu, nv});
	Task& task_bp_dB = tg.createTask(HalideKernel("img_output_to_dB"),
                        {bp, bp_dB},
			{&task_destroy_fft});

#if 1
	Dat *bp_u8 = &tg.createIntDat(8, 2, {nu, nv});
	DoubleScalar *dB_min = &tg.createDoubleScalar(-30.0);
	DoubleScalar *dB_max = &tg.createDoubleScalar(0.0);
	Task& task_bp_u8 = tg.createTask(HalideKernel("img_output_u8"),
                        {bp_dB, dB_min, dB_max, bp_u8},
			{&task_bp_dB});
#endif
#endif

        Task& task_save = tg.createTask(CKernel("save"), {bp_u8},
		{&task_bp_u8});

	return tryCompile(tg, opts);
}
