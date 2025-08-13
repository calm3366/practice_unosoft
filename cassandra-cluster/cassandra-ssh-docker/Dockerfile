# Используем официальный образ Cassandra в качестве базового
FROM cassandra:latest
# Устанавливаем OpenSSH server
# && rm -rf /var/lib/apt/lists/* - очищаем кэш apt, чтобы уменьшить размер образа
RUN apt-get update && apt-get install -y openssh-server \
    && rm -rf /var/lib/apt/lists/*
# генерируем ключи
RUN ssh-keygen -A
# Создаем директорию для PID-файлов SSH, если она не существует (необходимо для sshd)
RUN mkdir -p /run/sshd
# Устанавливаем пароль для пользователя 'cassandra'.
RUN echo 'cassandra:password' | chpasswd
# Демонстрируем открытый порт для SSH
EXPOSE 22
# Копируем наш кастомный скрипт entrypoint
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# Делаем скрипт исполняемым
RUN chmod +x /usr/local/bin/entrypoint.sh
# Устанавливаем наш скрипт как точку входа.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
# Команда Cassandra, которая будет передана нашему entrypoint скрипту
CMD ["cassandra", "-f"]