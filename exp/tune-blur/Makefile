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
profile-small: profile-cpu-small profile-gpu-small
profile-large: profile-cpu-large profile-gpu-large
.PHONY: profile-cpu-small profile-cpu-large
.PHONY: profile-gpu-small profile-gpu-large
.PHONY: profile-small profile-large

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

dat/cpu/small/fft.csv: | dat/cpu/small/
	profile/build/fft 2 2 1 1 1 0 $@
dat/cpu/large/fft.csv: | dat/cpu/large/
	profile/build/fft 2 2 1000 10 1000 0 $@
dat/gpu/small/fft.csv: | dat/gpu/small/
	profile/build/fft 2 2 1 1 1 1 $@
dat/gpu/large/fft.csv: | dat/gpu/large/
	profile/build/fft 2 2 1000 10 1000 1 $@

profile-cpu-%-clean:
	rm -f dat/cpu/$*/blur.csv
profile-gpu-%-clean:
	rm -f dat/gpu/$*/blur.csv
profile-small-clean: profile-cpu-small-clean profile-gpu-small-clean
profile-large-clean: profile-cpu-large-clean profile-gpu-large-clean
.PHONY: profile-small-clean profile-large-clean

model-cpu-small: \
	model/cpu/small/nn/blur_model.meta \
	model/cpu/small/nnc/blur_model.meta
model-cpu-large: \
	model/cpu/large/nn/blur_model.meta \
	model/cpu/large/nnc/blur_model.meta
model-gpu-small: \
	model/gpu/small/nn/blur_model.meta \
	model/gpu/small/nnc/blur_model.meta
model-gpu-large: \
	model/gpu/large/nn/blur_model.meta \
	model/gpu/large/nnc/blur_model.meta

.PHONY: model-cpu-small model-cpu-large
.PHONY: model-gpu-small model-gpu-large

model/cpu/small/%/blur_model.meta: TRAIN_SIZE=1
model/cpu/large/%/blur_model.meta: TRAIN_SIZE=2000
model/gpu/small/%/blur_model.meta: TRAIN_SIZE=1
model/gpu/large/%/blur_model.meta: TRAIN_SIZE=500
model/cpu/%/nn/blur_model.meta: TRAIN_FEATURES=5
model/cpu/%/nnc/blur_model.meta: TRAIN_FEATURES=6
model/gpu/%/nn/blur_model.meta: TRAIN_FEATURES=4
model/gpu/%/nnc/blur_model.meta: TRAIN_FEATURES=5
model/cpu/%/blur_model.meta: TRAIN_STEPS=10000
model/gpu/%/blur_model.meta: TRAIN_STEPS=5000
model/%/nn/blur_model.meta model/%/nnc/blur_model.meta: \
	dat/%/blur.csv | model/%/nn/ model/%/nnc/
	python predict.py $< \
		$(TRAIN_SIZE) $(TRAIN_FEATURES) $(TRAIN_STEPS) \
		$(@D)/blur_model

model-cpu-%-clean:
	rm -f model/cpu/$*/*/
model-gpu-%-clean:
	rm -f model/gpu/$*/*/
model-small: model-cpu-small model-gpu-small
model-large: model-cpu-large model-gpu-large
model-small-clean: model-cpu-small-clean model-gpu-small-clean
model-large-clean: model-cpu-large-clean model-gpu-large-clean
.PHONY: model-small-clean model-large-clean

small-clean: profile-small-clean model-small-clean
large-clean: profile-large-clean model-large-clean
.PHONY: small-clean large-clean

# Don't delete intemediate artifacts
.SECONDARY:
