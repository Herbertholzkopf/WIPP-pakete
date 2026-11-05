# WIPP-pakete

Pakete, die [WIPP](https://github.com/Herbertholzkopf/WIPP) (Windows IIS PostgreSQL & PHP) mitliefert, mit dem vollständigen Quellcode dazu. Das Repository ist öffentlich, damit Quellcode und Lizenz für jeden verfügbar sind, der eine WIPP-EXE erhält.

| Ordner | Inhalt | ab WIPP |
|---|---|---|
| [`ffmpeg/9.0.2-wipp-minimal/`](ffmpeg/9.0.2-wipp-minimal/) | FFmpeg 9.0.2, eigener Minimal-Build für die Audio-Transkription (win64, statisch, LGPL-2.1+), Quell-Tarball samt Signatur, Bauskript – siehe [Quellen.md](ffmpeg/9.0.2-wipp-minimal/Quellen.md) | 1.9 |
| [`tesseract/5.5.4-wipp-minimal/`](tesseract/5.5.4-wipp-minimal/) | Tesseract 5.5.4 mit Leptonica 1.87.0, libpng 1.6.59, zlib 1.3.2 (nur PNG), eigener Minimal-Build (win64, statisch, Apache-2.0 u. a.), tessdata_fast deu/eng/osd, alle Quellen, Bauskript – siehe [Quellen.md](tesseract/5.5.4-wipp-minimal/Quellen.md) | 1.10 |
| [`tesseract/5.5.4-wipp-minimal-r2/`](tesseract/5.5.4-wipp-minimal-r2/) | wie oben, Revision r2: ohne Debug-Schrift (`-DTESSERACT_DISABLE_DEBUG_FONTS`), keine Leptonica-Meldungen auf stderr; Quell-Tarballs im Ordner darüber – siehe [Quellen.md](tesseract/5.5.4-wipp-minimal-r2/Quellen.md) | 1.11.1 |

Regeln:

- Jeder Paketstand kommt in einen **neuen** Ordner.
- Vorhandene Dateien werden nie geändert oder gelöscht, damit ältere WIPP-Versionen ihre Quelle und die feste SHA-256 behalten.
