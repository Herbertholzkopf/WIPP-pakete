# Tesseract 5.5.4 – WIPP-Minimal-Build (win64) – Quellen

[WIPP](https://github.com/Herbertholzkopf/WIPP) ab Version 1.10 liefert diesen Build mit, eingebettet in die EXE bzw. von hier geladen. Er dient der lokalen Texterkennung der projektvorlage (Baustein D2c, Fassade `src/Support/Tesseract.php`). Die Vorlage gibt Tesseract **immer ein PNG**, das PHP-GD selbst erzeugt. Deshalb kann Leptonica hier nur **PNG** (mit zlib) lesen – kein JPEG, TIFF, WebP, GIF, JPEG 2000. Wer andere Formate an Tesseract geben will, wandelt vorher mit GD nach PNG um.

## Dateien

| Datei | Größe | SHA-256 | Inhalt |
|---|---|---|---|
| `tesseract-5.5.4-wipp-minimal-win64.zip` | 10 270 425 Byte | `9b823f8a28bc84c8eec63148139db5f34955d30f614cfd119ca07969447182a7` | `tesseract.exe` (6,9 MB, statisch), `tessdata/` (deu, eng, osd), `LICENSES/`, `bauoptionen.txt` |
| `tesseract-5.5.4.tar.xz` | 1 421 160 Byte | `1767b67b8354014fa5672af9f13b2b70e91992f1de6d700567407e012166fd7e` | Tesseract-Quelltext: `git archive` des Commits `7e548e6eff172f38f97664afe7f7ce40db36c8d6` (Tag 5.5.4, Tag-Objekt `c5065e4c`) aus github.com/tesseract-ocr/tesseract |
| `leptonica-1.87.0.tar.gz` | 14 802 808 Byte | `c73363397f96eb1295602bf44d708a994ad42046c791bf03ea0505d829bdb6a7` | unverändert von github.com/DanBloomberg/leptonica/releases/tag/1.87.0 |
| `libpng-1.6.59.tar.xz` | 1 074 540 Byte | `d80dd2a38a37f803cb9b6ac7b14bd6e74ddc3b654780a8380bdf93523fdb4389` | unverändert von download.sourceforge.net/libpng; Inhalt dateigleich mit dem Git-Tag `v1.6.59` (Commit `cd952f49`), eine Signatur veröffentlicht libpng dort nicht |
| `zlib-1.3.2.tar.xz` und `.asc` | 1 320 064 Byte | `d7a0654783a4da529d1bb793b7ad9c3318020af77667bcae35f95d0e42a792f3` | unverändert von zlib.net, Signatur von Mark Adler (`5ED4 6A67 21D3 6558 7791 E2AA 783F CD8E 58BC AFBA`) |
| `build.sh` | | `18afd8343bf92d26a6ba338567a629d06590f1dee3a0d308c5d62daff67487f7` | Bauskript (auch in WIPP unter `tools/tesseract-minimal/`) |
| `LICENSES/` | | | Lizenztexte, wie sie auch im ZIP liegen |
| `bauoptionen.txt` | | | Versionen und CMake-Optionen dieses Builds |
| `SHA256SUMS` | | | Prüfsummen zum Nachrechnen |

Sprachdaten: `deu`, `eng`, `osd` aus **tessdata_fast**, Commit `87416418657359cb625c412a48b6e1d6d41c29bd` (github.com/tesseract-ocr/tessdata_fast). Die SHA-256 je Datei stehen in `build.sh` und in WIPP (zusammen 16,2 MB). *tessdata_best* wäre genauer, ist aber 34,6 MB groß und etwa 2- bis 3-mal langsamer.

## Lizenzen

| Teil | Lizenz |
|---|---|
| Tesseract 5.5.4 | Apache-2.0 |
| tessdata_fast | Apache-2.0 |
| Leptonica 1.87.0 | Leptonica-Lizenz (BSD-2-artig) |
| libpng 1.6.59 | PNG Reference Library License v2 |
| zlib 1.3.2 | zlib-Lizenz |
| GCC-Laufzeit (libstdc++, libgcc; statisch) | GPL-3.0 mit GCC Runtime Library Exception – keine Pflichten für das gelinkte Programm |
| mingw-w64-Laufzeit (CRT) | gemeinfrei bzw. ZPL – win32-Threadmodell, also ohne winpthreads |

Kein LGPL- oder GPL-Teil, für den Quellcode bereitgestellt werden müsste. Die Quellen liegen trotzdem hier, damit der Build nachvollziehbar und unabhängig von den Originalquellen bleibt.

## Inhalt des Builds

- **Tesseract:** ohne Trainingswerkzeuge, ohne libcurl (keine URL-Eingaben), ohne libarchive, ohne TIFF, ohne OpenMP, ohne Grafik (ScrollView); `-DENABLE_NATIVE=OFF` (SIMD wird zur Laufzeit gewählt: SSE4.1, AVX, AVX2, FMA, AVX-512).
- **Leptonica:** nur zlib und PNG.
- **Ergebnis:** `tesseract.exe` braucht nur `KERNEL32.dll` und `msvcrt.dll`.

Hinweis: Tesseract legt bei jedem Lauf ein Debug-Objekt an, das Leptonicas eingebaute Bitmap-Schrift lädt. Die ist als TIFF hinterlegt, deshalb stehen auf stderr bis zu drei Meldungen `Error in pixReadMemTiff: function not present` / `bmfCreate: font pixa not made`. Sie haben keine Wirkung auf Erkennung und Exitcode; die Schrift würde nur für Debug-Bilder gebraucht.

## Nachbauen

Unter Ubuntu 24.04:

```
apt-get install gcc-mingw-w64-x86-64-win32 g++-mingw-w64-x86-64-win32 binutils-mingw-w64-x86-64 cmake make git curl gpg xz-utils zip
./build.sh            # -> out/win64/tesseract-5.5.4-wipp-minimal-win64.zip   (gut 2,5 Minuten mit 4 Kernen)
```

Mit `gcc/g++-mingw-w64-x86-64-win32 13.2.0-6ubuntu1+26.1`, `binutils-mingw-w64-x86-64 2.41.90.20240122-1ubuntu1+11.4`, `mingw-w64-x86-64-dev 11.0.1-3build1` und `cmake 3.28.3` entsteht bitgleich dieselbe Datei, unabhängig vom Bauordner (`-ffile-prefix-map`, PE ohne Zeitstempel, feste Dateizeiten im ZIP). `./build.sh linux64` baut dieselben Komponenten nativ für Tests.

## Geprüft

- **Erkennung:** Windows-Build (unter Wine) und gleich konfigurierter Linux-Build erkennen ein mit PHP-GD erzeugtes PNG („Rechnung Nr. 2026-0815 …“, „Größenänderung der Straßenbeleuchtung“, „Prüfung bestanden: Übergabe an Müller GmbH“, englischer Satz) fehlerfrei, mit `-l deu+eng --psm 1` wie die Vorlage.
- **Fassade der Vorlage:** `App\Support\Tesseract` (v1.00) liefert mit diesem Build `load`, `version` (5.5.4), `installedLanguages` (deu, eng, osd) und `recognize`.
- **Nur PNG:** Ein JPEG wird abgelehnt (Exitcode 1).
