ifeq ($(filter %.pdf %.svg,$(MAKECMDGOALS)),)
ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif # EPREFIX
else
EPREFIX_REQUIRED=
endif

ACCOUNT?=CASPER

# Could point to installation within the prefix, or within casper-utils (the
# latter is convenient for development, but the former is ensures that the
# prefix is self-sufficient, i.e. does not depend on any other repos)
#PTOOLS_DIR:=${EPREFIX}/usr/share/prefix-tools
PTOOLS_DIR:=../../../prefix-tools

include $(PTOOLS_DIR)/clusters/anl-theta/make/Makefile

# Very important to set OMP threads, otherwise it spawns way to many, and the
# default also varies by rank count -- the default is a mess.
OMP_NUM_THREADS?=1

all: ch-core-small ch-core-large

# Must be after the first target which will be the default target
include ../Makefile

DATS_ch-test=\
	ch_mesh-32_ranks-2_tpn-1.csv \

$(call target-set,ch-test,$(DATS_ch-test))

DATS_ch-node=\
	ch_mesh-32_ranks-2_tpn-1.csv \
	ch_mesh-96_ranks-2_tpn-1.csv \

$(call target-set,ch-node,$(DATS_ch-node))

# Note: this is not the dynamic $(call tgt-tasks-per-node) that is derived
# for each target from the target's name; here we are defining targets.
TPN:=64

# Fits on 8 nodes of debug q in parallel
DATS_ch-core-tiny=\
	ch_mesh-128_ranks-1_tpn-$(TPN).csv \
	ch_mesh-128_ranks-2_tpn-$(TPN).csv \
	ch_mesh-128_ranks-4_tpn-$(TPN).csv \
	ch_mesh-128_ranks-8_tpn-$(TPN).csv \
	ch_mesh-128_ranks-16_tpn-$(TPN).csv \
	ch_mesh-128_ranks-32_tpn-$(TPN).csv \
	ch_mesh-128_ranks-48_tpn-$(TPN).csv \
	ch_mesh-128_ranks-64_tpn-$(TPN).csv \

$(call target-set,ch-core-tiny,$(DATS_ch-core-tiny))

#ch_mesh-64_ranks-1_tpn-$(TPN).csv
DATS_ch-mem-with-size=\
	ch_mesh-64_ranks-2_tpn-$(TPN).csv \
	ch_mesh-64_ranks-4_tpn-$(TPN).csv \
	ch_mesh-128_ranks-1_tpn-$(TPN).csv \
	ch_mesh-128_ranks-2_tpn-$(TPN).csv \
	ch_mesh-128_ranks-4_tpn-$(TPN).csv \
	ch_mesh-256_ranks-1_tpn-$(TPN).csv \
	ch_mesh-256_ranks-2_tpn-$(TPN).csv \
	ch_mesh-256_ranks-4_tpn-$(TPN).csv \

#	ch_mesh-512_ranks-1_tpn-$(TPN).csv \
#	ch_mesh-1024_ranks-1_tpn-$(TPN).csv \

#	ch_mesh-2048_ranks-1_tpn-$(TPN).csv \
#	ch_mesh-4096_ranks-1_tpn-$(TPN).csv \
#	ch_mesh-8192_ranks-1_tpn-$(TPN).csv \
#	ch_mesh-16384_ranks-1_tpn-$(TPN).csv \

#	ch_mesh-128_ranks-64_tpn-$(TPN).csv \
#	ch_mesh-256_ranks-64_tpn-$(TPN).csv \
#	ch_mesh-512_ranks-64_tpn-$(TPN).csv \
#	ch_mesh-1024_ranks-64_tpn-$(TPN).csv \

$(call target-set,ch-mem-with-size,$(DATS_ch-mem-with-size))

DATS_ch-mem-with-ranks-512=\
	ch_mesh-512_ranks-1_tpn-$(TPN).csv \
	ch_mesh-512_ranks-2_tpn-$(TPN).csv \
	ch_mesh-512_ranks-4_tpn-$(TPN).csv \
	ch_mesh-512_ranks-8_tpn-$(TPN).csv \
	ch_mesh-512_ranks-16_tpn-$(TPN).csv \
	ch_mesh-512_ranks-32_tpn-$(TPN).csv \
	ch_mesh-512_ranks-64_tpn-$(TPN).csv \

$(call target-set,ch-mem-with-ranks-512,$(DATS_ch-mem-with-ranks-512))

DATS_ch-mem-with-ranks-1024=\
	ch_mesh-1024_ranks-1_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-2_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-4_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-8_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-16_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-32_tpn-$(TPN).csv \


#	ch_mesh-1024_ranks-64_tpn-$(TPN).csv \

$(call target-set,ch-mem-with-ranks-1024,$(DATS_ch-mem-with-ranks-1024))

DATS_ch-mem-with-ranks-2048=\
	ch_mesh-2048_ranks-1_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-2_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-4_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-8_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-16_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-32_tpn-$(TPN).csv \

#	ch_mesh-2048_ranks-64_tpn-$(TPN).csv \

$(call target-set,ch-mem-with-ranks-2048,$(DATS_ch-mem-with-ranks-2048))

DATS_ch-mem-with-size-ranks-1=\
	ch_mesh-128_ranks-1_tpn-$(TPN).csv \
	ch_mesh-256_ranks-1_tpn-$(TPN).csv \
	ch_mesh-512_ranks-1_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-1_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-1_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-1_tpn-$(TPN).csv \
	ch_mesh-8192_ranks-1_tpn-$(TPN).csv \
	ch_mesh-16384_ranks-1_tpn-$(TPN).csv \

$(call target-set,ch-mem-with-size-ranks-1,$(DATS_ch-mem-with-size-ranks-1))

#DATS_ch-mem-with-size-ranks-2=\
#	ch_mesh-128_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-256_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-512_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-1024_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-2048_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-4096_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-8192_ranks-2_tpn-$(TPN).csv \
#	ch_mesh-16384_ranks-2_tpn-$(TPN).csv \
#
#$(call target-set,ch-mem-with-size-ranks-2,$(DATS_ch-mem-with-size-ranks-2))

DATS_ch-scaling=\
	ch_mesh-8192_ranks-512_tpn-8.csv \
	ch_mesh-8192_ranks-1024_tpn-16.csv \
	ch_mesh-8192_ranks-1536_tpn-16.csv \
	ch_mesh-8192_ranks-2048_tpn-16.csv \

$(call target-set,ch-scaling,$(DATS_ch-scaling))

DATS_ch-memlim2=\
	ch_mesh-16384_ranks-512_tpn-24_steps-mesh-setup.csv \
	ch_mesh-16384_ranks-512_tpn-16_steps-mesh-setup.csv \
	ch_mesh-16384_ranks-512_tpn-8_steps-mesh-setup.csv \
	ch_mesh-4096_ranks-1024_tpn-64.csv \
	ch_mesh-4096_ranks-2048_tpn-64.csv \
	ch_mesh-8192_ranks-1024_tpn-24.csv \
	ch_mesh-8192_ranks-2048_tpn-24.csv \

$(call target-set,ch-memlim2,$(DATS_ch-memlim2))

DATS_ch-memlim3=\
	ch_mesh-12288_ranks-512_tpn-16_steps-mesh-setup.csv \
	ch_mesh-12288_ranks-512_tpn-8_steps-mesh-setup.csv \
	ch_mesh-4096_ranks-1024_tpn-48.csv \
	ch_mesh-4096_ranks-2048_tpn-48.csv \
	ch_mesh-8192_ranks-4096_tpn-24.csv \

#	ch_mesh-8192_ranks-8192_tpn-24.csv \
#	ch_mesh-4096_ranks-1024_tpn-32.csv \
#	ch_mesh-4096_ranks-2048_tpn-32.csv \

$(call target-set,ch-memlim3,$(DATS_ch-memlim3))

DATS_ch-memlim4=\
	ch_mesh-12288_ranks-4096_tpn-8.csv \

$(call target-set,ch-memlim4,$(DATS_ch-memlim4))

DATS_ch-memlim5=\
	ch_mesh-8192_ranks-4096_tpn-24.csv \
	ch_mesh-8192_ranks-8192_tpn-24.csv \

$(call target-set,ch-memlim5,$(DATS_ch-memlim5))

DATS_ch-memlim5-1=\
	ch_mesh-8192_ranks-3192_tpn-24.csv \

$(call target-set,ch-memlim5-1,$(DATS_ch-memlim5-1))

DATS_ch-memlim6=\
	ch_mesh-8192_ranks-4096_tpn-24.csv \

$(call target-set,ch-memlim6,$(DATS_ch-memlim6))

DATS_ch-memlim7=\
	ch_mesh-8192_ranks-8192_tpn-24.csv \

$(call target-set,ch-memlim7,$(DATS_ch-memlim7))

DATS_ch-memlim8=\
	ch_mesh-10000_ranks-512_tpn-8_steps-mesh-setup.csv \
	ch_mesh-9000_ranks-512_tpn-8_steps-mesh-setup.csv \
	ch_mesh-4096_ranks-512_tpn-48.csv \
	ch_mesh-4096_ranks-4096_tpn-48.csv \
	ch_mesh-8192_ranks-512_tpn-24.csv \
	ch_mesh-8192_ranks-1536_tpn-24.csv \

$(call target-set,ch-memlim8,$(DATS_ch-memlim8))

DATS_ch-memlim9=\
	ch_mesh-9000_ranks-1024_tpn-24.csv \
	ch_mesh-9000_ranks-1536_tpn-24.csv \
	ch_mesh-9000_ranks-2048_tpn-24.csv \
	ch_mesh-9000_ranks-3192_tpn-24.csv \

$(call target-set,ch-memlim9,$(DATS_ch-memlim9))

DATS_ch-memlim-dbg=\
	ch_mesh-8192_ranks-2048_tpn-16.csv \

$(call target-set,ch-memlim-dbg,$(DATS_ch-memlim-dbg))

DATS_ch-mem=\
	ch_mesh-256_ranks-16_tpn-$(TPN).csv \
	ch_mesh-128_ranks-32_tpn-$(TPN).csv \

$(call target-set,ch-mem,$(DATS_ch-mem))

# Together with ch-core-tiny, < 1 hr total (fits on dbg q in sequence)
DATS_ch-core-small=\
	ch_mesh-96_ranks-4_tpn-$(TPN).csv \
	ch_mesh-96_ranks-8_tpn-$(TPN).csv \
	ch_mesh-96_ranks-16_tpn-$(TPN).csv \
	ch_mesh-96_ranks-32_tpn-$(TPN).csv \
	ch_mesh-96_ranks-64_tpn-$(TPN).csv \
	ch_mesh-256_ranks-32_tpn-$(TPN).csv \
	ch_mesh-256_ranks-48_tpn-$(TPN).csv \
	ch_mesh-256_ranks-64_tpn-$(TPN).csv \
	ch_mesh-512_ranks-48_tpn-$(TPN).csv \
	ch_mesh-512_ranks-64_tpn-$(TPN).csv \
	ch_mesh-512_ranks-96_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-96_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-128_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-192_tpn-$(TPN).csv \

$(call target-set,ch-core-small,$(DATS_ch-core-small))

# hypothesis: < 1 hr each (so can run via the /split target on debug q)
DATS_ch-core-large=\
	ch_mesh-2048_ranks-128_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-192_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-256_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-320_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-384_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-512_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-128_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-192_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-256_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-320_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-384_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-448_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-512_tpn-$(TPN).csv \

$(call target-set,ch-core-large,$(DATS_ch-core-large))

$(call target-set,ch-core-8nodes,\
  $(DATS_ch-core-small) $(DATS_ch-core-large))

DATS_ch-core-jumbo=\
	ch_mesh-2048_ranks-768_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-768_tpn-$(TPN).csv \

# segfault
#	ch_mesh-2048_ranks-1024_tpn-$(TPN).csv \
#	ch_mesh-4096_ranks-1024_tpn-$(TPN).csv \

# OOM
#	ch_mesh-6144_ranks-256_tpn-$(TPN).csv \
#	ch_mesh-6144_ranks-512_tpn-$(TPN).csv \
#	ch_mesh-6144_ranks-768_tpn-$(TPN).csv \
#	ch_mesh-6144_ranks-1024_tpn-$(TPN).csv \
#	ch_mesh-6144_ranks-2048_tpn-$(TPN).csv \

#	ch_mesh-8192_ranks-768_tpn-$(TPN).csv \
#	ch_mesh-8192_ranks-1024_tpn-$(TPN).csv \
#	ch_mesh-8192_ranks-2048_tpn-$(TPN).csv \
#	ch_mesh-8192_ranks-4096_tpn-$(TPN).csv \

#	ch_mesh-12288_ranks-1024_tpn-$(TPN).csv \
#	ch_mesh-12288_ranks-2048_tpn-$(TPN).csv \
#	ch_mesh-12288_ranks-4096_tpn-$(TPN).csv \

$(call target-set,ch-core-jumbo,$(DATS_ch-core-jumbo))

# These were collected on debug q (some only mesh+setup, without solve), but
# perhaps are not of critical interest
DATS_ch-core-jumbo-extra=\
	ch_mesh-128_ranks-8_tpn-$(TPN).csv \
	ch_mesh-256_ranks-8_tpn-$(TPN).csv \
	ch_mesh-256_ranks-16_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-16_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-32_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-48_tpn-$(TPN).csv \
	ch_mesh-1024_ranks-64_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-64_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-128_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-384_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-448_tpn-$(TPN).csv \
	ch_mesh-2048_ranks-512_tpn-$(TPN).csv \
	ch_mesh-4096_ranks-64_tpn-$(TPN).csv \

$(call target-set,ch-core-jumbo-extra,$(DATS_ch-core-jumbo-extra))

DATS_ch-core=$(DATS_ch-core-tiny) $(DATS_ch-core-small) \
  $(DATS_ch-core-large) $(DATS_ch-core-jumbo)
$(call target-set,ch-core,$(DATS_ch-core))

# < 1 hr total
DATS_ch-tpn=\
	ch_mesh-1024_ranks-64_tpn-8-node.csv \
	ch_mesh-1024_ranks-64_tpn-16-node.csv \
	ch_mesh-1024_ranks-64_tpn-32-node.csv \
	ch_mesh-1024_ranks-64_tpn-48-node.csv \
	ch_mesh-1024_ranks-64_tpn-64-node.csv \

$(call target-set,ch-tpn,$(DATS_ch-tpn))

ifneq ($(IN),)
$(DATA_DIR)/ch_%.csv: $(DATA_DIR)/prun_%.hostfile | $(DATA_DIR)/
	set -o pipefail; \
	$(call prun-cmd,$*,$<) \
	env OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
	bash $(PWD)/../fch.sh "$(call tgt-extract,mesh,$*)" \
		"$(call tgt-extract,ranks,$*)" \
		"$(call tgt-tasks-per-node,$*)" \
		--elapsed-out "$@" \
		--solution-out "$(patsubst %.csv,%.pvd,$@)" \
		$(if $(call tgt-steps,$*),--tasks "$(call tgt-steps,$*)") \
		$(if $(MEM_PER_NODE),--mem-per-node "$(MEM_PER_NODE)") \
		$(if $(DEDI_NODE_FOR_RANK0),--dedicated-node-for-rank0) \
		$(if $(MONITOR_MEM),--monitor-mem $(MONITOR_MEM)) \
	2>&1 | tee "$@.log"
endif # IN=
