all:
	cd build && ninja -v

# also builds blur_gpu
build/blur_cpu:
	mkdir -p build
	cd build && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release ..
	cd build && ninja -v

# for convenience
build:
	cd build && ninja -v
.PHONY: build

# also tests blur_gpu
test: build/blur_cpu
	cd build && ninja -v test
.PHONY: test

# don't clean data, to prevent accidents
clean:
	rm -rf build/
