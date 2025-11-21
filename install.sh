#!/bin/bash
set -e

echo "🛠  Установка окружения Gemini Docker..."

function ensure_docker_running() {
  if ! command -v docker &> /dev/null; then
      echo "❌ Docker не найден! Установите Docker Desktop."
      exit 1
  fi
  if ! docker info > /dev/null 2>&1; then
    echo "🐳 Запускаю Docker Desktop..."
    open -a Docker
    local i=0
    while ! docker info > /dev/null 2>&1; do
      i=$(( (i+1) %4 )); printf "\r${spin:$i:1} Ожидание..."; sleep 1
    done
    echo "✅ Docker готов!"
  fi
}

ensure_docker_running

# Получаем последнюю версию из NPM (с fallback на latest)
echo "🔍 Проверка версии Gemini CLI в NPM..."
LATEST_VER=$(curl -m 3 -s https://registry.npmjs.org/@google/gemini-cli/latest | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
if [ -z "$LATEST_VER" ]; then LATEST_VER="latest"; fi

echo "📦 Сборка Docker образа (Версия: $LATEST_VER)..."
docker build --build-arg GEMINI_VERSION=$LATEST_VER -t gemini-cli .

# Конфиги
CONFIG_DIR="$HOME/.docker-gemini-config"
mkdir -p "$CONFIG_DIR/global_state"
if [ ! -f "$CONFIG_DIR/settings.json" ]; then
    cp settings.json "$CONFIG_DIR/"
    echo "✅ Конфиг создан."
fi

# Zsh
ZSH_FILE="$HOME/.zshrc"
SCRIPT_PATH="$(pwd)/gemini.zsh"
SOURCE_CMD="source \"$SCRIPT_PATH\""

if ! grep -Fq "$SCRIPT_PATH" "$ZSH_FILE"; then
    echo "" >> "$ZSH_FILE"
    echo "# Gemini Docker Tooling" >> "$ZSH_FILE"
    echo "$SOURCE_CMD" >> "$ZSH_FILE"
    echo "✅ Подключено к .zshrc"
fi

echo ""
echo "🎉 Установка завершена!"
echo "👉 Выполните: source ~/.zshrc"
