#!/usr/bin/env bash
# Minimal-FFmpeg fuer WIPP (Audio-Transkription D5 der projektvorlage).
# Ohne Fremdbibliotheken, ohne Netzwerk, statisch, LGPL-2.1-or-later.
#
#   ./build.sh               Windows x64 (mingw-w64, Cross-Compile)    -> out/win64/
#   ./build.sh linux64       gleiche Komponenten nativ (nur zum Testen) -> out/linux64/
#
# Voraussetzung (Ubuntu 24.04): apt-get install gcc-mingw-w64-x86-64-win32 \
#   binutils-mingw-w64-x86-64 make nasm curl gpg xz-utils zip
# Getestet mit gcc-mingw-w64-x86-64-win32 13.2.0-6ubuntu1+26.1,
# binutils-mingw-w64-x86-64 2.41.90.20240122-1ubuntu1+11.4, mingw-w64-x86-64-dev 11.0.1-3build1.
set -euo pipefail

FF_VERSION=9.0.2
FF_SHA256=8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e
FF_KEY=FCF986EA15E6E293A5644F10B4322F04D67658D8   # FFmpeg release signing key
FF_URL=https://ffmpeg.org/releases/ffmpeg-$FF_VERSION.tar.xz
TARGET=${1:-win64}

HERE=$(cd "$(dirname "$0")" && pwd)
WORK=$HERE/work/$TARGET
OUT=$HERE/out/$TARGET
DL=$HERE/work/dl
mkdir -p "$DL" "$OUT"
export SOURCE_DATE_EPOCH=1777593600   # fester Wert statt Bauzeit (reproduzierbar)
export LC_ALL=C TZ=UTC

# --- Quellen: SHA-256 fest, dazu die Signatur des Release-Schluessels ---
tarball=$DL/ffmpeg-$FF_VERSION.tar.xz
[ -f "$tarball" ] || curl -fsSL -o "$tarball" "$FF_URL"
[ -f "$tarball.asc" ] || curl -fsSL -o "$tarball.asc" "$FF_URL.asc"
echo "$FF_SHA256  $tarball" | sha256sum -c -
if command -v gpg >/dev/null; then
    gnupg=$(mktemp -d); trap 'rm -rf "$gnupg"' EXIT
    curl -fsSL https://ffmpeg.org/ffmpeg-devel.asc | GNUPGHOME=$gnupg gpg -q --import
    GNUPGHOME=$gnupg gpg -q --status-fd 1 --verify "$tarball.asc" "$tarball" | grep -q "VALIDSIG $FF_KEY" \
        || { echo "Signatur passt nicht zu $FF_KEY" >&2; exit 1; }
    echo "Signatur gueltig ($FF_KEY)"
fi

rm -rf "$WORK"; mkdir -p "$WORK"
tar -xJf "$tarball" -C "$WORK"
cd "$WORK/ffmpeg-$FF_VERSION"

# --- Komponenten: genau das, was src/Support/Ffmpeg.php der projektvorlage nutzt ---
# Demuxer = Ffmpeg::DEMUXERS, Decoder = Ffmpeg::DECODERS (ohne libopus), Ausgabe FLAC 16 kHz mono,
# -f null fuer die Dauermessung (dessen Standard-Encoder ist pcm_s16le), silencedetect + ametadata
# fuer die Stillesuche, -ss/-t ueber atrim. Protokolle nur file und pipe (-progress pipe:1).
# Die Programme ffmpeg/ffprobe ziehen selbst noch einige Filter nach (buffer, format, trim, crop,
# hflip/vflip/transpose/rotate fuer -autorotate, null) - ohne Decoder fuer Video bleiben die ungenutzt.
# Bewusst NICHT: lavfi/avdevice, hls, concat, image2, http/tcp/udp, Video-Decoder, Fremdbibliotheken.
DEMUXERS=mov,matroska,ogg,wav,mp3,aac,flac,amr
DECODERS=aac,aac_fixed,alac,mp3,mp3float,opus,vorbis,flac,amrnb,amrwb
DECODERS=$DECODERS,pcm_s16le,pcm_s16be,pcm_s24le,pcm_s24be,pcm_s32le,pcm_f32le,pcm_f64le,pcm_u8,pcm_alaw,pcm_mulaw
PARSERS=aac,aac_latm,mpegaudio,flac,opus,vorbis,amr
ENCODERS=flac,pcm_s16le
MUXERS=flac,wav,null
FILTERS=abuffer,abuffersink,aresample,aformat,anull,atrim,silencedetect,ametadata
PROTOCOLS=file,pipe

opts=(
    --disable-everything --disable-autodetect --disable-network
    --disable-doc --disable-debug --disable-ffplay --disable-avdevice --disable-swscale
    --enable-static --disable-shared --enable-ffmpeg --enable-ffprobe
    --enable-demuxer=$DEMUXERS --enable-decoder=$DECODERS --enable-parser=$PARSERS
    --enable-encoder=$ENCODERS --enable-muxer=$MUXERS --enable-filter=$FILTERS --enable-protocol=$PROTOCOLS
    --enable-swresample
)
case "$TARGET" in
    win64) opts+=(--target-os=mingw32 --arch=x86_64 --cross-prefix=x86_64-w64-mingw32-
                  "--extra-ldflags=-static -Wl,--no-insert-timestamp") ;;
    linux64) ;;
    *) echo "unbekanntes Ziel: $TARGET" >&2; exit 1 ;;
esac

./configure --prefix=/usr/local "${opts[@]}" | tee "$WORK/configure.log"
make -j"$(nproc)"
make install DESTDIR="$WORK/inst" >/dev/null

# --- Paket: ffmpeg, ffprobe, LICENSE, configure-Zeile ---
exe=; strip=strip
if [ "$TARGET" = win64 ]; then exe=.exe; strip=x86_64-w64-mingw32-strip; fi
name=ffmpeg-$FF_VERSION-wipp-minimal-$TARGET
pkg=$OUT/$name
rm -rf "$pkg" "$pkg.zip"; mkdir -p "$pkg/bin"
cp "$WORK/inst/usr/local/bin/ffmpeg$exe" "$WORK/inst/usr/local/bin/ffprobe$exe" "$pkg/bin/"
"$strip" "$pkg/bin/"*
cp COPYING.LGPLv2.1 "$pkg/LICENSE.txt"
sed -n 's/^#define FFMPEG_CONFIGURATION "\(.*\)"$/\1/p' config.h > "$pkg/configure-optionen.txt"
cd "$OUT"
find "$name" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
find "$name" -type f | sort | zip -X -q -D "$name.zip" -@
sha256sum "$name.zip" "$name"/bin/* | tee "$name.sha256"
