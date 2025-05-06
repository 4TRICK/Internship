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
