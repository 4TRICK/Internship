#!/bin/bash

# Скрипт для запуска Ansible-развертывания 

set -e  # Выход при ошибке

# Проверка прав root
if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт требует прав root. Запустите с sudo."
    exit 1
fi

# Установка зависимостей
echo "Установка необходимых пакетов..."
apt-get update
apt-get install -y python3-pip ansible

echo "Установка Python-зависимостей..."
pip3 install docker

echo "Установка Ansible коллекции community.docker..."
ansible-galaxy collection install community.docker

# Запуск playbook
echo "Запуск Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml

echo "Развертывание завершено успешно!"
echo "Логи можно найти в /tmp/http_check/logs/"