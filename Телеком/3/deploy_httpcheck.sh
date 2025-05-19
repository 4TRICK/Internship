<<<<<<< HEAD
#!/bin/bash

# Скрипт для автоматического развертывания и проверки http_check.py через Ansible и Docker

set -e  # Выход при ошибке


if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт требует прав root. Запустите с sudo."
    exit 1
fi


echo "Установка необходимых пакетов..."
apt-get update
apt-get install -y python3-pip git ansible


echo "Установка зависимостей Ansible..."
pip3 install docker


echo "Установка Ansible коллекции community.docker..."
ansible-galaxy collection install community.docker


echo "Создание структуры каталогов..."
mkdir -p /opt/httpcheck_ansible/roles/{docker_install,run_container}/{tasks,files,templates,handlers}
cd /opt/httpcheck_ansible


echo "Создание файлов конфигурации Ansible..."


cat > inventory.ini <<EOL
[local]
localhost ansible_connection=local
EOL


cat > playbook.yml <<EOL
---
- name: Install Docker and run http_check container
  hosts: all
  become: yes
  gather_facts: yes

  roles:
    - role: docker_install
    - role: run_container
EOL


cat > roles/docker_install/tasks/main.yml <<EOL
---
- name: Install prerequisites
  apt:
    name: "{{ item }}"
    state: present
    update_cache: yes
  loop:
    - apt-transport-https
    - ca-certificates
    - curl
    - software-properties-common
    - python3-pip

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
    state: present

- name: Install Docker
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - docker-ce
    - docker-ce-cli
    - containerd.io

- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes

- name: Start and enable Docker service
  service:
    name: docker
    state: started
    enabled: yes

- name: Install Docker Python SDK
  pip:
    name: docker

- name: Verify Docker installation
  command: docker --version
  register: docker_version
  changed_when: false

- name: Show Docker version
  debug:
    var: docker_version.stdout
EOL


cat > roles/run_container/tasks/main.yml <<EOL
---
- name: Create working directory
  file:
    path: /tmp/http_check
    state: directory

- name: Copy script files
  copy:
    src: "{{ item }}"
    dest: /tmp/http_check/
  loop:
    - files/http_check.py
    - files/requirements.txt

- name: Template Dockerfile
  template:
    src: templates/Dockerfile.j2
    dest: /tmp/http_check/Dockerfile

- name: Copy .dockerignore
  copy:
    src: ../../../.dockerignore
    dest: /tmp/http_check/.dockerignore

- name: Build Docker image
  community.docker.docker_image:
    name: http-checker
    source: build
    build:
      path: /tmp/http_check
      dockerfile: Dockerfile
    force_source: yes

- name: Run container
  community.docker.docker_container:
    name: http-check-container
    image: http-checker
    state: started
    detach: true
    volumes:
      - "/tmp/http_check/logs:/app/logs"

- name: Wait for container to finish
  command: docker wait http-check-container
  register: container_exit_code
  until: container_exit_code.stdout != ""
  retries: 10
  delay: 1

- name: Check container exit code
  assert:
    that:
      - container_exit_code.stdout == "0"
    fail_msg: "Container failed with exit code {{ container_exit_code.stdout }}"
    success_msg: "Container completed successfully"

- name: Get container logs
  command: docker logs http-check-container
  register: container_logs
  changed_when: false

- name: Display container logs
  debug:
    var: container_logs.stdout_lines

- name: Show log files
  find:
    paths: /tmp/http_check/logs
    patterns: "*.log"
  register: log_files

- name: Display log file contents
  command: cat "{{ item.path }}"
  loop: "{{ log_files.files }}"
  register: log_contents
  changed_when: false

- name: Show log contents
  debug:
    var: item.stdout_lines
  loop: "{{ log_contents.results }}"
  loop_control:
    label: "{{ item.item.path }}"
EOL


cat > roles/run_container/templates/Dockerfile.j2 <<EOL
FROM ubuntu:22.04

ENV TZ=Europe/Moscow

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mkdir -p /app/logs
COPY http_check.py requirements.txt ./

RUN pip3 install --no-cache-dir -r requirements.txt

VOLUME /app/logs

CMD ["python3", "http_check.py"]
EOL


cat > .dockerignore <<EOL
logs/
.git/
__pycache__/
*.pyc
EOL


cat > roles/run_container/files/http_check.py <<'EOL'
"""
Так как это скрипт, думаю модульность здесь неуместна
"""
import os
import requests
import logging
from datetime import datetime

# Настройки
STATUS_CODES = [200, 301, 404, 500, 102, 999]  # 999 для теста
BASE_URL = "https://httpstat.us/"
LOG_DIR = "logs"
os.makedirs(LOG_DIR, exist_ok=True)


class ColorFormatter(logging.Formatter):
    COLORS = {
        'DEBUG': '\033[92m',  # Green
        'INFO': '\033[94m',  # Blue
        'WARNING': '\033[93m',  # Yellow
        'ERROR': '\033[91m',  # Red
        'CRITICAL': '\033[95m'  # Purple (фиолетовый для критических ошибок)
    }

    def format(self, record):
        color = self.COLORS.get(record.levelname, '')
        message = super().format(record)
        return f"{color}{message}\033[0m}"


logger = logging.getLogger("HTTP Checker")
logger.setLevel(logging.DEBUG)

console_handler = logging.StreamHandler()
console_handler.setFormatter(ColorFormatter(
    '%(asctime)s - %(levelname)s - %(message)s'
))

log_file = os.path.join(LOG_DIR, f"http_check_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
file_handler = logging.FileHandler(log_file, encoding='utf-8')
file_handler.setFormatter(logging.Formatter(
    '[%(asctime)s] %(levelname)s: %(message)s'
))

logger.addHandler(console_handler)
logger.addHandler(file_handler)


def make_request(code):
    url = f"{BASE_URL}{code}"
    try:
        response = requests.get(url, timeout=5)
        status = response.status_code

        if status == 999:
            logger.critical("Simulated CRITICAL error for testing purposes")
            raise Exception("Manual critical error triggered")

        if 100 <= status < 400:
            logger.info(f"Success: Status {status}\nResponse body: {response.text}")
        elif 400 <= status < 500:
            logger.error(f"Client Error: Status {status}\nResponse body: {response.text}")
            raise Exception(f"HTTP Client Error: {status}")
        else:
            logger.critical(f"Server Error: Status {status}\nResponse body: {response.text}")
            raise Exception(f"HTTP Server Error: {status}")

    except requests.exceptions.RequestException as e:
        logger.critical(f"Request failed: {str(e)}")
        raise Exception(f"Network error: {str(e)}")


def main():
    logger.info("Starting HTTP status checks...")

    for code in STATUS_CODES:
        try:
            logger.debug(f"Checking status code: {code}")
            make_request(code)
        except Exception as e:
            logger.error(f"Error checking code {code}: {str(e)}")

    logger.info(f"All checks completed. Logs saved to {log_file}")


if __name__ == "__main__":
    main()
EOL


cat > roles/run_container/files/requirements.txt <<EOL
requests>=2.31.0
EOL


echo "Запуск Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml

echo "Развертывание завершено успешно!"
=======
#!/bin/bash

# Скрипт для автоматического развертывания и проверки http_check.py через Ansible и Docker

set -e  # Выход при ошибке


if [ "$(id -u)" -ne 0 ]; then
    echo "Этот скрипт требует прав root. Запустите с sudo."
    exit 1
fi


echo "Установка необходимых пакетов..."
apt-get update
apt-get install -y python3-pip git ansible


echo "Установка зависимостей Ansible..."
pip3 install docker


echo "Установка Ansible коллекции community.docker..."
ansible-galaxy collection install community.docker


echo "Создание структуры каталогов..."
mkdir -p /opt/httpcheck_ansible/roles/{docker_install,run_container}/{tasks,files,templates,handlers}
cd /opt/httpcheck_ansible


echo "Создание файлов конфигурации Ansible..."


cat > inventory.ini <<EOL
[local]
localhost ansible_connection=local
EOL


cat > playbook.yml <<EOL
---
- name: Install Docker and run http_check container
  hosts: all
  become: yes
  gather_facts: yes

  roles:
    - role: docker_install
    - role: run_container
EOL


cat > roles/docker_install/tasks/main.yml <<EOL
---
- name: Install prerequisites
  apt:
    name: "{{ item }}"
    state: present
    update_cache: yes
  loop:
    - apt-transport-https
    - ca-certificates
    - curl
    - software-properties-common
    - python3-pip

- name: Add Docker GPG key
  apt_key:
    url: https://download.docker.com/linux/ubuntu/gpg
    state: present

- name: Add Docker repository
  apt_repository:
    repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu jammy stable"
    state: present

- name: Install Docker
  apt:
    name: "{{ item }}"
    state: present
  loop:
    - docker-ce
    - docker-ce-cli
    - containerd.io

- name: Add user to docker group
  user:
    name: "{{ ansible_user }}"
    groups: docker
    append: yes

- name: Start and enable Docker service
  service:
    name: docker
    state: started
    enabled: yes

- name: Install Docker Python SDK
  pip:
    name: docker

- name: Verify Docker installation
  command: docker --version
  register: docker_version
  changed_when: false

- name: Show Docker version
  debug:
    var: docker_version.stdout
EOL


cat > roles/run_container/tasks/main.yml <<EOL
---
- name: Create working directory
  file:
    path: /tmp/http_check
    state: directory

- name: Copy script files
  copy:
    src: "{{ item }}"
    dest: /tmp/http_check/
  loop:
    - files/http_check.py
    - files/requirements.txt

- name: Template Dockerfile
  template:
    src: templates/Dockerfile.j2
    dest: /tmp/http_check/Dockerfile

- name: Copy .dockerignore
  copy:
    src: ../../../.dockerignore
    dest: /tmp/http_check/.dockerignore

- name: Build Docker image
  community.docker.docker_image:
    name: http-checker
    source: build
    build:
      path: /tmp/http_check
      dockerfile: Dockerfile
    force_source: yes

- name: Run container
  community.docker.docker_container:
    name: http-check-container
    image: http-checker
    state: started
    detach: true
    volumes:
      - "/tmp/http_check/logs:/app/logs"

- name: Wait for container to finish
  command: docker wait http-check-container
  register: container_exit_code
  until: container_exit_code.stdout != ""
  retries: 10
  delay: 1

- name: Check container exit code
  assert:
    that:
      - container_exit_code.stdout == "0"
    fail_msg: "Container failed with exit code {{ container_exit_code.stdout }}"
    success_msg: "Container completed successfully"

- name: Get container logs
  command: docker logs http-check-container
  register: container_logs
  changed_when: false

- name: Display container logs
  debug:
    var: container_logs.stdout_lines

- name: Show log files
  find:
    paths: /tmp/http_check/logs
    patterns: "*.log"
  register: log_files

- name: Display log file contents
  command: cat "{{ item.path }}"
  loop: "{{ log_files.files }}"
  register: log_contents
  changed_when: false

- name: Show log contents
  debug:
    var: item.stdout_lines
  loop: "{{ log_contents.results }}"
  loop_control:
    label: "{{ item.item.path }}"
EOL


cat > roles/run_container/templates/Dockerfile.j2 <<EOL
FROM ubuntu:22.04

ENV TZ=Europe/Moscow

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone && \
    apt-get update && \
    apt-get install -y --no-install-recommends python3 python3-pip && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN mkdir -p /app/logs
COPY http_check.py requirements.txt ./

RUN pip3 install --no-cache-dir -r requirements.txt

VOLUME /app/logs

CMD ["python3", "http_check.py"]
EOL


cat > .dockerignore <<EOL
logs/
.git/
__pycache__/
*.pyc
EOL


cat > roles/run_container/files/http_check.py <<'EOL'
"""
Так как это скрипт, думаю модульность здесь неуместна
"""
import os
import requests
import logging
from datetime import datetime

# Настройки
STATUS_CODES = [200, 301, 404, 500, 102, 999]  # 999 для теста
BASE_URL = "https://httpstat.us/"
LOG_DIR = "logs"
os.makedirs(LOG_DIR, exist_ok=True)


class ColorFormatter(logging.Formatter):
    COLORS = {
        'DEBUG': '\033[92m',  # Green
        'INFO': '\033[94m',  # Blue
        'WARNING': '\033[93m',  # Yellow
        'ERROR': '\033[91m',  # Red
        'CRITICAL': '\033[95m'  # Purple (фиолетовый для критических ошибок)
    }

    def format(self, record):
        color = self.COLORS.get(record.levelname, '')
        message = super().format(record)
        return f"{color}{message}\033[0m}"


logger = logging.getLogger("HTTP Checker")
logger.setLevel(logging.DEBUG)

console_handler = logging.StreamHandler()
console_handler.setFormatter(ColorFormatter(
    '%(asctime)s - %(levelname)s - %(message)s'
))

log_file = os.path.join(LOG_DIR, f"http_check_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log")
file_handler = logging.FileHandler(log_file, encoding='utf-8')
file_handler.setFormatter(logging.Formatter(
    '[%(asctime)s] %(levelname)s: %(message)s'
))

logger.addHandler(console_handler)
logger.addHandler(file_handler)


def make_request(code):
    url = f"{BASE_URL}{code}"
    try:
        response = requests.get(url, timeout=5)
        status = response.status_code

        if status == 999:
            logger.critical("Simulated CRITICAL error for testing purposes")
            raise Exception("Manual critical error triggered")

        if 100 <= status < 400:
            logger.info(f"Success: Status {status}\nResponse body: {response.text}")
        elif 400 <= status < 500:
            logger.error(f"Client Error: Status {status}\nResponse body: {response.text}")
            raise Exception(f"HTTP Client Error: {status}")
        else:
            logger.critical(f"Server Error: Status {status}\nResponse body: {response.text}")
            raise Exception(f"HTTP Server Error: {status}")

    except requests.exceptions.RequestException as e:
        logger.critical(f"Request failed: {str(e)}")
        raise Exception(f"Network error: {str(e)}")


def main():
    logger.info("Starting HTTP status checks...")

    for code in STATUS_CODES:
        try:
            logger.debug(f"Checking status code: {code}")
            make_request(code)
        except Exception as e:
            logger.error(f"Error checking code {code}: {str(e)}")

    logger.info(f"All checks completed. Logs saved to {log_file}")


if __name__ == "__main__":
    main()
EOL


cat > roles/run_container/files/requirements.txt <<EOL
requests>=2.31.0
EOL


echo "Запуск Ansible playbook..."
ansible-playbook -i inventory.ini playbook.yml

echo "Развертывание завершено успешно!"
>>>>>>> a3dae4be9614be0317785ed61660d8d1af6621d0
echo "Логи можно найти в /tmp/http_check/logs/"