# Tesseract 5.5.4 – WIPP-Minimal-Build r2 (win64) – Quellen

Zweite Revision des Minimal-Builds aus [`../5.5.4-wipp-minimal/`](../5.5.4-wipp-minimal/), ab WIPP 1.11.1. Die Quellen, Versionen und Optionen sind dieselben. Einziger Unterschied: **`-DTESSERACT_DISABLE_DEBUG_FONTS`**. Dafür sieht Tesseract in `src/ccstruct/debugpixa.h` einen Schalter vor. Ohne ihn lädt Tesseract bei jedem Lauf Leptonicas Bitmap-Schrift für Debug-Bilder. Die ist als TIFF eingebettet, und ohne libtiff standen deshalb auf stderr vier Zeilen `Error in pixReadMemTiff … / bmfCreate …`. Mit r2 bleibt stderr bei normaler Erkennung leer. Die Debug-Bilder (nur mit Debug-Parametern) haben dann keine Beschriftung.

## Dateien

| Datei | Größe | SHA-256 |
|---|---|---|
| `tesseract-5.5.4-wipp-minimal-r2-win64.zip` | 10 270 418 Byte | `903b740bc404fae9b44cc19ba6a29c55bbab0464cd532076c876f57bcafb23ee` |
| `build.sh` (`BUILD_REV=r2`) | | `40e66f85635160a9456e634f922f228caebd372d644bc58cc0f98bc8795b40ff` |
| `LICENSES/`, `bauoptionen.txt`, `SHA256SUMS` | | |

**Quell-Tarballs** (byte-gleich, deshalb nicht doppelt abgelegt): Sie liegen in [`../5.5.4-wipp-minimal/`](../5.5.4-wipp-minimal/), mit SHA-256 und Herkunft in der dortigen [Quellen.md](../5.5.4-wipp-minimal/Quellen.md):
- `tesseract-5.5.4.tar.xz`
- `leptonica-1.87.0.tar.gz`
- `libpng-1.6.59.tar.xz`
- `zlib-1.3.2.tar.xz` mit `.asc`

Lizenzen wie dort: Apache-2.0 (Tesseract, tessdata_fast), Leptonica (BSD-2-artig), libpng-2.0, zlib. GCC-Laufzeit statisch mit Runtime Library Exception.

## Nachbauen und geprüft

- **Nachbauen:** `./build.sh` mit den Werkzeugversionen aus der Quellen.md von r1. Ein zweiter Bau in einem anderen Ordner ergab bitgleich dieselbe SHA-256.
- **Geprüft:** Windows-EXE unter Wine und Linux-Build erkennen das Testbild aus r1 unverändert und fehlerfrei. stderr ist leer, Exitcode 0.
