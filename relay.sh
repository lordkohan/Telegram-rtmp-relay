#!/bin/bash
if [ -z "$STREAM_URL" ] || [ -z "$RTMP_URL" ]; then
  echo "Error: STREAM_URL y RTMP_URL son obligatorias."
  exit 1
fi

echo "Iniciando relay..."
echo "Origen audio: $STREAM_URL"
echo "Destino RTMP: $RTMP_URL"

# Configuración de video (si existe VIDEO_SOURCE)
if [ -n "$VIDEO_SOURCE" ]; then
  EXT="${VIDEO_SOURCE##*.}"
  if [[ "$EXT" =~ ^(jpg|jpeg|png|bmp)$ ]]; then
    VIDEO_INPUT="-loop 1 -i $VIDEO_SOURCE"
    # Codificación ligera con keyframes cada 1 s, resolución 640x360
    VIDEO_OPTS="-c:v libx264 -preset ultrafast -tune stillimage -r 5 -g 5 \
                 -vf scale=640:360 -pix_fmt yuv420p -b:v 200k -maxrate 250k -bufsize 500k"
    echo "Usando imagen estática: $VIDEO_SOURCE"
  else
    VIDEO_INPUT="-stream_loop -1 -i $VIDEO_SOURCE"
    VIDEO_OPTS="-c:v libx264 -preset ultrafast -r 15 -g 30 \
                 -vf scale=640:360 -pix_fmt yuv420p -b:v 500k -maxrate 600k -bufsize 1M"
    echo "Usando video en bucle: $VIDEO_SOURCE"
  fi
else
  echo "Sin fuente de video, transmitiendo solo audio."
fi

while true; do
  if [ -n "$VIDEO_SOURCE" ]; then
    # Importante: -rtmp_live live para que el servidor sepa que es un stream en vivo
    ffmpeg -re -i "$STREAM_URL" $VIDEO_INPUT \
      -map 0:a -map 1:v \
      -c:a aac -b:a 128k -ar 44100 -ac 2 \
      $VIDEO_OPTS \
      -rtmp_live live -f flv "$RTMP_URL"
  else
    ffmpeg -re -i "$STREAM_URL" \
      -c:a aac -b:a 128k -ar 44100 -ac 2 \
      -rtmp_live live -f flv "$RTMP_URL"
  fi
  echo "ffmpeg se detuvo. Reintentando en 5 segundos..."
  sleep 5
done
