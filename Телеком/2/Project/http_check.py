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
        return f"{color}{message}\033[0m"


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