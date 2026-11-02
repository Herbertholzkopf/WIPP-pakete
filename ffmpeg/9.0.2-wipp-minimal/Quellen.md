# FFmpeg 9.0.2 – WIPP-Minimal-Build (win64) – Quellen

[WIPP](https://github.com/Herbertholzkopf/WIPP) ab Version 1.9 liefert diesen Build mit, eingebettet in die EXE bzw. von hier geladen. Er ist für die Audio-Transkription der projektvorlage (Baustein D5) gebaut und enthält nur, was deren Fassade `src/Support/Ffmpeg.php` nutzt.

**Lizenz:** GNU Lesser General Public License **2.1 oder später** (`LICENSE.txt`). Gebaut ohne `--enable-gpl`, `--enable-nonfree` und `--enable-version3`, ohne jede Fremdbibliothek: Der vollständige Quellcode ist allein der FFmpeg-Tarball in diesem Ordner.

## Dateien

| Datei | Größe | SHA-256 | Inhalt |
|---|---|---|---|
| `ffmpeg-9.0.2-wipp-minimal-win64.zip` | 3 122 672 Byte | `30f6156cdc99565fd86428b337488c25998c89c854dd97b56426f9b2d589e75a` | `bin/ffmpeg.exe` (3,4 MB), `bin/ffprobe.exe` (3,2 MB), `LICENSE.txt`, `configure-optionen.txt` |
| `ffmpeg-9.0.2.tar.xz` | 12 040 788 Byte | `8c3850283eb25fa026482078a04051e0be17347b09ef81a0849bec15a96e002e` | Offizieller Quell-Tarball, unverändert von https://ffmpeg.org/releases/ffmpeg-9.0.2.tar.xz |
| `ffmpeg-9.0.2.tar.xz.asc` | | | Signatur dazu, FFmpeg release signing key `FCF9 86EA 15E6 E293 A564 4F10 B432 2F04 D676 58D8` |
| `build.sh` | | `30efa8abffae33ff4f519b80277d46b8d64fa1243e09ecf8dfc90b39bb9d53cc` | Bauskript (auch in WIPP unter `tools/ffmpeg-minimal/`) |
| `LICENSE.txt` | | `246041b6ecf9bc32d718a62c57877c78b5eb397b6467e74ed7ae2626ab189c30` | `COPYING.LGPLv2.1` aus dem Tarball |
| `configure-optionen.txt` | | | `configure`-Zeile, wie `ffmpeg -version` sie zeigt |
| `SHA256SUMS` | | | Prüfsummen zum Nachrechnen |

## Inhalt des Builds

| Art | Enthalten |
|---|---|
| Demuxer | mov (mp4/m4a/3gp), matroska (webm), ogg, wav, mp3, aac, flac, amr |
| Decoder (nur Audio) | aac, aac_fixed, alac, mp3, mp3float, opus, vorbis, flac, amrnb, amrwb, pcm_s16le/be, pcm_s24le/be, pcm_s32le, pcm_f32le, pcm_f64le, pcm_u8, pcm_alaw, pcm_mulaw |
| Parser | aac, aac_latm, mpegaudio, flac, opus, vorbis, amr |
| Encoder | flac, pcm_s16le (Standard von `-f null`) |
| Muxer | flac, wav, null |
| Filter | aresample, aformat, anull, atrim, silencedetect, ametadata, abuffer/abuffersink; dazu die Filter, die die Programme selbst verlangen (buffer, format, trim, null, crop, hflip, vflip, transpose, rotate) – ohne Video-Decoder ungenutzt |
| Protokolle | file, pipe |
| Bewusst nicht | lavfi und alle Geräte (avdevice), hls, concat, image2, http/https/tcp/udp, Video-Decoder, swscale, jede Fremdbibliothek |

`ffmpeg.exe` und `ffprobe.exe` sind statisch gelinkt und brauchen nur System-DLLs (`KERNEL32`, `msvcrt`, `bcrypt`, `SHELL32`).

## Nachbauen

Unter Ubuntu 24.04:

```
apt-get install gcc-mingw-w64-x86-64-win32 binutils-mingw-w64-x86-64 make nasm curl gpg xz-utils zip
./build.sh            # -> out/win64/ffmpeg-9.0.2-wipp-minimal-win64.zip
```

Mit `gcc-mingw-w64-x86-64-win32 13.2.0-6ubuntu1+26.1`, `binutils-mingw-w64-x86-64 2.41.90.20240122-1ubuntu1+11.4` und `mingw-w64-x86-64-dev 11.0.1-3build1` entsteht bitgleich dieselbe Datei (SHA-256 wie oben, unabhängig vom Bauordner; die PE-Dateien tragen keinen Zeitstempel). `./build.sh linux64` baut dieselben Komponenten nativ für Tests.

## Geprüft

Mit dem Windows-Build (unter Wine) und dem gleich konfigurierten Linux-Build, jeweils mit den Schutzoptionen der Fassade (`-protocol_whitelist file`, `-format_whitelist`, `-codec_whitelist`, erzwungenes `-f`, `-map 0:a:0 -vn -sn -dn`):

- m4a/AAC, ADTS-AAC, mp3, ogg/Vorbis, flac, ALAC, WAV 24 Bit, AMR-NB und AMR-WB werden jeweils nach FLAC 16 kHz mono umgewandelt.
- MP4 mit Video und AAC: Nur die Tonspur wird umgewandelt, ein Video-Decoder ist gar nicht vorhanden.
- webm/Opus ohne Dauer im Kopf: Die Dauer wird per `-progress pipe:1` gemessen (5,0 s).
- Die Stillesuche (silencedetect + ametadata in eine Datei) findet die Stille von 1–2 s.
- Abgelehnt werden: MP4 ohne Tonspur, PNG, HLS-Playlist (auch als .mp3 getarnt), ffconcat und Text.
- Die Fassade `App\Support\Ffmpeg` der projektvorlage (v0.99) liefert mit diesem Build bei `load`, `version`, `isLgpl`, `probe`, `toFlac` und `silences` dieselben Ergebnisse und Meldungen, die ihre Tests erwarten.
