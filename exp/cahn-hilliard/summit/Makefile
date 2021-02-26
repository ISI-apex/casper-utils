ifeq ($(filter %.pdf %.svg,$(MAKECMDGOALS)),)
ifeq ($(EPREFIX),)
$(error EPREFIX env var not set to Prefix root directory)
endif # EPREFIX
else
EPREFIX_REQUIRED=
endif

ACCOUNT?=csc436

# Could point to installation within the prefix, or within casper-utils (the
# latter is convenient for development, but the former is ensures that the
# prefix is self-sufficient, i.e. does not depend on any other repos)
#PTOOLS_DIR:=${EPREFIX}/usr/share/prefix-tools
PTOOLS_DIR:=../../../prefix-tools

include $(PTOOLS_DIR)/clusters/olcf-summit/make/Makefile

# Very important to set OMP threads, otherwise it spawns way to many, and the
# default also varies by rank count -- the default is a mess.
OMP_NUM_THREADS?=1

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

ifneq ($(IN),)
# NOTES: On Summit, have these extra happenings:
#  1. for some reason some env vars are not propagated, so set them here
#    1a. PETSC_DIR
#    1a. CUDA lib is not found, presumably because of a missing env var,
#        workaround is to add it to LD_LIBRARY_PATH here
#  2. in case prefix is in ~ file system, it's read-only on compute nodes,
#  so have to set cache directory to a writable path
#
CUDA_LIB_DIR:="/autofs/nccs-svm1_home1/acolin/casper/gpref/gp-k/opt/cuda/targets/ppc64le-linux/lib"
# TODO: needing XL_LIB_DIR is a bug, petsc4py pulls this in from host!
XL_LIB_DIR:="/autofs/nccs-svm1_sw/summit/xl/16.1.1-5/lib"

$(DATA_DIR)/ch_%.csv: $(DATA_DIR)/prun_%.hostfile | $(DATA_DIR)/
	set -o pipefail; \
	$(call prun-cmd,$*,$<) \
	env OMP_NUM_THREADS=$(OMP_NUM_THREADS) \
	  XDG_CACHE_HOME="$$__LSF_JOB_TMPDIR__" \
	  PETSC_DIR="${EPREFIX}/usr/lib64/petsc" \
	  LD_LIBRARY_PATH="$$LD_LIBRARY_PATH:${CUDA_LIB_DIR}:${XL_LIB_DIR}" \
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
