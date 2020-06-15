%/:
	mkdir -p $@

define run-app
	sh -c "export OMP_NUM_THREADS=$(5) && \
		mpirun --oversubscribe -np $(4) \
			python demo_cavity.py $(1) $(2) $(3) \
				$(4) $(5) $(6)"
endef

dat/small/mumps.csv: | dat/small/
	for np in 1 2; do \
		for th in 1 2; do \
			$(call run-app,3,3,1,$$np,$$th,$@); \
		done \
	done

# Iterate over (NPROC, NTHREAD) pairs such that total number of ranks
# is below the total number of cores
COUNT:=1 2 4 6 8 16 32
CORES:=32
dat/log-large/mumps.csv: | dat/log-large/
	$(foreach np,$(COUNT),\
	  $(foreach th,$(COUNT),\
	    $(if $(filter 1,$(shell echo '$(np)*$(th)<=$(CORES)' | bc)),\
	      $(call run-app,3,9,3,$(np),$(th),$@)$(NL))))

dat/lin-large/mumps.csv: | dat/lin-large/
	for np in {1..16..1}; do \
		for th in {1..32..1}; do \
			$(call run-app,3,9,3,$$np,$$th,$@); \
		done \
	done
	for np in {17..32..1}; do \
		for th in {1..32..1}; do \
			$(call run-app,3,9,3,$$np,$$th,$@); \
		done \
	done

dat/%/mumps_uniq.csv: dat/%/mumps.csv
	python dedup.py $< $@

profile-small: dat/small/mumps_uniq.csv
profile-log-large: dat/log-large/mumps_uniq.csv
profile-lin-large: dat/lin-large/mumps_uniq.csv

profile-small-clean:
	rm -rf dat/small/
profile-log-large-clean:
	rm -rf dat/log-large/
profile-lin-large-clean:
	rm -rf dat/lin-large/
.PHONY: profile-small profile-small-clean
.PHONY: profile-log-large profile-lin-large
.PHONY: profile-lin-large-clean profile-lin-large-clean

model/%_model.meta: HAS_HEADER=1
model/%_model.meta: TRAIN_TOL=0.1
model/%_model.meta: LAYERS=1
model/%_model.meta: MAPE_LIM1=1
model/%_model.meta: MAPE_LIM2=5

model/small/%/mumps_model.meta: TRAIN_SIZE=1
model/log-large/%/mumps_model.meta: TRAIN_SIZE=70
model/lin-large/%/mumps_model.meta: TRAIN_SIZE=70
model/%/nn/mumps_model.meta: TRAIN_FEATURES=3
model/%/nnc/mumps_model.meta: TRAIN_FEATURES=4
model/%/mumps_model.meta: TRAIN_STEPS=10000

model/%/nn/mumps_model.meta model/%/nnc/mumps_model.meta: \
	dat/%/mumps_uniq.csv | model/%/nn/ model/%/nnc/
	python ../../compiler/autotuner/train.py $< $(HAS_HEADER) \
		$(TRAIN_SIZE) $(TRAIN_FEATURES) $(TRAIN_STEPS) \
		$(TRAIN_TOL) $(LAYERS) $(MAPE_LIM1) $(MAPE_LIM2) \
		$(@D)/mumps_model

model-small: model/small/nn/mumps_model.meta model/small/nnc/mumps_model.meta
model-small-clean:
	rm -rf model/small/
model-log-large: \
	model/log-large/nn/mumps_model.meta \
	model/lin-large/nnc/mumps_model.meta 
model-lin-large: \
	model/lin-large/nn/mumps_model.meta \
	model/lin-large/nnc/mumps_model.meta 
model-log-large-clean:
	rm -rf model/log-large/
model-lin-large-clean:
	rm -rf model/lin-large/
.PHONY: model-small model-log-large model-lin-large
.PHONY: model-small-clean model-log-large-clean model-lin-large-clean

# newline
define NL



endef


# Don't delete intemediate artifacts
.SECONDARY:
