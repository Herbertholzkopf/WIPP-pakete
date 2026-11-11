# Tesseract 5.5.4 – WIPP-Minimal-Build r4 (win64) – Quellen

Vierte Revision des Minimal-Builds, ab WIPP 1.11.3. Sie entspricht r3 ([`../5.5.4-wipp-minimal-r3/`](../5.5.4-wipp-minimal-r3/): `-DTESSERACT_DISABLE_DEBUG_FONTS`, `tessdata/pdf.ttf`), dazu liest Leptonica jetzt **TIFF** (libtiff 4.7.2) und **JPEG** (libjpeg-turbo 3.2.1). Die projektvorlage gibt damit mehrseitige TIFF-Scans direkt an Tesseract (`ImagePdf`: eine PDF mit allen Seiten, Bild und Textebene).

## Dateien

| Datei | Größe | SHA-256 | Inhalt |
|---|---|---|---|
| `tesseract-5.5.4-wipp-minimal-r4-win64.zip` | 10 754 008 Byte | `ea6385a6f0f92065814b56e8d59f8752b80c18758526573b763507fd2798648a` | `tesseract.exe` (8,3 MB, statisch), `tessdata/` (deu, eng, osd, pdf.ttf), `LICENSES/`, `bauoptionen.txt` |
| `tiff-4.7.2.tar.xz` und `.sig` | 2 409 652 Byte | `4996f0c4f93094719b1ca5c6279b20e588773ba8a247533e486416fb662ddb88` | unverändert von download.osgeo.org/libtiff, Signatur von Even Rouault (`B1FA 7D81 EEB8 E663 9917 8B97 33EB BFC4 7B3D D87D`) |
| `libjpeg-turbo-3.2.1.tar.gz` und `.sig` | 2 549 854 Byte | `c27ad72a68da151177929aa969ae773a2da5ac2af9ce946079314fdac8cece7f` | unverändert von github.com/libjpeg-turbo/libjpeg-turbo/releases/tag/3.2.1, Signatur des libjpeg-turbo-Projekts (`0338 C8D8 D9FD A62C F9C4 21BD 7EC2 DBB6 F4DB F434`) |
| `build.sh` (`BUILD_REV=r4`) | | siehe `SHA256SUMS` | Bauskript (auch in WIPP unter `tools/tesseract-minimal/`) |
| `LICENSES/`, `bauoptionen.txt`, `SHA256SUMS` | | | wie im ZIP; Prüfsummen zum Nachrechnen |

Die übrigen **Quell-Tarballs** (Tesseract, Leptonica, libpng, zlib) liegen byte-gleich in [`../5.5.4-wipp-minimal/`](../5.5.4-wipp-minimal/), mit Herkunft und SHA-256 in der dortigen Quellen.md. `build.sh` prüft alle Tarballs gegen feste SHA-256 und, wo veröffentlicht, die Signatur (zlib, libtiff, libjpeg-turbo).

## Lizenzen

| Teil | Lizenz |
|---|---|
| Tesseract 5.5.4, tessdata_fast, `pdf.ttf` | Apache-2.0 |
| Leptonica 1.87.0 | Leptonica-Lizenz (BSD-2-artig) |
| libpng 1.6.59 | PNG Reference Library License v2 |
| zlib 1.3.2 | zlib-Lizenz |
| libtiff 4.7.2 | libtiff-Lizenz (BSD-artig, Sam Leffler / Silicon Graphics), `LICENSES/libtiff-LICENSE.md` |
| libjpeg-turbo 3.2.1 | IJG-Lizenz (libjpeg-API, hier genutzt) und BSD-3-Clause, `LICENSES/libjpeg-turbo-LICENSE.md`, `LICENSES/libjpeg-turbo-README.ijg.txt` |
| GCC- und mingw-w64-Laufzeit (statisch) | wie in r1 |

Die IJG-Lizenz verlangt in der Dokumentation den Hinweis:

> This software is based in part on the work of the Independent JPEG Group.

Er steht im ZIP in `LICENSES/HINWEIS.txt` und in der WIPP-README. Kein LGPL- oder GPL-Teil.

## Inhalt des Builds

- **libtiff:** CCITT G3/G4, LZW, PackBits, Deflate (zlib), JPEG (libjpeg-turbo). Aus: Old-JPEG, 12-Bit-JPEG, LZMA, ZSTD, WebP, JBIG, LERC, libdeflate, PixarLog, ThunderScan, NeXT, LogLuv, MDI, C++-Schnittstelle, Werkzeuge.
- **libjpeg-turbo:** statisch, mit SIMD, ohne TurboJPEG-API und Werkzeuge.
- **Leptonica:** zlib, PNG, JPEG, TIFF; kein GIF, WebP, JPEG 2000.
- **Tesseract:** wie r3, dazu `-DDISABLE_TIFF=OFF` (mehrseitige TIFFs). `tesseract.exe` braucht weiter nur `KERNEL32.dll` und `msvcrt.dll`.
- **Bauhinweis:** `tiff-targets.cmake` von libtiff nennt die Ziele `ZLIB::ZLIB` und `JPEG::JPEG`, lädt sie aber nicht. `build.sh` ersetzt sie nach der Installation durch die Pfade der statischen Bibliotheken; an den Quellen ändert das nichts.

## Nachbauen und geprüft

- **Nachbauen:** `./build.sh` (Ubuntu 24.04, Werkzeuge wie in r1). Ein zweiter Bau in einem anderen Ordner ergab bitgleich dieselbe SHA-256.
- **`tesseract --version`:** `libjpeg 6b (libjpeg-turbo 3.2.1) : libpng 1.6.59 : libtiff 4.7.2 : zlib 1.3.2`.
- **Geprüft:** Windows-EXE unter Wine, je ein dreiseitiges TIFF mit CCITT G4, LZW und JPEG-Kompression:
  - Aufruf: `tesseract scan.tif out -l deu+eng -c tessedit_create_pdf=1`
  - Ergebnis: Exitcode 0, PDF mit **3 Seiten**, je Seite das Bild (G4 als CCITT, JPEG als JPEG übernommen) und die Textebene; `pdftotext` liest alle drei Seiten fehlerfrei (mit Umlauten und ß).
  - Mit `-c textonly_pdf=1`: 3 Seiten ohne Bild, gleicher Text.
  - Einseitiges TIFF und JPEG-Datei: ebenso erkannt.
  - stderr: **keine** `pixReadMemTiff`-Meldungen. Bei mehrseitigen TIFFs schreibt Tesseract je Seite `Page N` (so vorgesehen, `src/api/baseapi.cpp`); mit `-c debug_file=nul` bleibt stderr leer.
