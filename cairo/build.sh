#!/bin/bash -x

set -x
#set -e -o pipefail

BUILD_DIR=$PWD/out
export EM_PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig
export PATH=$PATH:$BUILD_DIR/bin

mkdir -p third_party

install_tools() {
	apt-get update
	apt-get install -y autoconf
	apt-get install -y libtool
	apt-get install -y pkg-config
	apt-get install -y gettext
}

download_and_decompress() {
	URL=$1
	FILENAME=$(echo $URL | awk -F'/' '{print $NF}')
	if [ ! -f $FILENAME ]
	then
		wget $URL
	fi
	tar xzf $FILENAME
}

build_libtool() {
	LAST_PWD=$(pwd)
	cd third_party
	download_and_decompress "http://ftpmirror.gnu.org/libtool/libtool-2.4.6.tar.gz"
	cd libtool-2.4.6
	emconfigure ./configure \
		--disable-asm \
		--disable-thread \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	cd $LAST_PWD
}

build_zlib() {
	LAST_PWD=$(pwd)
	cd third_party/
	download_and_decompress "https://www.zlib.net/zlib-1.2.11.tar.gz"
	cd zlib-1.2.11
	emconfigure ./configure \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	cd $LAST_PWD
}

build_pixman() {
	LAST_PWD=$(pwd)
	cd third_party/
	download_and_decompress "https://www.cairographics.org/releases/pixman-0.38.4.tar.gz"
	cd pixman-0.38.4
	emconfigure ./configure \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	cp third_party/pixman-0.38.4/pixman-1.pc $BUILD_DIR/pkgconfig/
	cd $LAST_PWD
}

create_libpng_pc() {
echo "prefix=/src/out
bindir=${prefix}/bin
mandir=${prefix}/
docdir=${prefix}/
libdir=${prefix}/lib
includedir=${prefix}/include/libpng

Name: libpng
Description: PNG library
URL: http://www.openjpeg.org/
Version: 16.36.0
Libs: -L${libdir} -lpng
Libs.private: -lm
Cflags: -I${includedir}" > out/lib/pkgconfig/libpng.pc
}

build_file() {
  sh autogen.sh
  emconfigure ./configure \
    CFLAGS="-I/src/out/include" \
	LDFLAGS="-L/src/out/lib" \
    --disable-asm \
	--disable-asm-optimizations \
	--disable-examples \
    --disable-thread \
	--disable-cpplibs \
	--disable-xmms-plugin \
	--disable-rpath \
	--disable-thorough-tests \
	--disable-vsx \
	--disable-avx \
    --prefix=$BUILD_DIR
  # create_libpng_pc
  # sed -i 's/ax_cv_c_float_words_bigendian=unknown/ax_cv_c_float_words_bigendian=no/g' configure
  # sed -i 's/use_script=$have_libz/use_script=yes/g' configure
  emmake make -j6
  emmake make install
}


link_js_file() {
  LAST_PWD=$(pwd)
  cd src/metaflac
  emmake make
  em++ -I$BUILD_DIR/include -L${BUILD_DIR}/lib \
	-Oz \
	main.o operations.o operations_shorthand_cuesheet.o operations_shorthand_picture.o operations_shorthand_seektable.o operations_shorthand_streaminfo.o operations_shorthand_vorbiscomment.o options.o usage.o utils.o \
	-logg -lFLAC \
	../../src/share/grabbag/.libs/libgrabbag.a ../../src/share/replaygain_analysis/.libs/libreplaygain_analysis.a ../../out/lib/libogg.a ../../src/share/utf8/.libs/libutf8.a ../../src/share/getopt/.libs/libgetopt.a \
	--closure 1 \
	-o metaflac.js \
	-s EXPORT_NAME="'MetaFlacModule'" \
	-s USE_SDL=2 \
	-s MODULARIZE=1 \
	-s SINGLE_FILE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s RESERVED_FUNCTION_POINTERS=1 \
	-s EXPORTED_FUNCTIONS="['_metaflac']" \
	-s EXTRA_EXPORTED_RUNTIME_METHODS="[cwrap, FS, getValue, setValue]" \

  cd $LAST_PWD
}

#install_tools
#build_libtool
#build_zlib
#build_pixman
build_file
#link_js_file

