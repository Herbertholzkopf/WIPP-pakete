#!/usr/bin/env bash
# Minimal-Tesseract fuer WIPP (lokale Texterkennung D2c der projektvorlage).
# Tesseract + Leptonica nur mit PNG und zlib, ohne curl/libarchive/TIFF/JPEG/WebP,
# ohne OpenMP und ohne Trainingswerkzeuge, statisch. Apache-2.0 und freizuegige Lizenzen.
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
TESS_COMMIT=7e548e6eff172f38f97664afe7f7ce40db36c8d6      # Tag 5.5.4 (Commit, nicht das Tag-Objekt)
LEPT_VERSION=1.87.0
LEPT_SHA256=c73363397f96eb1295602bf44d708a994ad42046c791bf03ea0505d829bdb6a7
PNG_VERSION=1.6.59
PNG_SHA256=d80dd2a38a37f803cb9b6ac7b14bd6e74ddc3b654780a8380bdf93523fdb4389
ZLIB_VERSION=1.3.2
ZLIB_SHA256=d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3
ZLIB_KEY=5ED46A6721D365587791E2AA783FCD8E58BCAFBA            # Mark Adler
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
if command -v gpg >/dev/null; then
    gnupg=$(mktemp -d); trap 'rm -rf "$gnupg"' EXIT
    curl -fsSL "https://keys.openpgp.org/vks/v1/by-fingerprint/$ZLIB_KEY" | GNUPGHOME=$gnupg gpg -q --import
    GNUPGHOME=$gnupg gpg -q --status-fd 1 --verify "$DL/zlib-$ZLIB_VERSION.tar.xz.asc" "$DL/zlib-$ZLIB_VERSION.tar.xz" \
        | grep -q "VALIDSIG $ZLIB_KEY" || { echo "zlib: Signatur passt nicht zu $ZLIB_KEY" >&2; exit 1; }
    echo "zlib: Signatur gueltig ($ZLIB_KEY)"
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
for t in zlib-$ZLIB_VERSION.tar.xz libpng-$PNG_VERSION.tar.xz leptonica-$LEPT_VERSION.tar.gz tesseract-$TESS_VERSION.tar.xz; do
    tar -xf "$DL/$t" -C "$WORK/src"
done

# Pfade nicht in die Programme schreiben (__FILE__ in Meldungen), sonst haengt das Ergebnis vom Bauordner ab
FLAGS="-O2 -ffile-prefix-map=$WORK=/build"
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
        CMAKE_COMMON+=(-DCMAKE_TOOLCHAIN_FILE="$WORK/mingw.cmake" -DLEPT_TIFF_RESULT=1)
        LDFLAGS_EXE="-static -static-libgcc -static-libstdc++ -Wl,--no-insert-timestamp"
        STRIP=x86_64-w64-mingw32-strip; EXE=.exe ;;
    linux64)
        LDFLAGS_EXE="-static-libgcc -static-libstdc++"
        STRIP=strip; EXE= ;;
    *) echo "unbekanntes Ziel: $TARGET" >&2; exit 1 ;;
esac

# --- zlib, libpng, Leptonica (nur PNG + zlib), Tesseract ---
cmake -S "$WORK/src/zlib-$ZLIB_VERSION" -B "$WORK/b-zlib" "${CMAKE_COMMON[@]}" -DZLIB_BUILD_SHARED=OFF -DZLIB_BUILD_TESTING=OFF >/dev/null
cmake --build "$WORK/b-zlib" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-zlib" >/dev/null
# zlib 1.3.2 nennt die statische Bibliothek je nach Ziel unterschiedlich - fuer FindZLIB vereinheitlichen
for z in "$PREFIX"/lib/libzs.a "$PREFIX"/lib/libzlibstatic.a; do [ -f "$z" ] && cp "$z" "$PREFIX/lib/libz.a"; done
rm -f "$PREFIX"/lib/libz.so* "$PREFIX"/lib/libzlib.dll.a "$PREFIX"/bin/*zlib*.dll 2>/dev/null || true

cmake -S "$WORK/src/libpng-$PNG_VERSION" -B "$WORK/b-png" "${CMAKE_COMMON[@]}" -DPNG_SHARED=OFF -DPNG_STATIC=ON \
      -DPNG_TESTS=OFF -DPNG_TOOLS=OFF -DPNG_FRAMEWORK=OFF -DZLIB_ROOT="$PREFIX" -DZLIB_USE_STATIC_LIBS=ON >/dev/null
cmake --build "$WORK/b-png" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-png" >/dev/null

cmake -S "$WORK/src/leptonica-$LEPT_VERSION" -B "$WORK/b-lept" "${CMAKE_COMMON[@]}" -DSW_BUILD=OFF -DBUILD_PROG=OFF \
      -DENABLE_ZLIB=ON -DENABLE_PNG=ON -DENABLE_GIF=OFF -DENABLE_JPEG=OFF -DENABLE_TIFF=OFF -DENABLE_WEBP=OFF \
      -DENABLE_OPENJPEG=OFF -DZLIB_ROOT="$PREFIX" >/dev/null
cmake --build "$WORK/b-lept" -j "$JOBS" >/dev/null && cmake --install "$WORK/b-lept" >/dev/null
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
           -DDISABLE_TIFF=ON -DDISABLE_ARCHIVE=ON -DDISABLE_CURL=ON -DENABLE_LTO=OFF -DENABLE_NATIVE=OFF
           -DENABLE_PRECOMPILED_HEADERS=OFF -DENABLE_CCACHE=OFF -DENABLE_UNITY_BUILD=OFF -DINSTALL_CONFIGS=OFF
           -DLeptonica_DIR="$PREFIX/lib/cmake/leptonica" -DCMAKE_EXE_LINKER_FLAGS="$LDFLAGS_EXE")
cmake -S "$WORK/src/tesseract-$TESS_VERSION" -B "$WORK/b-tess" "${CMAKE_COMMON[@]}" "${TESS_OPTS[@]}" | tee "$WORK/tess-cmake.log"
cmake --build "$WORK/b-tess" -j "$JOBS"
cmake --install "$WORK/b-tess" >/dev/null

# --- Paket: tesseract.exe, tessdata (fast), Lizenzen, Bauoptionen ---
name=tesseract-$TESS_VERSION-wipp-minimal-$TARGET
pkg=$OUT/$name
rm -rf "$pkg" "$pkg.zip"; mkdir -p "$pkg/tessdata" "$pkg/LICENSES"
cp "$PREFIX/bin/tesseract$EXE" "$pkg/"
"$STRIP" "$pkg/tesseract$EXE"
for l in deu eng osd; do cp "$DL/$l.traineddata" "$pkg/tessdata/"; done
cp "$WORK/src/tesseract-$TESS_VERSION/LICENSE"      "$pkg/LICENSES/tesseract-LICENSE.txt"
cp "$WORK/src/leptonica-$LEPT_VERSION/leptonica-license.txt" "$pkg/LICENSES/leptonica-LICENSE.txt"
cp "$WORK/src/libpng-$PNG_VERSION/LICENSE"          "$pkg/LICENSES/libpng-LICENSE.txt"
cp "$WORK/src/zlib-$ZLIB_VERSION/LICENSE"           "$pkg/LICENSES/zlib-LICENSE.txt"
cp "$WORK/src/tesseract-$TESS_VERSION/LICENSE"      "$pkg/LICENSES/tessdata_fast-LICENSE.txt"   # Apache-2.0 wie Tesseract
{
    echo "Tesseract $TESS_VERSION (Commit $TESS_COMMIT), Leptonica $LEPT_VERSION, libpng $PNG_VERSION, zlib $ZLIB_VERSION"
    echo "tessdata_fast $TESSDATA_COMMIT: deu eng osd"
    echo "Leptonica: ENABLE_ZLIB=ON ENABLE_PNG=ON ENABLE_GIF=OFF ENABLE_JPEG=OFF ENABLE_TIFF=OFF ENABLE_WEBP=OFF ENABLE_OPENJPEG=OFF"
    echo "Tesseract: ${TESS_OPTS[*]}" | sed "s#$PREFIX#<prefix>#g"
} > "$pkg/bauoptionen.txt"
cd "$OUT"
find "$name" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
find "$name" -type f | sort | zip -X -q -D "$name.zip" -@
sha256sum "$name.zip" "$name/tesseract$EXE" | tee "$name.sha256"
