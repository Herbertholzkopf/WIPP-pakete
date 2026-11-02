# WIPP-pakete

Pakete, die [WIPP](https://github.com/Herbertholzkopf/WIPP) (Windows IIS PostgreSQL & PHP) mitliefert, mit dem vollständigen Quellcode dazu. Das Repository ist öffentlich, damit Quellcode und Lizenz für jeden verfügbar sind, der eine WIPP-EXE erhält.

| Ordner | Inhalt | ab WIPP |
|---|---|---|
| [`ffmpeg/9.0.2-wipp-minimal/`](ffmpeg/9.0.2-wipp-minimal/) | FFmpeg 9.0.2, eigener Minimal-Build für die Audio-Transkription (win64, statisch, LGPL-2.1+), Quell-Tarball samt Signatur, Bauskript – siehe [Quellen.md](ffmpeg/9.0.2-wipp-minimal/Quellen.md) | 1.9 |

Regeln:

- Jeder Paketstand kommt in einen **neuen** Ordner.
- Vorhandene Dateien werden nie geändert oder gelöscht, damit ältere WIPP-Versionen ihre Quelle und die feste SHA-256 behalten.
