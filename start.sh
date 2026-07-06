#!/bin/bash
# Iniciar el relay de radio en segundo plano
/usr/local/bin/relay.sh &

# Iniciar el servidor HTTP (se queda en primer plano)
python3 /usr/local/bin/server.py
