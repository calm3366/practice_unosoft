#!/usr/bin/env bash
set -euo pipefail

# Параметры сети
PARENT_IF="eth1"  
SUBNET="192.168.1.0/24"
GATEWAY="192.168.1.197"
MACVLAN_NET="cassandra_macvlan_net"

SEED_IP="192.168.1.200"
NODE2_IP="192.168.1.201"
NODE3_IP="192.168.1.202"


# 0) Чистим старые контейнеры и тома вторичных нод (во избежание коллизий)
echo "Останавливаем и удаляем старые контейнеры."
docker rm -f cassandra-1 cassandra-2 cassandra-3 || true
docker volume rm cass1_data cass2_data cass3_data || true
docker volume rm cassandra-cluster_cass1_data cassandra-cluster_cass2_data cassandra-cluster_cass3_data || true


# 1) Создаём macvlan-сеть (если нет)
if ! docker network ls | grep " ${MACVLAN_NET} "; then
  echo "Создаём macvlan-сеть ${MACVLAN_NET} на ${PARENT_IF} (${SUBNET}, gw ${GATEWAY})"
  docker network create -d macvlan \
    --subnet="${SUBNET}" \
    --gateway="${GATEWAY}" \
    -o parent="${PARENT_IF}" \
    "${MACVLAN_NET}"
else
  echo "macvlan-сеть ${MACVLAN_NET} уже существует"
fi

# 2) Создаем ноды
echo "Запускаем seed-ноду cassandra-1."
docker compose up -d cassandra-1

echo "Ожидаем инициализацию cassandra-1 (60 секунд)."
sleep 60

echo "Запускаем cassandra-2."
docker compose up -d cassandra-2

echo "Ожидаем инициализацию cassandra-2 (60 секунд)."
sleep 60

echo "Запускаем cassandra-3."
docker compose up -d cassandra-3

echo "Финальная пауза для стабилизации кластера (60 секунд)."
sleep 60

# 3) Проверка сетей и IP
echo "Проверка IP адресов контейнеров:"
for n in cassandra-1 cassandra-2 cassandra-3; do
  echo -n "   $n: "
  docker inspect -f '{{.Name}} -> {{range .NetworkSettings.Networks}}{{.IPAddress}} {{end}}' "$n" || true
done

# 4) Проверка публикации портов (SSH/CQL через bridge)
echo "Ожидаю публикацию портов на хосте А."
sleep 2
ss -tlnp | grep -E '(:22200|:9042|:9043|:9044)' || echo "Порты пока не слушаются — это может занять несколько секунд."

# 5) Проверяем кластер
echo "Проверка состояния кластера:"
docker exec cassandra-1 nodetool status || true


# 6) Финальная подсказка
cat <<EOF
Готово.

- Доступ к cassandra-1 по SSH (если образ cassandra-ssh): ssh cassandra@127.0.0.1 -p 22200
- Доступ к CQL:
  - cassandra-1: 127.0.0.1:9042
  - cassandra-2: 127.0.0.1:9043
  - cassandra-3: 127.0.0.1:9044
EOF