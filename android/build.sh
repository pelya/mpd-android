#!/bin/sh

set -x

NCPU=4
export BUILDDIR=`pwd`
#export GLIB_PATH=$BUILDDIR/../../glib/build/android
export GLIB_PATH=$BUILDDIR/glib/build/android

[ -e $GLIB_PATH/lib/libglib-2.0.so ] || {
	[ -e glib ] || git clone --depth 1 git://git.gnome.org/glib || exit 1
	cd glib

	curl --location https://bugzilla.gnome.org/attachment.cgi?id=257308 > glib-android.patch || exit 1
	git apply glib-android.patch || exit 1

	cd build/android
	./build.sh || exit 1

	cd $BUILDDIR
}

export PKG_CONFIG_PATH=$GLIB_PATH/lib/pkgconfig:$BUILDDIR/lib/pkgconfig

if false; then
[ -e lib/libaudiofile.so ] || {
	[ -e audiofile ] || git clone --depth 1 https://github.com/mpruett/audiofile.git
	cd audiofile

	env BUILD_EXECUTABLE=1 \
		../setCrossEnvironment.sh \
		./autogen.sh \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		--disable-flac \
		--disable-examples \
		--disable-docs \
		|| exit 1


	cd $BUILDDIR
}
fi

[ -e lib/libsndfile.so ] || {
	[ -e libsndfile-1.0.25 ] || curl http://www.mega-nerd.com/libsndfile/files/libsndfile-1.0.25.tar.gz | tar xz || exit 1
	cd libsndfile-1.0.25
	cp -f /usr/share/automake-*/config.* Cfg/

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		--disable-alsa \
		--disable-external-libs \
		--disable-sqlite \
		|| exit 1

	echo all install: > tests/Makefile
	echo all install: > programs/Makefile

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libogg.so ] || {
	[ -e libogg-1.3.1 ] || curl http://downloads.xiph.org/releases/ogg/libogg-1.3.1.tar.gz | tar xz || exit 1
	cd libogg-1.3.1

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libvorbis.so ] || {
	[ -e libvorbis-1.3.3 ] || curl http://downloads.xiph.org/releases/vorbis/libvorbis-1.3.3.tar.gz | tar xz || exit 1
	cd libvorbis-1.3.3

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include" \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libFLAC.so ] || {
	[ -e flac-1.2.1 ] || curl http://downloads.xiph.org/releases/flac/flac-1.2.1.tar.gz | tar xz || exit 1
	cd flac-1.2.1

	cp -f /usr/share/automake-*/config.* ./
	#cp -f `which libtool` ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include" \
		LDFLAGS="-L$BUILDDIR/lib -L`pwd`" \
		../setCrossEnvironment.sh \
		./autogen.sh \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	sed -i 's/crtbegin_so.o//g' libtool
	sed -i 's/crtend_so.o//g' libtool
	sed -i 's/-nostdlib//g' libtool

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libssl.a ] || {
	[ -e openssl/jni ] || git clone --depth 1 git://github.com/fries/android-external-openssl.git openssl/jni || exit 1
	rm -f openssl/jni/Application.mk
	echo APP_MODULES := libcrypto-static libssl-static > openssl/jni/Application.mk
	echo APP_ABI := armeabi >> openssl/jni/Application.mk
	ndk-build -j$NCPU -C openssl || exit 1
	cp -f openssl/obj/local/armeabi/libcrypto-static.a lib/libcrypto.a || exit 1
	cp -f openssl/obj/local/armeabi/libssl-static.a lib/libssl.a || exit 1
	cp -f -a openssl/jni/include/* include/
}

[ -e lib/libcurl.so ] || {
	[ -e curl-7.33.0 ] || curl http://curl.haxx.se/download/curl-7.33.0.tar.gz | tar xz || exit 1
	cd curl-7.33.0

	env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include" \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		--enable-ipv6 \
		--with-ssl=$BUILDDIR \
		|| exit 1

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libfaad.so ] || {
	[ -e faad2-2.7 ] || curl --location http://downloads.sourceforge.net/faac/faad2-2.7.tar.gz | tar xz || exit 1
	cd faad2-2.7

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		. ./bootstrap &&
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include" \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	sed -i 's/crtbegin_so.o//g' libtool
	sed -i 's/crtend_so.o//g' libtool
	sed -i 's/-nostdlib//g' libtool
	echo all install: > frontend/Makefile

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libavformat.so ] || {
	# Use Github SVN interface to get specific directory from a big repo
	svn co https://github.com/pelya/commandergenius/trunk/project/jni/ffmpeg || exit 1
	cp -a -f ffmpeg/include/* include/
	cp -a -f ffmpeg/lib/armeabi/* lib/
}

if false; then
[ -e lib/libmad.so ] || {
	[ -e libmad-0.15.1b ] || curl --location http://sourceforge.net/projects/mad/files/libmad/0.15.1b/libmad-0.15.1b.tar.gz/download | tar xz || exit 1
	cd libmad-0.15.1b

	cp -f /usr/share/automake-*/config.* ./
	sed -i 's/CFLAGS="$CFLAGS $optimize"//g' ./configure

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include" \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	sed -i 's/ASO_OBJS = .*/ASO_OBJS = /g' Makefile
	sed -i 's/ASO = .*/ASO = /g' Makefile
	sed -i 's/FPM = .*/FPM = -DFPM_64BIT/g' Makefile
	sed -i 's/crtbegin_so.o//g' libtool
	sed -i 's/crtend_so.o//g' libtool
	sed -i 's/-nostdlib//g' libtool

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}
fi

[ -e lib/libzzip.so ] || {
	[ -e zzip/jni ] || svn co https://github.com/pelya/commandergenius/trunk/project/jni/zzip zzip/jni || exit 1
	rm -f zzip/jni/Application.mk zzip/jni/zzip/SDL_rwops_zzip.c
	echo APP_MODULES := zzip > openssl/jni/Application.mk
	echo APP_ABI := armeabi >> openssl/jni/Application.mk
	ndk-build -j$NCPU -C zzip || exit 1
	cp -f zzip/obj/local/armeabi/libzzip.so lib/libzzip.so || exit 1
	cp -f -a zzip/jni/include/* include/
}

if false; then
[ -e lib/libid3.a ] || {
	[ -e id3lib-3.8.3 ] || curl --location http://sourceforge.net/projects/id3lib/files/id3lib/3.8.3/id3lib-3.8.3.tar.gz/download | tar xz || exit 1
	cd id3lib-3.8.3

	cp -f /usr/share/automake-*/config.* ./
	echo > iomanip.h

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}
fi

[ -e lib/libid3tag.so ] || {
	[ -e libid3tag-0.15.1b ] || curl --location http://sourceforge.net/projects/mad/files/libid3tag/0.15.1b/libid3tag-0.15.1b.tar.gz/download | tar xz || exit 1
	cd libid3tag-0.15.1b

	cp -f /usr/share/automake-*/config.* ./

	autoconf && \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	#sed -i 's/crtbegin_so.o//g' libtool
	#sed -i 's/crtend_so.o//g' libtool
	#sed -i 's/-nostdlib//g' libtool

	#../setCrossEnvironment.sh \
	#	make -j$NCPU install \
	#	|| exit 1

	env BUILD_EXECUTABLE=1 \
		../setCrossEnvironment.sh \
		sh -c '$CC -DHAVE_CONFIG_H $CFLAGS *.c -shared -o ../lib/libid3tag.so $LDFLAGS' || exit 1

	cp -f id3tag.h ../include/

	cd $BUILDDIR
}

[ -e lib/libsamplerate.so ] || {
	[ -e libsamplerate-0.1.8 ] || curl --location http://www.mega-nerd.com/SRC/libsamplerate-0.1.8.tar.gz | tar xz || exit 1
	cd libsamplerate-0.1.8

	# Compiled and stripped library takes up 1.5Mb, so we'll disable huge coeff tables
	cp -f /usr/share/automake-*/config.* Cfg/

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I. \
		-Dslow_high_qual_coeffs=fastest_coeffs \
		-Dslow_mid_qual_coeffs=fastest_coeffs" \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./autogen.sh \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	echo all install: > examples/Makefile
	echo > src/high_qual_coeffs.h
	echo > src/mid_qual_coeffs.h

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}


[ -e lib/libsqlite3.so ] || {
	[ -e sqlite-autoconf-3080002 ] || curl --location http://www.sqlite.org/2013/sqlite-autoconf-3080002.tar.gz | tar xz || exit 1
	cd sqlite-autoconf-3080002

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libexpat.so ] || {
	[ -e expat-2.1.0 ] || curl --location http://sourceforge.net/projects/expat/files/expat/2.1.0/expat-2.1.0.tar.gz/download | tar xz || exit 1
	cd expat-2.1.0

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib" \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}


[ -e lib/libdaemon.so ] || {
	[ -e libdaemon-0.14 ] || curl --location http://0pointer.de/lennart/projects/libdaemon/libdaemon-0.14.tar.gz | tar xz || exit 1
	cd libdaemon-0.14

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env NOCONFIGURE=1 \
		./bootstrap.sh && \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib" \
		ac_cv_func_setpgrp_void=yes \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	echo all install: > examples/Makefile

	../setCrossEnvironment.sh \
		make -j$NCPU V=1 install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libdbus-1.so ] || {
	[ -e dbus-1.6.16 ] || curl --location http://dbus.freedesktop.org/releases/dbus/dbus-1.6.16.tar.gz | tar xz || exit 1
	cd dbus-1.6.16

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib" \
		ac_cv_func_setpgrp_void=yes \
		ac_cv_func_posix_getpwnam_r=no \
		ac_cv_func_posix_getpwnam_r=no \
		ac_cv_func_nonposix_getpwnam_r=no \
		../setCrossEnvironment.sh \
		./configure \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		|| exit 1

	mkdir -p sys
	echo "#include <fcntl.h>" > sys/fcntl.h

	../setCrossEnvironment.sh \
		make -j$NCPU V=1 install \
		|| exit 1

	cd $BUILDDIR
}

[ -e lib/libglob.a ] || {
	[ -e TokyoCabinet ] || git clone --depth 1 https://github.com/white-gecko/TokyoCabinet.git || exit 1
	cd TokyoCabinet
	env BUILD_EXECUTABLE=1 \
		../setCrossEnvironment.sh \
		sh -c '$CC $CFLAGS -I. -c glob.c -o glob.o $LDFLAGS && ar rcs ../lib/libglob.a glob.o && cp -f glob.h ../include/' || exit 1
	cd $BUILDDIR
}

[ -e lib/libavahi-client.so ] || {
	[ -e avahi-0.6.31 ] || curl --location http://avahi.org/download/avahi-0.6.31.tar.gz | tar xz || exit 1
	cd avahi-0.6.31

	cp -f /usr/share/automake-*/config.* ./

	[ -e Makefile ] || \
		env BUILD_EXECUTABLE=1 \
		CFLAGS="-I$BUILDDIR/include -I." \
		LDFLAGS="-L$BUILDDIR/lib -lglob" \
		../setCrossEnvironment.sh \
		./autogen.sh \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR \
		--with-distro=none \
		--disable-qt3 \
		--disable-qt4 \
		--disable-gtk \
		--disable-gtk3 \
		--enable-dbus \
		--disable-gdbm \
		--enable-libdaemon \
		--disable-python \
		--disable-pygtk \
		--disable-python-dbus \
		--disable-mono \
		--disable-monodoc \
		--enable-autoipd \
		--disable-doxygen-doc \
		--disable-doxygen-dot \
		--disable-doxygen-xml \
		--disable-doxygen-html \
		--disable-manpages \
		--disable-xmltoman \
		|| exit 1

	mkdir -p avahi-daemon/sys
	echo "#include <fcntl.h>" > avahi-daemon/sys/fcntl.h

	../setCrossEnvironment.sh \
		make -j$NCPU install \
		|| exit 1

	cd $BUILDDIR
}

[ -e ../configure ] || {
	cd ..

	env NOCONFIGURE=1 \
		./autogen.sh || exit 1

	cd $BUILDDIR
}

[ -e Makefile ] || {

	sed -i 's/-std=gnu++0x/-std=gnu++11/g' ../configure

	env BUILD_EXECUTABLE=1       \
		CFLAGS="-I$BUILDDIR/../../glib/build/android/include \
				-I$BUILDDIR/include" \
		LDFLAGS="-L$BUILDDIR/../../glib/build/android/lib \
				-L$BUILDDIR/lib" \
		./setCrossEnvironment.sh \
		../configure             \
		--host=arm-linux-androideabi \
		--prefix=$BUILDDIR       \
		--enable-pipe-output     \
		--enable-fifo            \
		--enable-sndfile         \
		--enable-flac            \
		--enable-vorbis          \
		--enable-curl            \
		--enable-ffmpeg          \
		--enable-aac             \
		--enable-zzip            \
		--enable-httpd-output    \
		--enable-id3             \
		--enable-lsr             \
		--enable-wave-encoder    \
		--enable-sqlite          \
		--with-zeroconf=no       \
		--disable-vorbis-encoder \
		--disable-audiofile      \
		--disable-shout          \
		--disable-adplug         \
		--disable-alsa           \
		--disable-roar           \
		--disable-ao             \
		--disable-audiofile      \
		--disable-bzip2          \
		--disable-cdio-paranoia  \
		--disable-fluidsynth     \
		--disable-gme            \
		--disable-iso9660        \
		--disable-jack           \
		--disable-despotify      \
		--disable-soundcloud     \
		--disable-lame-encoder   \
		--disable-libmpdclient   \
		--disable-libwrap        \
		--disable-mad            \
		--disable-mikmod         \
		--disable-mms            \
		--disable-modplug        \
		--disable-mpc            \
		--disable-mpg123         \
		--disable-openal         \
		--disable-opus           \
		--disable-oss            \
		--disable-pulse          \
		--disable-sidplay        \
		--disable-solaris-output \
		--disable-systemd-daemon \
		--disable-twolame-encoder\
		--disable-wavpack        \
		--disable-werror         \
		--disable-wildmidi       \
		FFMPEG_CFLAGS="-I$BUILDDIR/include" \
		FFMPEG_LIBS="-L$BUILDDIR/lib -lavutil -lavcodec -lavformat" \
		ZZIP_CFLAGS="-I$BUILDDIR/include" \
		ZZIP_LIBS="-L$BUILDDIR/lib -lzzip" \
		|| exit 1

	sed -i "s/CXXFLAGS = /CXXFLAGS = -D'nan(X)=std::numeric_limits<float>::quiet_NaN()' -D'nanf(X)=std::numeric_limits<float>::quiet_NaN()' -include limits -include errno.h/g" Makefile
	sed -i "s/^LIBS = /LIBS = -lgnustl_static -lsupc++ /g" Makefile
}

./setCrossEnvironment.sh \
	make -j$NCPU V=1 &&
	make -j$NCPU install \
	|| exit 1

#Generated with ndk-depends
DEPS="
libzzip.so
libvorbisfile.so.3
libvorbis.so.0
libsqlite3.so.0
libsndfile.so.1
libsamplerate.so.0
libogg.so.0
libintl.so.8
libid3tag.so
libgthread-2.0.so.0
libglib-2.0.so.0
libfaad.so.2
libcurl.so.5
libavformat.so
libavcodec.so
libavutil.so
libFLAC.so.8
libffi.so.6
libiconv.so.2
"

#libavahi-glib.so.1
#libavahi-common.so.3
#libavahi-client.so.3
#libdbus-1.so.3

rm -rf dist
mkdir -p dist

cp -f bin/mpd mpd.conf mpd-test.sh dist/

for f in $DEPS; do
	cp -f $GLIB_PATH/lib/$f dist/
	cp -f lib/$f dist/
	chmod a+x dist/$f
done

./setCrossEnvironment.sh \
	sh -c '$STRIP --strip-unneeded dist/*'
