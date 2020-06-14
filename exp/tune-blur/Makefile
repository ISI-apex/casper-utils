all:
	$(MAKE) -C profile
clean:
	$(MAKE) -C profile clean

small: model-cpu-small model-gpu-small
large: model-cpu-large model-gpu-large
.PHONY: all clean small large

profile-cpu-small: dat/cpu/small/blur.csv
profile-cpu-large: dat/cpu/large/blur.csv
profile-gpu-small: dat/gpu/small/blur.csv
profile-gpu-large: dat/gpu/large/blur.csv
.PHONY: profile-cpu-small profile-cpu-large
.PHONY: profile-gpu-small profile-gpu-large

%/:
	mkdir -p $@

dat/cpu/small/blur.csv: | dat/cpu/small/
	profile/build/blur_cpu 2 2 2 $@
dat/cpu/large/blur.csv: | dat/cpu/large/
	profile/build/blur_cpu 5 1000 5 $@
dat/gpu/small/blur.csv: | dat/gpu/small/
	profile/build/blur_gpu 2 2 $@
dat/gpu/large/blur.csv: | dat/gpu/large/
	profile/build/blur_gpu 5 5 $@

profile-cpu-%-clean:
	rm -f dat/cpu/$*/blur.csv
profile-gpu-%-clean:
	rm -f dat/gpu/$*/blur.csv
profile-small-clean: profile-cpu-small-clean profile-gpu-small-clean
profile-large-clean: profile-cpu-large-clean profile-gpu-large-clean
.PHONY: profile-small-clean profile-large-clean

model-cpu-small: model/nn/cpu/small/blur_model.meta
model-cpu-large: model/nn/cpu/large/blur_model.meta
model-gpu-small: model/nn/gpu/small/blur_model.meta
model-gpu-large: model/nn/gpu/large/blur_model.meta
.PHONY: model-cpu-small model-cpu-large
.PHONY: model-gpu-small model-gpu-large

model/nn/cpu/small/blur_model.meta: TRAIN_SIZE=1
model/nn/cpu/large/blur_model.meta: TRAIN_SIZE=2000
model/nn/gpu/small/blur_model.meta: TRAIN_SIZE=1
model/nn/gpu/large/blur_model.meta: TRAIN_SIZE=500
model/nn/cpu/%/blur_model.meta: dat/cpu/%/blur.csv | model/nn/cpu/%/
	python predict/blur_cpu/pred_NN.py $< $(TRAIN_SIZE) $(@D)/blur_model
model/nn/gpu/%/blur_model.meta: dat/gpu/%/blur.csv | model/nn/gpu/%/
	python predict/blur_gpu/pred_NN.py $< $(TRAIN_SIZE) $(@D)/blur_model

model-cpu-%-clean:
	rm -f model/nn/cpu/$*/blur_model*
model-gpu-%-clean:
	rm -f model/nn/gpu/$*/blur_model*
model-small-clean: model-cpu-small-clean model-gpu-small-clean
model-large-clean: model-cpu-large-clean model-gpu-large-clean
.PHONY: model-small-clean model-large-clean

small-clean: profile-small-clean model-small-clean
large-clean: profile-large-clean model-large-clean
.PHONY: small-clean large-clean

# Don't delete intemediate artifacts
.PRECIOUS:
