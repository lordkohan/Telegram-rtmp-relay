#!/bin/bash

# Verificar que al menos STREAM_URL está presente
if [ -z "$STREAM_URL" ]; then
  echo "Error: STREAM_URL es obligatoria."
  exit 1
fi

echo "Iniciando relay..."
echo "Origen audio: $STREAM_URL"

# Construir la lista de RTMP URLs a partir de las variables que empiezan por RTMP_
RTMP_URLS=()
for var in $(compgen -v | grep '^RTMP_'); do
  url="${!var}"
  if [ -n "$url" ]; then
    echo "Destino encontrado: $var -> $url"
    RTMP_URLS+=("$url")
  fi
done

if [ ${#RTMP_URLS[@]} -eq 0 ]; then
  echo "Error: No se ha definido ninguna variable RTMP_ (ej. RTMP_TELEGRAM, RTMP_YOUTUBE)."
  exit 1
fi

# Preparar inputs de video si está definido VIDEO_SOURCE
if [ -n "$VIDEO_SOURCE" ]; then
  EXT="${VIDEO_SOURCE##*.}"
  if [[ "$EXT" =~ ^(jpg|jpeg|png|bmp)$ ]]; then
    VIDEO_INPUT="-loop 1 -r 5 -i $VIDEO_SOURCE"
    VIDEO_OPTS="-c:v libx264 -preset ultrafast -tune stillimage -g 5 \
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
  # Construir comando base
  CMD="ffmpeg -re -i \"$STREAM_URL\" $VIDEO_INPUT \
    -map 0:a -map 1:v \
    -c:a aac -b:a 128k -ar 44100 -ac 2 \
    $VIDEO_OPTS"

  # Añadir una salida -f flv por cada URL
  for url in "${RTMP_URLS[@]}"; do
    CMD+=" -f flv \"$url\""
  done

  echo "Ejecutando: $CMD"
  eval "$CMD"

  echo "ffmpeg se detuvo. Reintentando en 5 segundos..."
  sleep 5
done
