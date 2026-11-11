#!/usr/bin/env bash
# Minimal-Tesseract fuer WIPP (lokale Texterkennung D2c der projektvorlage).
# Tesseract + Leptonica mit PNG, zlib und (seit r4) TIFF und JPEG - ohne curl/libarchive/WebP/GIF/
# JPEG 2000, ohne OpenMP und ohne Trainingswerkzeuge, statisch. Apache-2.0 und freizuegige Lizenzen.
#
#   ./build.sh               Windows x64 (mingw-w64, Cross-Compile)    -> out/win64/
#   ./build.sh linux64       gleiche Komponenten nativ (nur zum Testen) -> out/linux64/
#
# Voraussetzung (Ubuntu 24.04): apt-get install gcc-mingw-w64-x86-64-win32 g++-mingw-w64-x86-64-win32 \
#   binutils-mingw-w64-x86-64 cmake make git curl gpg xz-utils zip
# Getestet mit gcc/g++-mingw-w64-x86-64-win32 13.2.0-6ubuntu1+26.1, binutils-mingw-w64-x86-64
# 2.41.90.20240122-1ubuntu1+11.4, mingw-w64-x86-64-dev 11.0.1-3build1, cmake 3.28.3.
set -euo pipefail

TESS_VERSION=5.5.4
BUILD_REV=r4   # r4 (WIPP 1.11.3): mit libtiff + libjpeg-turbo (Scans/Faxe als TIFF); r3 (1.11.2): dazu tessdata/pdf.ttf;
               # r2 (1.11.1): ohne Debug-Schrift; r1 (1.10): erster Build
TESS_COMMIT=7e548e6eff172f38f97664afe7f7ce40db36c8d6      # Tag 5.5.4 (Commit, nicht das Tag-Objekt)
LEPT_VERSION=1.87.0
LEPT_SHA256=c73363397f96eb1295602bf44d708a994ad42046c791bf03ea0505d829bdb6a7
PNG_VERSION=1.6.59
PNG_SHA256=d80dd2a38a37f803cb9b6ac7b14bd6e74ddc3b654780a8380bdf93523fdb4389
ZLIB_VERSION=1.3.2
ZLIB_SHA256=d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3
ZLIB_KEY=5ED46A6721D365587791E2AA783FCD8E58BCAFBA            # Mark Adler
TIFF_VERSION=4.7.2
TIFF_SHA256=4996f0c4f93094719b1ca5c6279b20e588773ba8a247533e486416fb662ddb88
TIFF_KEY=B1FA7D81EEB8E66399178B9733EBBFC47B3DD87D            # Even Rouault (libtiff)
JPEG_VERSION=3.2.1
JPEG_SHA256=c27ad72a68da151177929aa969ae773a2da5ac2af9ce946079314fdac8cece7f
JPEG_KEY=0338C8D8D9FDA62CF9C421BD7EC2DBB6F4DBF434            # The libjpeg-turbo Project
TESSDATA_COMMIT=87416418657359cb625c412a48b6e1d6d41c29bd     # tessdata_fast
declare -A TESSDATA=(
    [deu]=19d219bbb6672c869d20a9636c6816a81eb9a71796cb93ebe0cb1530e2cdb22d
    [eng]=7d4322bd2a7749724879683fc3912cb542f19906c83bcc1a52132556427170b2
    [osd]=9cf5d576fcc47564f11265841e5ca839001e7e6f38ff7f7aacf46d15a96b00ff
)
TARGET=${1:-win64}

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$HERE/work/$TARGET
OUT=$HERE/out/$TARGET
DL=$HERE/work/dl
PREFIX=$WORK/prefix
mkdir -p "$DL" "$OUT"
export SOURCE_DATE_EPOCH=1777593600   # fester Wert statt Bauzeit (reproduzierbar)
export LC_ALL=C TZ=UTC
JOBS=$(nproc)

fetch() {   # fetch <url> <datei> [sha256]
    if [ ! -f "$DL/$2" ]; then curl -fsSL -o "$DL/$2.tmp" "$1"; mv "$DL/$2.tmp" "$DL/$2"; fi
    if [ -n "${3:-}" ]; then echo "$3  $DL/$2" | sha256sum -c - ; fi
}

# --- Quellen: feste SHA-256, zlib zusaetzlich mit Signatur, Tesseract ueber den Commit ---
fetch https://zlib.net/zlib-$ZLIB_VERSION.tar.xz zlib-$ZLIB_VERSION.tar.xz $ZLIB_SHA256
fetch https://zlib.net/zlib-$ZLIB_VERSION.tar.xz.asc zlib-$ZLIB_VERSION.tar.xz.asc
fetch https://download.sourceforge.net/libpng/libpng-$PNG_VERSION.tar.xz libpng-$PNG_VERSION.tar.xz $PNG_SHA256
fetch https://github.com/DanBloomberg/leptonica/releases/download/$LEPT_VERSION/leptonica-$LEPT_VERSION.tar.gz \
      leptonica-$LEPT_VERSION.tar.gz $LEPT_SHA256
fetch https://download.osgeo.org/libtiff/tiff-$TIFF_VERSION.tar.xz tiff-$TIFF_VERSION.tar.xz $TIFF_SHA256
fetch https://download.osgeo.org/libtiff/tiff-$TIFF_VERSION.tar.xz.sig tiff-$TIFF_VERSION.tar.xz.sig
fetch https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$JPEG_VERSION/libjpeg-turbo-$JPEG_VERSION.tar.gz \
      libjpeg-turbo-$JPEG_VERSION.tar.gz $JPEG_SHA256
fetch https://github.com/libjpeg-turbo/libjpeg-turbo/releases/download/$JPEG_VERSION/libjpeg-turbo-$JPEG_VERSION.tar.gz.sig \
      libjpeg-turbo-$JPEG_VERSION.tar.gz.sig
if command -v gpg >/dev/null; then
    gnupg=$(mktemp -d); trap 'rm -rf "$gnupg"' EXIT
    verify() {   # verify <name> <datei> <signatur> <fingerprint>
        curl -fsSL "https://keys.openpgp.org/vks/v1/by-fingerprint/$4" | GNUPGHOME=$gnupg gpg -q --import
        GNUPGHOME=$gnupg gpg -q --status-fd 1 --verify "$DL/$3" "$DL/$2" \
            | grep -q "VALIDSIG $4" || { echo "$1: Signatur passt nicht zu $4" >&2; exit 1; }
        echo "$1: Signatur gueltig ($4)"
    }
    verify zlib zlib-$ZLIB_VERSION.tar.xz zlib-$ZLIB_VERSION.tar.xz.asc $ZLIB_KEY
    verify libtiff tiff-$TIFF_VERSION.tar.xz tiff-$TIFF_VERSION.tar.xz.sig $TIFF_KEY
    verify libjpeg-turbo libjpeg-turbo-$JPEG_VERSION.tar.gz libjpeg-turbo-$JPEG_VERSION.tar.gz.sig $JPEG_KEY
fi
# Tesseract: Tag klonen, Commit pruefen (Git-Hash sichert den Inhalt), daraus den Quell-Tarball
tesstar=$DL/tesseract-$TESS_VERSION.tar.xz
if [ ! -f "$tesstar" ]; then
    rm -rf "$DL/tesseract-git"
    git clone -q --depth 1 --branch "$TESS_VERSION" https://github.com/tesseract-ocr/tesseract "$DL/tesseract-git"
    [ "$(git -C "$DL/tesseract-git" rev-parse HEAD)" = "$TESS_COMMIT" ] || { echo "Tesseract: Commit passt nicht" >&2; exit 1; }
    git -C "$DL/tesseract-git" archive --format=tar --prefix="tesseract-$TESS_VERSION/" HEAD | xz -9 -T1 > "$tesstar"
    rm -rf "$DL/tesseract-git"
fi
for l in "${!TESSDATA[@]}"; do
    fetch "https://raw.githubusercontent.com/tesseract-ocr/tessdata_fast/$TESSDATA_COMMIT/$l.traineddata" "$l.traineddata" "${TESSDATA[$l]}"
done

rm -rf "$WORK"; mkdir -p "$WORK/src" "$PREFIX"
for t in zlib-$ZLIB_VERSION.tar.xz libpng-$PNG_VERSION.tar.xz leptonica-$LEPT_VERSION.tar.gz tesseract-$TESS_VERSION.tar.xz \
         tiff-$TIFF_VERSION.tar.xz libjpeg-turbo-$JPEG_VERSION.tar.gz; do
    tar -xf "$DL/$t" -C "$WORK/src"
done

# Pfade nicht in die Programme schreiben (__FILE__ in Meldungen), sonst haengt das Ergebnis vom Bauordner ab
# TESSERACT_DISABLE_DEBUG_FONTS (vorgesehener Schalter in src/ccstruct/debugpixa.h): Tesseract laedt Leptonicas
# Bitmap-Schrift fuer Debug-Bilder sonst bei JEDEM Lauf - die ist als TIFF eingebettet, ohne libtiff stuenden
# auf stderr vier Zeilen "Error in pixReadMemTiff ... / bmfCreate ...". Fuer die Erkennung wird sie nie gebraucht.
FLAGS="-O2 -ffile-prefix-map=$WORK=/build -DTESSERACT_DISABLE_DEBUG_FONTS"
CMAKE_COMMON=(-DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX"
              -DCMAKE_C_FLAGS="$FLAGS" -DCMAKE_CXX_FLAGS="$FLAGS" -DBUILD_SHARED_LIBS=OFF)
case "$TARGET" in
    win64)
        cat > "$WORK/mingw.cmake" <<EOF
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)
set(CMAKE_C_COMPILER x86_64-w64-mingw32-gcc-win32)
set(CMAKE_CXX_COMPILER x86_64-w64-mingw32-g++-win32)
set(CMAKE_RC_COMPILER x86_64-w64-mingw32-windres)
set(CMAKE_FIND_ROOT_PATH $PREFIX /usr/x86_64-w64-mingw32)
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
EOF
        # LEPT_TIFF_RESULT: try_run geht beim Cross-Compile nicht - Leptonica hat ohnehin kein TIFF (1 = nein)
        # LEPT_TIFF_RESULT=0: Leptonica hat (ab r4) TIFF - der try_run der Tesseract-Konfiguration geht beim Cross-Compile nicht
        CMAKE_COMMON+=(-DCMAKE_TOOLCHAIN_FILE="$WORK/mingw.cmake" -DLEPT_TIFF_RESULT=0)
        LDFLAGS_EXE="-static -static-libgcc -static-libstdc++ -Wl,--no-insert-timestamp"
        STRIP=x86_64-w64-mingw32-strip; EXE=.exe ;;
    linux64)
        LDFLAGS_EXE="-static-libgcc -static-libstdc++"
        STRIP=strip; EXE= ;;
    *) echo "unbekanntes Ziel: $TARGET" >&2; exit 1 ;;
esac

# --- zlib, libpng, libjpeg-turbo, libtiff, Leptonica, Tesseract ---
cmake -S "$WORK/src/zlib-$ZLIB_VERSION" -B "$WORK/b-zlib" "${CMAKE_COMMON[@]}" -DZLIB_BUILD_SHARED=OFF -DZLIB_BUILD_TESTING=OFF >/dev/null
cmake --build "$WORK/b-zlib" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-zlib" >/dev/null
# zlib 1.3.2 nennt die statische Bibliothek je nach Ziel unterschiedlich - fuer FindZLIB vereinheitlichen
for z in "$PREFIX"/lib/libzs.a "$PREFIX"/lib/libzlibstatic.a; do [ -f "$z" ] && cp "$z" "$PREFIX/lib/libz.a"; done
rm -f "$PREFIX"/lib/libz.so* "$PREFIX"/lib/libzlib.dll.a "$PREFIX"/bin/*zlib*.dll 2>/dev/null || true

cmake -S "$WORK/src/libpng-$PNG_VERSION" -B "$WORK/b-png" "${CMAKE_COMMON[@]}" -DPNG_SHARED=OFF -DPNG_STATIC=ON \
      -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_FRAMEWORK=OFF -DZLIB_ROOT="$PREFIX" -DZLIB_USE_STATIC_LIBS=ON >/dev/null
cmake --build "$WORK/b-png" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-png" >/dev/null

# libjpeg-turbo (ab r4): nur die Bibliothek, statisch, mit SIMD (nasm), ohne TurboJPEG-API und Werkzeuge
cmake -S "$WORK/src/libjpeg-turbo-$JPEG_VERSION" -B "$WORK/b-jpeg" "${CMAKE_COMMON[@]}" -DENABLE_SHARED=OFF -DENABLE_STATIC=ON \
      -DWITH_TURBOJPEG=OFF -DWITH_TOOLS=OFF -DWITH_TESTS=OFF -DWITH_FUZZ=OFF -DCMAKE_INSTALL_LIBDIR=lib >/dev/null
cmake --build "$WORK/b-jpeg" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-jpeg" >/dev/null

# libtiff (ab r4): nur, was Scanner und Faxe liefern - CCITT G3/G4, LZW, PackBits, Deflate (zlib), JPEG.
# Aus: Old-JPEG, 12-Bit-JPEG, LZMA, ZSTD, WebP, JBIG, LERC, libdeflate, PixarLog, ThunderScan, NeXT,
# LogLuv, MDI, C++-API, Werkzeuge, Tests, Doku.
cmake -S "$WORK/src/tiff-$TIFF_VERSION" -B "$WORK/b-tiff" "${CMAKE_COMMON[@]}" -Dtiff-static=ON \
      -Dtiff-tools=OFF -Dtiff-tests=OFF -Dtiff-contrib=OFF -Dtiff-docs=OFF -Dtiff-cxx=OFF -Dsphinx=OFF \
      -Dccitt=ON -Dlzw=ON -Dpackbits=ON -Dzlib=ON -Djpeg=ON -Dold-jpeg=OFF -Djpeg12=OFF \
      -Dlzma=OFF -Dzstd=OFF -Dwebp=OFF -Djbig=OFF -Dlerc=OFF -Dlibdeflate=OFF -Dpixarlog=OFF \
      -Dthunder=OFF -Dnext=OFF -Dlogluv=OFF -Dmdi=OFF \
      -DZLIB_ROOT="$PREFIX" -DJPEG_ROOT="$PREFIX" >/dev/null
cmake --build "$WORK/b-tiff" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-tiff" >/dev/null
# tiff-targets.cmake nennt ZLIB::ZLIB/JPEG::JPEG, laedt sie aber nicht (kein find_dependency) - Leptonica
# und Tesseract scheitern daran. Durch die festen Pfade der statischen Bibliotheken ersetzen.
sed -i -e "s|\\\\\\\$<LINK_ONLY:ZLIB::ZLIB>|$PREFIX/lib/libz.a|g" \
       -e "s|\\\\\\\$<LINK_ONLY:JPEG::JPEG>|$PREFIX/lib/libjpeg.a|g" "$PREFIX"/lib/cmake/tiff/tiff-targets.cmake
grep -q '::' <(grep INTERFACE_LINK_LIBRARIES "$PREFIX"/lib/cmake/tiff/tiff-targets.cmake) \
    && { echo "tiff-targets.cmake enthaelt noch fremde Ziele" >&2; exit 1; }

cmake -S "$WORK/src/leptonica-$LEPT_VERSION" -B "$WORK/b-lept" "${CMAKE_COMMON[@]}" -DSW_BUILD=OFF -DBUILD_PROG=OFF \
      -DENABLE_ZLIB=ON -DENABLE_PNG=ON -DENABLE_GIF=OFF -DENABLE_JPEG=ON -DENABLE_TIFF=ON -DENABLE_WEBP=OFF \
      -DENABLE_OPENJPEG=OFF -DZLIB_ROOT="$PREFIX" | tee "$WORK/lept-cmake.log" | grep -iE "tiff|jpeg|png|zlib" || true
cmake --build "$WORK/b-lept" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-lept" >/dev/null
if grep -q '::' <(grep INTERFACE_LINK_LIBRARIES "$PREFIX"/lib/cmake/leptonica/*.cmake); then
    echo "LeptonicaTargets.cmake enthaelt fremde Ziele" >&2; exit 1
fi
# Leptonica haengt unter MinGW auch an die STATISCHE Bibliothek "-1.87.0.dll" an (SUFFIX) - es ist ein ar-Archiv
for f in "$PREFIX"/lib/libleptonica*; do
    case "$(head -c 7 "$f")" in '!<arch>') ;; *) echo "Leptonica: $f ist keine statische Bibliothek" >&2; exit 1 ;; esac
done

# Tesseract linkt unter Windows "Ws2_32" - mingw unter Linux heisst libws2_32.a (Gross-/Kleinschreibung)
if [ "$TARGET" = win64 ]; then
    ln -sf /usr/x86_64-w64-mingw32/lib/libws2_32.a "$PREFIX/lib/libWs2_32.a"
    LDFLAGS_EXE="$LDFLAGS_EXE -L$PREFIX/lib"
fi
TESS_OPTS=(-DSW_BUILD=OFF -DOPENMP_BUILD=OFF -DGRAPHICS_DISABLED=ON -DBUILD_TRAINING_TOOLS=OFF -DBUILD_TESTS=OFF
           -DDISABLE_TIFF=OFF -DDISABLE_ARCHIVE=ON -DDISABLE_CURL=ON -DENABLE_LTO=OFF -DENABLE_NATIVE=OFF
           -DENABLE_PRECOMPILED_HEADERS=OFF -DENABLE_CCACHE=OFF -DENABLE_UNITY_BUILD=OFF -DINSTALL_CONFIGS=OFF
           -DLeptonica_DIR="$PREFIX/lib/cmake/leptonica" -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS_EXE")
cmake -S "$WORK/src/tesseract-$TESS_VERSION" -B "$WORK/b-tess" "${CMAKE_COMMON[@]}" "${TESS_OPTS[@]}" | tee "$WORK/tess-cmake.log"
cmake --build "$WORK/b-tess" -j "$JOBS"
cmake --install "$WORK/b-tess" >/dev/null

# --- Paket: tesseract.exe, tessdata (fast), Lizenzen, Bauoptionen ---
name=tesseract-$TESS_VERSION-wipp-minimal-$BUILD_REV-$TARGET
pkg=$OUT/$name
rm -rf "$pkg" "$pkg.zip"; mkdir -p "$pkg/tessdata" "$pkg/LICENSES"
cp "$PREFIX/bin/tesseract$EXE" "$pkg/"
"$STRIP" "$pkg/tesseract$EXE"
for l in deu eng osd; do cp "$DL/$l.traineddata" "$pkg/tessdata/"; done
# pdf.ttf (GlyphLessFont, 572 Byte, Apache-2.0 wie Tesseract): Schrift der unsichtbaren Textebene bei
# PDF-Ausgabe (textonly_pdf, "Scans durchsuchbar machen"). Tesseract 5.5 hat sie zwar als Rueckfall
# eingebaut (src/api/pdf_ttf.h), der Renderer liest aber zuerst <tessdata>/pdf.ttf - so ist es eindeutig.
cp "$WORK/src/tesseract-$TESS_VERSION/tessdata/pdf.ttf" "$pkg/tessdata/"
cp "$WORK/src/tesseract-$TESS_VERSION/LICENSE"      "$pkg/LICENSES/tesseract-LICENSE.txt"
cp "$WORK/src/leptonica-$LEPT_VERSION/leptonica-license.txt" "$pkg/LICENSES/leptonica-LICENSE.txt"
cp "$WORK/src/libpng-$PNG_VERSION/LICENSE"          "$pkg/LICENSES/libpng-LICENSE.txt"
cp "$WORK/src/zlib-$ZLIB_VERSION/LICENSE"           "$pkg/LICENSES/zlib-LICENSE.txt"
cp "$WORK/src/tiff-$TIFF_VERSION/LICENSE.md"        "$pkg/LICENSES/libtiff-LICENSE.md"
cp "$WORK/src/libjpeg-turbo-$JPEG_VERSION/LICENSE.md" "$pkg/LICENSES/libjpeg-turbo-LICENSE.md"
cp "$WORK/src/libjpeg-turbo-$JPEG_VERSION/README.ijg" "$pkg/LICENSES/libjpeg-turbo-README.ijg.txt"   # IJG-Lizenz, Hinweispflicht
cp "$WORK/src/tesseract-$TESS_VERSION/LICENSE"      "$pkg/LICENSES/tessdata_fast-LICENSE.txt"   # Apache-2.0 wie Tesseract
# Die IJG-Lizenz verlangt diesen Satz in der Dokumentation des Programms
printf '%s\r\n' "tesseract.exe enthaelt libjpeg-turbo $JPEG_VERSION (IJG-Lizenz, siehe libjpeg-turbo-LICENSE.md und libjpeg-turbo-README.ijg.txt)." \
    "This software is based in part on the work of the Independent JPEG Group." > "$pkg/LICENSES/HINWEIS.txt"
{
    echo "Build $BUILD_REV, -DTESSERACT_DISABLE_DEBUG_FONTS, tessdata/pdf.ttf aus den Tesseract-Quellen"
    echo "Tesseract $TESS_VERSION (Commit $TESS_COMMIT), Leptonica $LEPT_VERSION, libpng $PNG_VERSION, zlib $ZLIB_VERSION, libtiff $TIFF_VERSION, libjpeg-turbo $JPEG_VERSION"
    echo "tessdata_fast $TESSDATA_COMMIT: deu eng osd"
    echo "Leptonica: ENABLE_ZLIB=ON ENABLE_PNG=ON ENABLE_GIF=OFF ENABLE_JPEG=ON ENABLE_TIFF=ON ENABLE_WEBP=OFF ENABLE_OPENJPEG=OFF"
    echo "libtiff: ccitt lzw packbits zlib jpeg; aus: old-jpeg jpeg12 lzma zstd webp jbig lerc libdeflate pixarlog thunder next logluv mdi cxx"
    echo "libjpeg-turbo: statisch, SIMD, ohne TurboJPEG-API und Werkzeuge"
    echo "Tesseract: ${TESS_OPTS[*]}" | sed "s#$PREFIX#<prefix>#g"
} > "$pkg/bauoptionen.txt"
cd "$OUT"
find "$name" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
find "$name" -type f | sort | zip -X -q -D "$name.zip" -@
sha256sum "$name.zip" "$name/tesseract$EXE" | tee "$name.sha256"
