.PHONY: build clean test

build:
	cmake -S . -B build && cmake --build build

clean:
	if [ -d build ]; then make -C build clean; fi

test: build
	cd build && ctest --output-on-failure
