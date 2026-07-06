FROM alpine:latest

RUN apk add --no-cache ffmpeg bash python3

# Establecemos el directorio de trabajo donde estarán los scripts y la imagen
WORKDIR /usr/local/bin

COPY relay.sh /usr/local/bin/relay.sh
RUN chmod +x /usr/local/bin/relay.sh

COPY server.py /usr/local/bin/server.py
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Copiamos la imagen al mismo directorio de trabajo (ajusta el nombre si es diferente)
COPY live_radio.png .

CMD ["/usr/local/bin/start.sh"]
