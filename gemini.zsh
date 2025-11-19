#!/bin/zsh

# 1. Helper
function ensure_docker_running() {
  if ! docker info > /dev/null 2>&1; then
    echo "🐳 Docker не запущен. Запускаю..."
    open -a Docker
    while ! docker info > /dev/null 2>&1; do sleep 1; done
    echo "✅ Docker готов!"
  fi
}

# 2. Main
function gemini() {
  ensure_docker_running
  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  local TARGET_DIR
  local STATE_DIR
  local GLOBAL_AUTH="$HOME/.docker-gemini-config/google_accounts.json"
  local GLOBAL_SETTINGS="$HOME/.docker-gemini-config/settings.json"
  local GH_CONFIG_DIR="$HOME/.docker-gemini-config/gh_config"
  local SSH_KNOWN_HOSTS="$HOME/.ssh/known_hosts"
  local GIT_CONFIG="$HOME/.gitconfig"
  local DOCKER_FLAGS
  if [ -t 1 ]; then DOCKER_FLAGS="-it"; else DOCKER_FLAGS="-i"; fi

  if [[ -n "$GIT_ROOT" ]]; then
    TARGET_DIR="$GIT_ROOT"
    STATE_DIR="$GIT_ROOT/.gemini-state"
    echo -e "\033[0;34m🤖 Project Mode:\033[0m $(basename "$GIT_ROOT")" >&2
  else
    TARGET_DIR="$(pwd)"
    STATE_DIR="$HOME/.docker-gemini-config/global_state"
    echo -e "\033[0;33m🤖 Global Mode\033[0m" >&2
  fi

  mkdir -p "$STATE_DIR"
  mkdir -p "$GH_CONFIG_DIR"
  touch "$SSH_KNOWN_HOSTS"

  if [[ -f "$GLOBAL_AUTH" ]]; then cp "$GLOBAL_AUTH" "$STATE_DIR/google_accounts.json"; fi
  if [[ -f "$GLOBAL_SETTINGS" ]]; then cp "$GLOBAL_SETTINGS" "$STATE_DIR/settings.json"; fi

  docker run $DOCKER_FLAGS --rm \
    --network host \
    -e GOOGLE_CLOUD_PROJECT=gemini-cli-auth-478707 \
    -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
    -v "${SSH_KNOWN_HOSTS}":/root/.ssh/known_hosts \
    -v "${GIT_CONFIG}":/root/.gitconfig \
    -v "${GH_CONFIG_DIR}":/root/.config/gh \
    -v "${TARGET_DIR}":/app \
    -v "${STATE_DIR}":/root/.gemini \
    gemini-cli "$@"

  if [[ -f "$STATE_DIR/google_accounts.json" ]]; then
    cp "$STATE_DIR/google_accounts.json" "$GLOBAL_AUTH"
  fi
}

# 3. AI Commit Function (True Analysis)
function aic() {
  ensure_docker_running
  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$GIT_ROOT" ]]; then echo "❌ Не git-репозиторий"; return 1; fi
  
  cd "$GIT_ROOT"
  git add .
  
  local DIFF_FILE="_gemini_diff_tmp.txt"
  # Увеличиваем лимит до 100KB, чтобы модель увидела полный контекст изменений README
  git diff --staged | head -c 100000 > "$DIFF_FILE"
  
  if [[ ! -s "$DIFF_FILE" ]]; then echo "🤷‍♂️ Нет изменений."; rm "$DIFF_FILE"; return; fi
  
  echo "🤖 Анализирую изменения (Deep Code Analysis)..." >&2
  
  # ЧЕСТНЫЙ ПРОМПТ: Только анализ diff-а, без подсказок от человека
  local PROMPT="Analyze the git diff provided in file @$DIFF_FILE. 
  Role: Senior Lead Developer performing a Code Review.
  
  Task: Write a semantic git commit message (Conventional Commits) based ONLY on the code changes.
  
  Requirements:
  1. Analyze the logic changes in shell scripts: Detect ARCHITECTURAL shifts (e.g., switching from 'mount' to 'copy' strategy). Explain WHY this was likely done based on the code.
  2. Analyze documentation: If the README was replaced, describe it as a rewrite/overhaul, not just an update.
  3. Identify new capabilities: Mention any new functions added (e.g., aic).
  
  Format:
  <type>(<scope>): <imperative summary>
  
  - <Detail 1: What changed and Why>
  - <Detail 2: Technical implication>
  - <Detail 3: Documentation updates>
  
  Output Constraints:
  - RAW text only. No markdown fencing. No conversational filler."
  
  local MSG=$(gemini "$PROMPT" | sed 's/```//g' | sed 's/"//g' | tr -d '\r')
  rm "$DIFF_FILE"
  MSG=$(echo "$MSG" | sed -e 's/^[[:space:]]*//')

  echo -e "\n📝 \033[1;32mПредложенный коммит:\033[0m"
  echo "---------------------------------------------------"
  echo "$MSG"
  echo "---------------------------------------------------"
  
  echo -n "🚀 Выполнить commit? [y/N]: "
  read CONFIRM
  
  if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    git commit -m "$MSG"
    echo "✅ Закоммичено."
  else
    echo "❌ Отменено."
  fi
}
