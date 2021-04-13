CLUSTER=olcf-summit
ACCOUNT?=csc436
MAP_BY?=rankfile

PTOOLS_MAKE:=${EPREFIX}/usr/lib/prefix-tools/make

include $(PTOOLS_MAKE)/Makefile.job
include $(PTOOLS_MAKE)/Makefile

all: ch-test

# Must be after the first target which will be the default target
include ../Makefile

DATS_ch-test=\
	ch_mesh-32_ranks-2_tpn-1.csv \

$(call target-set,ch-test,$(DATS_ch-test))

DATS_ch-test-2=\
	ch_mesh-512_ranks-42_tpn-42_steps-1.csv \
	ch_mesh-512_ranks-84_tpn-42_steps-1.csv \

$(call target-set,ch-test-2,$(DATS_ch-test-2))

DATS_ch-2k-steps-25=\
	ch_mesh-2048_ranks-42_tpn-42_steps-25.csv \
	ch_mesh-2048_ranks-84_tpn-42_steps-25.csv \
	ch_mesh-2048_ranks-168_tpn-42_steps-25.csv \
	ch_mesh-2048_ranks-346_tpn-42_steps-25.csv \
	ch_mesh-2048_ranks-692_tpn-42_steps-25.csv \

$(call target-set,ch-2k-steps-25,$(DATS_ch-2k-steps-25))

DATS_ch-4k-steps-25=\
	ch_mesh-4096_ranks-42_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-84_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-168_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-346_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-692_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-1384_tpn-42_steps-25.csv \

$(call target-set,ch-4k-steps-25,$(DATS_ch-4k-steps-25))

DATS_ch-4k-steps-25-pow2=\
	ch_mesh-4096_ranks-32_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-64_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-128_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-256_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-512_tpn-42_steps-25.csv \
	ch_mesh-4096_ranks-1024_tpn-42_steps-25.csv \

$(call target-set,ch-4k-steps-25-pow2,$(DATS_ch-4k-steps-25-pow2))

DATS_ch-4k-steps-50=\
	ch_mesh-4096_ranks-42_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-84_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-168_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-346_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-692_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-1384_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-2768_tpn-42_steps-50.csv \
	ch_mesh-4096_ranks-5536_tpn-42_steps-50.csv \

$(call target-set,ch-4k-steps-50,$(DATS_ch-4k-steps-50))

DATS_ch-4k-steps-100=\
	ch_mesh-4096_ranks-42_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-84_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-168_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-346_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-692_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-1384_tpn-42_steps-100.csv \

$(call target-set,ch-4k-steps-100,$(DATS_ch-4k-steps-100))

DATS_ch-4k-steps-100-pow2=\
	ch_mesh-4096_ranks-32_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-64_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-128_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-256_tpn-42_steps-100.csv \
	ch_mesh-4096_ranks-512_tpn-42_steps-100.csv \

#ch_mesh-4096_ranks-1024_tpn-42_steps-100.csv \

$(call target-set,ch-4k-steps-100-pow2,$(DATS_ch-4k-steps-100-pow2))

DATS_ch-4k=\
	ch_mesh-4096_ranks-42_tpn-42_steps-1.csv \
	ch_mesh-4096_ranks-84_tpn-42_steps-1.csv \
	ch_mesh-4096_ranks-168_tpn-42_steps-1.csv \
	ch_mesh-4096_ranks-346_tpn-42_steps-1.csv \
	ch_mesh-4096_ranks-692_tpn-42_steps-1.csv \
	ch_mesh-4096_ranks-1384_tpn-42_steps-1.csv \

# bathtub botton is around ranks=1384 for 4Kx4K mesh with steps=1
#ch_mesh-4096_ranks-2768_tpn-42_steps-1.csv \
#ch_mesh-4096_ranks-5536_tpn-42_steps-1.csv \

$(call target-set,ch-4k,$(DATS_ch-4k))

DATS_ch-8k=\
	ch_mesh-8192_ranks-42_tpn-42_steps-1.csv \
	ch_mesh-8192_ranks-84_tpn-42_steps-1.csv \
	ch_mesh-8192_ranks-168_tpn-42_steps-1.csv \
	ch_mesh-8192_ranks-346_tpn-42_steps-1.csv \
	ch_mesh-8192_ranks-692_tpn-42_steps-1.csv \
	ch_mesh-8192_ranks-1384_tpn-42_steps-1.csv \
	ch_mesh-8192_ranks-2768_tpn-42_steps-1.csv \

$(call target-set,ch-8k,$(DATS_ch-8k))

DATS_ch-8k-steps-25=\
	ch_mesh-8192_ranks-42_tpn-42_steps-25.csv \
	ch_mesh-8192_ranks-84_tpn-42_steps-25.csv \
	ch_mesh-8192_ranks-168_tpn-42_steps-25.csv \
	ch_mesh-8192_ranks-346_tpn-42_steps-25.csv \
	ch_mesh-8192_ranks-692_tpn-42_steps-25.csv \
	ch_mesh-8192_ranks-1384_tpn-42_steps-25.csv \
	ch_mesh-8192_ranks-2768_tpn-42_steps-25.csv \

$(call target-set,ch-8k-steps-25,$(DATS_ch-8k-steps-25))

$(call target-set,ch-4k-8k,$(DATS_ch-4k) $(DATS_ch-8k))

DATS_ch-16k=\
	ch_mesh-16384_ranks-2768_tpn-24.csv \
	ch_mesh-16384_ranks-5536_tpn-24.csv \
	ch_mesh-16384_ranks-11072_tpn-40.csv \

$(call target-set,ch-16k,$(DATS_ch-16k))

DATS_ch-2k-omp=\
	ch_mesh-2048_ranks-32_tpn-42_steps-25_omp-1.csv \
	ch_mesh-2048_ranks-16_tpn-42_steps-25_omp-2.csv \
	ch_mesh-2048_ranks-8_tpn-42_steps-25_omp-4.csv \
	ch_mesh-2048_ranks-4_tpn-42_steps-25_omp-8.csv \
	ch_mesh-2048_ranks-2_tpn-42_steps-25_omp-16.csv \
	ch_mesh-2048_ranks-1_tpn-42_steps-25_omp-32.csv \

$(call target-set,ch-2k-omp,$(DATS_ch-2k-omp))

DATS_ch-tpn=\
	ch_mesh-1024_ranks-64_tpn-8-node.csv \
	ch_mesh-1024_ranks-64_tpn-16-node.csv \
	ch_mesh-1024_ranks-64_tpn-32-node.csv \
	ch_mesh-1024_ranks-64_tpn-48-node.csv \
	ch_mesh-1024_ranks-64_tpn-64-node.csv \

$(call target-set,ch-tpn,$(DATS_ch-tpn))

$(call target-set,ch-scaling,$(DATS_ch-4k) $(DATS_ch-8k))
