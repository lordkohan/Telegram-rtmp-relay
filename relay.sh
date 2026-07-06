#!/bin/bash
if [ -z "$STREAM_URL" ] || [ -z "$RTMP_URL" ]; then
  echo "Error: STREAM_URL y RTMP_URL son obligatorias."
  exit 1
fi

echo "Iniciando relay..."
echo "Origen: $STREAM_URL"
echo "Destino: $RTMP_URL"

while true; do
  ffmpeg -re -i "$STREAM_URL" \
    -c:a aac -b:a 128k -ar 44100 -ac 2 \
    -f flv "$RTMP_URL"
  echo "ffmpeg se detuvo. Reintentando en 5 segundos..."
  sleep 5
done
