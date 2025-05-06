#!/bin/bash

set -e

echo "==> Обновление пакетов..."
sudo apt update && sudo apt upgrade -y

echo "==> Установка необходимых зависимостей..."
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    software-properties-common \
    curl \
    gnupg \
    lsb-release

# Установка Docker
if ! command -v docker >/dev/null 2>&1; then
    echo "==> Docker не найден, устанавливаю..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
else
    echo "==> Docker уже установлен."
fi

# Установка Ansible
if ! command -v ansible >/dev/null 2>&1; then
    echo "==> Ansible не найден, устанавливаю через pip..."
    pip3 install --upgrade pip
    pip3 install ansible
else
    echo "==> Ansible уже установлен."
fi

echo "==> Добавление пользователя в группу docker (если нужно)..."
sudo usermod -aG docker "$USER"
newgrp docker <<EONG

echo "==> Запуск и включение Docker..."
sudo systemctl enable docker
sudo systemctl start docker

EONG

echo "==> Проверка установки Docker и Ansible:"
docker --version
ansible --version

# Проверка наличия папки 3 и нужных файлов
if [ ! -f "./3/site.yml" ]; then
    echo "Ошибка: файл site.yml не найден в папке 3"
    exit 1
fi
if [ ! -f "./3/inventory.ini" ]; then
    echo "Ошибка: файл inventory.ini не найден в папке 3"
    exit 1
fi

echo "==> Переход в папку 3 и запуск playbook..."
cd ./3
ansible-playbook site.yml -i inventory.ini

echo "Готово! Если docker-команды не работают без sudo — перезайди в систему."
