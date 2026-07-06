#!/bin/bash
if [ -z "$STREAM_URL" ] || [ -z "$RTMP_URL" ]; then
  echo "Error: STREAM_URL y RTMP_URL son obligatorias."
  exit 1
fi

echo "Iniciando relay..."
echo "Origen audio: $STREAM_URL"
echo "Destino RTMP: $RTMP_URL"

# Si no se define VIDEO_SOURCE, solo audio; si se define, se usará como fuente de video
if [ -n "$VIDEO_SOURCE" ]; then
  # Determinar si es una imagen (extensiones comunes) para loop infinito
  EXT="${VIDEO_SOURCE##*.}"
  if [[ "$EXT" =~ ^(jpg|jpeg|png|bmp)$ ]]; then
    VIDEO_INPUT="-loop 1 -i $VIDEO_SOURCE"
    # Configuración ligera para imagen estática
    VIDEO_OPTS="-c:v libx264 -r 5 -pix_fmt yuv420p -preset ultrafast -tune stillimage -b:v 200k"
    echo "Usando imagen estática: $VIDEO_SOURCE"
  else
    # Si no es imagen, asumimos video en bucle
    VIDEO_INPUT="-stream_loop -1 -i $VIDEO_SOURCE"
    VIDEO_OPTS="-c:v libx264 -preset ultrafast -b:v 500k -r 15"
    echo "Usando video en bucle: $VIDEO_SOURCE"
  fi
else
  echo "Sin fuente de video, transmitiendo solo audio."
fi

while true; do
  if [ -n "$VIDEO_SOURCE" ]; then
    # Transmisión con video + audio
    ffmpeg -re -i "$STREAM_URL" $VIDEO_INPUT \
      -map 0:a -map 1:v \
      -c:a aac -b:a 128k -ar 44100 -ac 2 \
      $VIDEO_OPTS \
      -shortest -f flv "$RTMP_URL"
  else
    # Solo audio (modo anterior)
    ffmpeg -re -i "$STREAM_URL" \
      -c:a aac -b:a 128k -ar 44100 -ac 2 \
      -f flv "$RTMP_URL"
  fi
  echo "ffmpeg se detuvo. Reintentando en 5 segundos..."
  sleep 5
done
