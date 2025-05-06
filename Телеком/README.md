# [![Typing SVG](https://readme-typing-svg.herokuapp.com?color=%2336BCF7&lines=🛠+Internship+Project)](https://git.io/typing-svg)

Репозиторий содержит комплексное решение из трёх этапов:

- `1/` — HTTP-скрипт (Python)
- `2/` — Docker-контейнер со скриптом
- `3/` — Автоматизация с помощью Ansible

---

## 🔹 Раздел 1: Работа со скриптом (Python)

### Задачи:

```bash
- Написать скрипт (Python или Bash), выполняющий 5 HTTP-запросов к https://httpsfat.us
- Обработка ответов:
    * 1xx, 2xx, 3xx → логировать статус и тело
    * 4xx, 5xx → генерировать исключение
- Логировать вывод в консоль
- Обрабатывать сетевые ошибки
```
## Запуск:
```bash
python .\http_check.py
```
---
## 🔹 Раздел 2: Docker-обёртка

### Задачи:
```bash
- Создать Dockerfile (на базе Ubuntu 22.04)
- Установить зависимости:
    * curl (для Bash) или python3, pip, requests (для Python)
- Копировать скрипт из раздела 1
- Автоматически запускать его при старте контейнера
```
## Запуск:
```bash
-docker build -t http-checker .
-docker run --name checker http-checker
-docker rm checker 
```
---
##🔹 Раздел 3: Автоматизация с Ansible
### Задачи:
```bash
- Установить Docker на хосте
- Добавить пользователя в группу docker
- Запустить и включить docker.service
- Проверить установку (docker --version)
- Собрать или использовать Docker-образ
- Запустить контейнер и проверить статус
- Вывести логи контейнера через Ansible
```
## Запуск:
```bash
./sh run_all.sh(Для Linux)
.\run_all.bat (Для Windows)
```

🔗 Ссылки
Исходный сервис: https://httpsfat.us

Docker: https://www.docker.com

Ansible: https://docs.ansible.com

GitHub репозиторий: github.com/4TRICK/Internship

