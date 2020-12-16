
# This function run on host machine, not em docker
copy_openjpeg() {
    # The following lines for openjpeg run on host machine, openjpeg is built from another em docker
    mkdir -p out/include
    mkdir -p out/lib
    mkdir -p out/lib/pkgconfig
    mkdir -p out/include/openjpeg-2.3
    cp -r ../openjpeg/src/lib/openjp2/*.h out/include/openjpeg-2.3
    cp -r ../openjpeg/em/src/lib/openjp2/*.h out/include/openjpeg-2.3
    cp ../openjpeg/em/bin/libopenjp2.a out/lib/
    cp ../openjpeg/em/libopenjp2.pc out/lib/pkgconfig/
    cp ../openjpeg/em/OpenJPEGConfig.cmake cmake/modules/
    cp ../openjpeg/em/CMakeFiles/Export/lib/openjpeg-2.3/* cmake/modules/
}

copy_cairo() {
	cp ../cairo/out/lib/libpixman-1.a out/lib/
	cp ../cairo/src/.libs/libcairo.a out/lib/
	mkdir -p out/include/cairo
	cp ../cairo/src/*.h out/include/cairo
	cp ../cairo/out/lib/pkgconfig/cairo* out/lib/pkgconfig/
}


#copy_openjpeg
copy_cairo
