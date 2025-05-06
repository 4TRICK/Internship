#!/bin/bash

OS="$(uname)"

if [ "$OS" == "Linux" ]; then
    docker stop checker 2>/dev/null
    docker rm checker 2>/dev/null
elif [[ "$OS" == *"NT"* ]]; then
    if docker ps -a --format '{{.Names}}' | grep -q 'checker'; then
        docker stop checker
        docker rm checker
    fi
fi

docker build -t http-checker .

mkdir -p ./logs
docker run --name checker -v "$(pwd)/logs:/app/logs" http-checker

docker logs checker
