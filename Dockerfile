FROM alpine:latest

RUN apk add --no-cache ffmpeg bash python3

COPY relay.sh /usr/local/bin/relay.sh
RUN chmod +x /usr/local/bin/relay.sh

COPY server.py /usr/local/bin/server.py
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]
