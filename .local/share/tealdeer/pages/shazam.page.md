# shazam

> Modern Music Identifier for Linux using SongRec and Shazam API.
> Listens to system audio output (speakers/headphones via PipeWire monitor), not microphone.

- Recognize currently playing music from system audio:
  `shazam`

- Launch the full graphical GTK SongRec GUI:
  `shazam -g`

- Continuous listening mode in terminal (keeps recognizing new tracks):
  `shazam -c`

- Recognize song from an audio or video file:
  `shazam -f {{path/to/media_file}}`

- Output raw song recognition metadata as JSON:
  `shazam -j`

- Run silently without terminal output (notification & clipboard copy only):
  `shazam -q`
