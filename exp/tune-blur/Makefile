all: test

# also builds blur_gpu
build/blur_cpu:
	mkdir -p build
	cd build && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
	cd build && ninja -v

# for convenience
build:
	cd build && ninja -v

# also tests blur_gpu
test: build/blur_cpu
	cd build && ninja -v test
.PHONY: test

profile: blur_cpu.csv blur_gpu.csv
.PHONY: profile

blur_cpu.csv:
	build/blur_cpu 5 1000 5 $@
blur_gpu.csv:
	build/blur_gpu 5 5 5 $@

# don't clean data, to prevent accidents
clean:
	rm -rf build/
