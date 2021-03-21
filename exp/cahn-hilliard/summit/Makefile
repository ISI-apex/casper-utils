ACCOUNT?=csc436

include ../Makefile.paths
include $(PTOOLS_DIR)/clusters/olcf-summit/make/Makefile

all: ch-test

# Must be after the first target which will be the default target
include ../Makefile

DATS_ch-test=\
	ch_mesh-32_ranks-2_tpn-1.csv \

$(call target-set,ch-test,$(DATS_ch-test))

DATS_ch-4k=\
	ch_mesh-4096_ranks-42_tpn-42.csv \
	ch_mesh-4096_ranks-84_tpn-42.csv \
	ch_mesh-4096_ranks-168_tpn-42.csv \
	ch_mesh-4096_ranks-346_tpn-42.csv \
	ch_mesh-4096_ranks-692_tpn-42.csv \
	ch_mesh-4096_ranks-1384_tpn-42.csv \
	ch_mesh-4096_ranks-2768_tpn-42.csv \
	ch_mesh-4096_ranks-5536_tpn-42.csv \

$(call target-set,ch-4k,$(DATS_ch-4k))

DATS_ch-8k=\
	ch_mesh-8192_ranks-42_tpn-42.csv \
	ch_mesh-8192_ranks-84_tpn-42.csv \
	ch_mesh-8192_ranks-168_tpn-42.csv \
	ch_mesh-8192_ranks-346_tpn-42.csv \
	ch_mesh-8192_ranks-692_tpn-42.csv \
	ch_mesh-8192_ranks-1384_tpn-42.csv \
	ch_mesh-8192_ranks-2768_tpn-42.csv \

$(call target-set,ch-8k,$(DATS_ch-8k))

DATS_ch-16k=\
	ch_mesh-16384_ranks-2768_tpn-24.csv \
	ch_mesh-16384_ranks-5536_tpn-24.csv \
	ch_mesh-16384_ranks-11072_tpn-40.csv \

$(call target-set,ch-16k,$(DATS_ch-16k))

DATS_ch-tpn=\
	ch_mesh-1024_ranks-64_tpn-8-node.csv \
	ch_mesh-1024_ranks-64_tpn-16-node.csv \
	ch_mesh-1024_ranks-64_tpn-32-node.csv \
	ch_mesh-1024_ranks-64_tpn-48-node.csv \
	ch_mesh-1024_ranks-64_tpn-64-node.csv \

$(call target-set,ch-tpn,$(DATS_ch-tpn))

$(call target-set,ch-scaling,$(DATS_ch-4k) $(DATS_ch-8k))
