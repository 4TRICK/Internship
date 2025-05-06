@echo off
title Ansible Autoinstaller and Runner
chcp 65001 >nul

echo [INFO] Проверка наличия WSL...
wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] WSL не установлен. Устанавливаю...
    wsl --install
    echo [INFO] Перезагрузите компьютер и снова запустите этот скрипт.
    pause
    exit /b
)

echo [INFO] Установка Ubuntu (если нужно)...
wsl -l -v | findstr -i "Ubuntu" >nul
if %errorlevel% neq 0 (
    wsl --install -d Ubuntu
    echo [INFO] Ubuntu установлена. Перезагрузите компьютер и повторно запустите скрипт.
    pause
    exit /b
)

echo [INFO] Установка Ansible и Docker в WSL...
wsl bash -c "sudo apt update && sudo apt install -y ansible docker.io python3-pip"

echo [INFO] Добавление текущего пользователя в группу docker...
wsl bash -c "sudo usermod -aG docker $(whoami)"

echo [INFO] Копирование необходимых файлов (если нужно)...
REM Здесь предполагается, что ты уже поместил все в папку 3

echo [INFO] Запуск Ansible Playbook...
wsl bash -c "cd ~/ && cd $(pwd | sed 's|\\|/|g' | sed 's/C:/mnt/c/') && ansible-playbook 3/site.yml -i 3/inventory.ini"

echo [INFO] Готово.
pause
