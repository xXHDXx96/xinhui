#!/bin/bash
cd "$(dirname "$0")"
[ -f .env ] || { echo "❌ 缺 .env"; exit 1; }
set -a; source .env; set +a
pkill -f "eusd-backend-1.0.0.jar" 2>/dev/null
sleep 2
nohup java -jar target/eusd-backend-1.0.0.jar > /root/eusd-backend.log 2>&1 &
echo "✅ 已启动 PID=$!"
