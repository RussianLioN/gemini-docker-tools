#!/bin/bash
set -e  # Остановить скрипт при любой ошибке

echo "🛠  Установка окружения Gemini Docker..."

# --- Функция проверки Docker ---
function ensure_docker_running() {
  # Проверяем наличие бинарника
  if ! command -v docker &> /dev/null; then
      echo "❌ Docker не найден! Пожалуйста, установите Docker Desktop."
      exit 1
  fi

  # Проверяем статус демона
  if ! docker info > /dev/null 2>&1; then
    echo "🐳 Docker не запущен. Запускаю Docker Desktop..."
    open -a Docker
    
    # Спиннер ожидания
    local spin='-\|/'
    local i=0
    while ! docker info > /dev/null 2>&1; do
      i=$(( (i+1) %4 ))
      printf "\r${spin:$i:1} Ожидание готовности Docker Engine..."
      sleep 1
    done
    printf "\r✅ Docker запущен и готов!               \n"
  fi
}
# -------------------------------

# 1. Проверка и запуск Docker
ensure_docker_running

# 2. Сборка образа
echo "📦 Сборка Docker образа 'gemini-cli'..."
docker build -t gemini-cli .

# 3. Настройка глобальных конфигов
CONFIG_DIR="$HOME/.docker-gemini-config"
echo "📂 Проверка папки конфигурации: $CONFIG_DIR"
mkdir -p "$CONFIG_DIR/global_state"

# Копируем шаблон настроек, если целевого файла нет
if [ ! -f "$CONFIG_DIR/settings.json" ]; then
    cp settings.json "$CONFIG_DIR/"
    echo "✅ Файл настроек (settings.json) скопирован."
else
    echo "ℹ️  Файл settings.json уже существует. Оставляем как есть."
fi

# 4. Подключение скрипта в Zsh
ZSH_FILE="$HOME/.zshrc"
SCRIPT_PATH="$(pwd)/gemini.zsh"
SOURCE_CMD="source \"$SCRIPT_PATH\""

echo "🔗 Настройка .zshrc..."
if grep -Fq "$SCRIPT_PATH" "$ZSH_FILE"; then
    echo "ℹ️  Скрипт уже подключен в .zshrc"
else
    echo "" >> "$ZSH_FILE"
    echo "# Gemini Docker Tooling" >> "$ZSH_FILE"
    echo "$SOURCE_CMD" >> "$ZSH_FILE"
    echo "✅ Строка подключения добавлена в конец .zshrc"
fi

echo ""
echo "🎉 Установка завершена!"
echo "👉 Выполните: source ~/.zshrc"
