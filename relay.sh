#!/bin/bash
if [ -z "$STREAM_URL" ] || [ -z "$RTMP_URL" ]; then
  echo "Error: STREAM_URL y RTMP_URL son obligatorias."
  exit 1
fi

echo "Iniciando relay..."
echo "Origen audio: $STREAM_URL"
echo "Destino RTMP: $RTMP_URL"

if [ -n "$VIDEO_SOURCE" ]; then
  EXT="${VIDEO_SOURCE##*.}"
  if [[ "$EXT" =~ ^(jpg|jpeg|png|bmp)$ ]]; then
    VIDEO_INPUT="-loop 1 -i $VIDEO_SOURCE"
    # Configuración ligera y compatible
    VIDEO_OPTS="-c:v libx264 -r 5 -pix_fmt yuv420p -preset ultrafast -tune stillimage -b:v 200k -maxrate 250k -bufsize 500k"
    echo "Usando imagen estática: $VIDEO_SOURCE"
  else
    VIDEO_INPUT="-stream_loop -1 -i $VIDEO_SOURCE"
    VIDEO_OPTS="-c:v libx264 -preset ultrafast -b:v 500k -r 15"
    echo "Usando video en bucle: $VIDEO_SOURCE"
  fi
else
  echo "Sin fuente de video, transmitiendo solo audio."
fi

while true; do
  if [ -n "$VIDEO_SOURCE" ]; then
    # Opciones de reconexión y sin -shortest
    ffmpeg -re -i "$STREAM_URL" $VIDEO_INPUT \
      -map 0:a -map 1:v \
      -c:a aac -b:a 128k -ar 44100 -ac 2 \
      $VIDEO_OPTS \
      -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5 \
      -f flv "$RTMP_URL"
  else
    ffmpeg -re -i "$STREAM_URL" \
      -c:a aac -b:a 128k -ar 44100 -ac 2 \
      -reconnect 1 -reconnect_at_eof 1 -reconnect_streamed 1 -reconnect_delay_max 5 \
      -f flv "$RTMP_URL"
  fi
  echo "ffmpeg se detuvo. Reintentando en 5 segundos..."
  sleep 5
done
