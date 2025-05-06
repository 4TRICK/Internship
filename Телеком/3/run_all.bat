@echo off
title Ansible Autoinstaller and Runner
chcp 65001 >nul

:: Проверка наличия WSL
echo [INFO] Проверка наличия WSL...
wsl --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] WSL не установлен. Устанавливаю...
    wsl --install
    echo [INFO] Перезагрузите компьютер и снова запустите этот скрипт.
    pause
    exit /b
)

:: Проверка и установка Ubuntu в WSL
echo [INFO] Установка Ubuntu (если нужно)...
wsl -l -v | findstr -i "Ubuntu" >nul
if %errorlevel% neq 0 (
    wsl --install -d Ubuntu
    echo [INFO] Ubuntu установлена. Перезагрузите компьютер и повторно запустите скрипт.
    pause
    exit /b
)

:: Установка зависимостей и Docker в WSL
echo [INFO] Установка Ansible, Docker и Python3 в WSL...
wsl bash -c "sudo apt update && sudo apt install -y ansible docker.io python3-pip"

:: Запуск и проверка Docker в WSL
echo [INFO] Проверка работы Docker...
wsl bash -c "sudo systemctl enable --now docker"
wsl bash -c "docker --version"

:: Добавление текущего пользователя в группу docker
echo [INFO] Добавление текущего пользователя в группу docker...
wsl bash -c "sudo usermod -aG docker $(whoami)"

:: Проверка наличия директории с проектом
echo [INFO] Проверка наличия директории с проектом в разделе 3...
set PROJECT_DIR=%~dp0
if not exist "%PROJECT_DIR%Internship\3" (
    echo [ERROR] Директория с проектом не найдена. Убедитесь, что вы находитесь в разделе 3.
    pause
    exit /b
)

:: Запуск Ansible Playbook
echo [INFO] Запуск Ansible Playbook...
wsl bash -c "cd /mnt/c/%PROJECT_DIR:~2%Internship/3 && ansible-playbook site.yml -i inventory.ini"

echo [INFO] Готово. Все настройки завершены!
pause
