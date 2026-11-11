# Tesseract 5.5.4 – WIPP-Minimal-Build r3 (win64) – Quellen

Dritte Revision des Minimal-Builds, ab WIPP 1.11.2. Sie entspricht r2 ([`../5.5.4-wipp-minimal-r2/`](../5.5.4-wipp-minimal-r2/)), dazu kommt **`tessdata/pdf.ttf`**. `tesseract.exe` ist bitgleich mit r2.

`pdf.ttf` ist die „GlyphLessFont“ aus den Tesseract-Quellen (`tessdata/pdf.ttf`, 572 Byte, SHA-256 `c7845420925a23d88ed830a63957b8af85a66a8daf8d9fc90e843673b2ef1a59`, Apache-2.0 wie Tesseract, siehe `LICENSES/tesseract-LICENSE.txt`). Der PDF-Renderer setzt mit ihr die unsichtbare Textebene. Die projektvorlage braucht das für „Scans durchsuchbar machen“ (`-c tessedit_create_pdf=1 -c textonly_pdf=1`). Tesseract 5.5 hat dieselbe Schrift zwar als Rückfall eingebaut (`src/api/pdf_ttf.h`), liest aber zuerst `<tessdata>/pdf.ttf`. Mit der Datei ist die Ausgabe eindeutig.

## Dateien

| Datei | Größe | SHA-256 |
|---|---|---|
| `tesseract-5.5.4-wipp-minimal-r3-win64.zip` | 10 270 953 Byte | `9c98753fbe53a6cbcaca739c6a921613c959cee2db17b7ef2870f4d1b8d71edd` |
| `build.sh` (`BUILD_REV=r3`) | | siehe `SHA256SUMS` |
| `LICENSES/`, `bauoptionen.txt`, `SHA256SUMS` | | |

**Quell-Tarballs** liegen byte-gleich in [`../5.5.4-wipp-minimal/`](../5.5.4-wipp-minimal/), mit Herkunft und SHA-256 in der dortigen Quellen.md. `pdf.ttf` stammt aus `tesseract-5.5.4.tar.xz`.

## Nachbauen und geprüft

- **Nachbauen:** `./build.sh`. Ein zweiter Bau in einem anderen Ordner ergab bitgleich dieselbe SHA-256.
- **Geprüft:** Windows-EXE unter Wine:
  - Aufruf: `tesseract seite.png out -l deu+eng --psm 1 -c tessedit_create_txt=1 -c tessedit_create_pdf=1 -c textonly_pdf=1`
  - Ergebnis: TXT und PDF entstehen, stderr bleibt leer, Exitcode 0.
  - Die PDF enthält die Schrift mit 572 Byte (`/Length 572`).
  - `pdftotext` liest den erkannten Text (mit Umlauten und ß) wieder aus.
- **Hinweis zu Configs:** Die Konfigurationsdateien (`configs/pdf`, `configs/txt`) sind bewusst nicht enthalten. Ein Aufruf mit dem Config-Namen am Ende (`… out pdf`) meldet deshalb `read_params_file: Can't open pdf`. Die Optionen gehören direkt mit `-c` übergeben, so wie es die Vorlage tut.
