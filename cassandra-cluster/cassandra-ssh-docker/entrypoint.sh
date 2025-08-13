#!/bin/bash
set -e
# Запускаем SSH-сервер
/usr/sbin/sshd
# Выполняем оригинальный Docker-скрипт entrypoint Cassandra.
exec /usr/local/bin/docker-entrypoint.sh "$@"