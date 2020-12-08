#!/bin/bash -x

set -x
#set -e -o pipefail

BUILD_DIR=$PWD/out
OUT_LIB_DIR=$BUILD_DIR/lib
export EM_PKG_CONFIG_PATH=$BUILD_DIR/lib/pkgconfig
export PATH=$PATH:$BUILD_DIR/bin

mkdir -p out
mkdir -p out/lib
mkdir -p out/include

install_buildin_libs() {
    emcc -s USE_SDL=2 -s USE_FREETYPE=1 -s USE_LIBJPEG=1 -s USE_LIBPNG=1 -s USE_ZLIB=1 trigger/a.c -s LEGACY_GL_EMULATION=1 -o trigger/a.html
    
    mkdir -p out/include/zlib
    cp -r /emsdk_portable/.data/cache/wasm/ports-builds/zlib/*.h out/include/zlib
    cp /emsdk_portable/.data/cache/wasm/libz.a out/lib
    mkdir -p out/include/libjpeg
    cp -r /emsdk_portable/.data/cache/wasm/ports-builds/libjpeg/*.h out/include/libjpeg
    cp /emsdk_portable/.data/cache/wasm/libjpeg.a out/lib
    mkdir -p out/include/libpng
    cp -r /emsdk_portable/.data/cache/wasm/ports-builds/libpng/*.h out/include/libpng
    cp /emsdk_portable/.data/cache/wasm/libpng.a out/lib
    cp -r /emsdk_portable/.data/cache/wasm/ports-builds/freetype/include out/include/freetype
    cp /emsdk_portable/.data/cache/wasm/ports-builds/freetype/libfreetype.a out/lib
    export FREETYPE_DIR=/src/out
    #export FREETYPE_LIBS="/src/out/lib/libfreetype.a"
    export FREETYPE_LIBS="-L/src/out/lib -lfreetype"
    export FREETYPE_CFLAGS="-I$FREETYPE_DIR/include/freetype -I$FREETYPE_DIR/include"
}

mkdir -p third_party

install_tools() {
	apt-get update
	apt-get install -y autoconf
	apt-get install -y libtool
	apt-get install -y pkg-config
	apt-get install -y gettext
	apt-get install -y gperf
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

build_libtiff() {
	LAST_PWD=$(pwd)
	cd third_party
	download_and_decompress "https://gitlab.com/libtiff/libtiff/-/archive/Release-v4-0-9/libtiff-Release-v4-0-9.tar.gz"
	cd libtiff-Release-v4-0-9
	emconfigure ./configure \
		--disable-asm \
		--disable-thread \
		--prefix=$BUILD_DIR
	emmake make clean
	emmake make -j6
	emmake make install
	cd $LAST_PWD
}

build_libxml2() {
	LAST_PWD=$(pwd)
	cd third_party
	download_and_decompress "ftp://xmlsoft.org/libxml2/libxml2-git-snapshot.tar.gz"
	cd libxml2-2.9.7
	emconfigure ./configure \
		--disable-asm \
		--disable-thread \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	if [ ! -f .lib/libxml2.a ]
	then
		cd .lib
		# O_FILES=`ls *.o | grep -v nano | grep -v -i test`
		# llvm-ar r libxml2.a $O_FILES
		llvm-ar r libxml2.a *.o
		llvm-ranlib libxml2.a
		cp libxml2.a $OUT_LIB_DIR
		cd -
	fi
	cd $LAST_PWD
}

build_fontconfig() {
	LAST_PWD=$(pwd)
	cd third_party
	download_and_decompress "https://www.freedesktop.org/software/fontconfig/release/fontconfig-2.13.92.tar.gz"
	cd fontconfig-2.13.92
	export LIBXML2_CFLAGS="-I/src/out/include/libxml2"
	export LIBXML2_LIBS="-L/src/out/lib -lxml2"
	export FREETYPE_CFLAGS="-I/src/out/include/freetype"
	export FREETYPE_LIBS="-L/src/out/lib -lfreetype"
	emconfigure ./configure \
		LDFLAGS="-static" \
		--disable-asm \
		--disable-thread \
		--enable-libxml2 \
		--prefix=$BUILD_DIR
	emmake make -j6
	emmake make install
	cd $LAST_PWD
}

build_poppler() {
  cd em
  emconfigure cmake . 
  emmake make -j6
  emmake make install
  cp libpoppler.a $OUT_LIB_DIR
  cd -
}

link_js_file() {
  LAST_PWD=$(pwd)
  em++ -I$BUILD_DIR/include -L${BUILD_DIR}/lib -Ipoppler -Iutil -Iem/poppler/ -I. -Iem -Igoo -I$BUILD_DIR/include/cairo \
    -Wall -Wextra -Wpedantic -Wno-unused-parameter -Wcast-align -Wformat-security -Wframe-larger-than=65536 -Wmissing-format-attribute -Wnon-virtual-dtor -Woverloaded-virtual -Wmissing-declarations -Wundef -Wzero-as-null-pointer-constant -Wshadow -Wweak-vtables -fno-exceptions -fno-check-new -fno-common -D_DEFAULT_SOURCE -std=c++14 \
    utils/parseargs.cc ./utils/printencodings.cc utils/ImageOutputDev.cc utils/HtmlFonts.cc  utils/HtmlLinks.cc  utils/HtmlOutputDev.cc utils/InMemoryFile.cc \
	utils/pdfunite.cc utils/pdfimages.cc utils/pdfinfo.cc utils/pdfseparate.cc utils/pdfattach.cc utils/pdfdetach.cc utils/pdftohtml.cc utils/pdftotext.cc \
	-Oz \
	-lpoppler -lfontconfig -lfreetype -ltiff -lxml2 -lz -lopenjp2 -lcairo -lpixman-1 \
	--closure 1 \
	--pre-js prepend.js \
	-o poppler.js \
	-s ERROR_ON_UNDEFINED_SYMBOLS=0 \
	-s LLD_REPORT_UNDEFINED=1 \
	-s EXPORT_NAME="'PDFModule'" \
	-s USE_SDL=2 -s USE_FREETYPE=1 -s USE_LIBJPEG=1 -s USE_LIBPNG=1 -s USE_ZLIB=1 \
	-s MODULARIZE=1 \
	-s SINGLE_FILE=1 \
	-s ALLOW_MEMORY_GROWTH=1 \
	-s RESERVED_FUNCTION_POINTERS=1 \
	-s EXPORTED_FUNCTIONS="['_pdfunite', '_pdfimages', '_pdfinfo', '_pdfseparate', '_pdfattach', '_pdfdetach', '_pdftohtml', '_pdftotext']" \
	-s EXTRA_EXPORTED_RUNTIME_METHODS="[cwrap, FS, getValue, setValue]" \

  cd $LAST_PWD
}

#install_tools
#install_buildin_libs
#build_libogg
#build_libtool
#build_file
#build_libxml2
#build_libtiff
#build_fontconfig
link_js_file

