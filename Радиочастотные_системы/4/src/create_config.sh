#!/bin/bash

cat > config.txt << EOF
name: test_server
path: /home/user/data
file: data.txt
port: 8080
log path: /var/log/app
EOF

echo "Файл config.txt успешно создан."
