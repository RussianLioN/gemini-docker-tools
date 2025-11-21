#!/bin/zsh

GEMINI_TOOLS_HOME=${0:a:h}

# 1. Helper
function ensure_docker_running() {
  if ! docker info > /dev/null 2>&1; then
    echo "🐳 Docker не запущен. Запускаю..."
    open -a Docker
    while ! docker info > /dev/null 2>&1; do sleep 1; done
    echo "✅ Docker готов!"
  fi
}

# 2. Helper: Update Check
function check_gemini_update() {
  if ping -c 1 -W 100 8.8.8.8 &> /dev/null; then
    local CURRENT_VER=$(docker run --rm --entrypoint gemini gemini-cli --version 2>/dev/null)
    local LATEST_VER=$(curl -m 3 -s https://registry.npmjs.org/@google/gemini-cli/latest | grep -o '"version":"[^"]*"' | cut -d'"' -f4)
    if [[ -n "$LATEST_VER" && "$CURRENT_VER" != "$LATEST_VER" ]]; then
      echo "✨ \033[1;35mОбновление Gemini CLI:\033[0m $CURRENT_VER -> $LATEST_VER"
      echo "📦 Пересборка образа..."
      docker build --build-arg GEMINI_VERSION=$LATEST_VER -t gemini-cli "$GEMINI_TOOLS_HOME"
      echo "✅ Готово."
    fi
  fi
}

# 3. Main Wrapper
function gemini() {
  ensure_docker_running
  check_gemini_update

  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  local TARGET_DIR
  local STATE_DIR
  local GLOBAL_AUTH="$HOME/.docker-gemini-config/google_accounts.json"
  local GLOBAL_SETTINGS="$HOME/.docker-gemini-config/settings.json"
  local GH_CONFIG_DIR="$HOME/.docker-gemini-config/gh_config"
  local SSH_KNOWN_HOSTS="$HOME/.ssh/known_hosts"
  local GIT_CONFIG="$HOME/.gitconfig"
  local SSH_CONFIG_SRC="$HOME/.ssh/config"
  
  local IS_INTERACTIVE=false
  local DOCKER_FLAGS="-i"

  if [ -t 1 ] && [ -z "$1" ]; then 
    DOCKER_FLAGS="-it"
    IS_INTERACTIVE=true
  fi

  if [[ -n "$GIT_ROOT" ]]; then
    TARGET_DIR="$GIT_ROOT"
    STATE_DIR="$GIT_ROOT/.gemini-state"
  else
    TARGET_DIR="$(pwd)"
    STATE_DIR="$HOME/.docker-gemini-config/global_state"
  fi
  
  local PROJECT_NAME=$(basename "$TARGET_DIR")
  local CONTAINER_WORKDIR="/app/$PROJECT_NAME"

  mkdir -p "$STATE_DIR"
  mkdir -p "$GH_CONFIG_DIR"
  touch "$SSH_KNOWN_HOSTS"

  local SSH_CONFIG_CLEAN="$STATE_DIR/ssh_config_clean"
  if [[ -f "$SSH_CONFIG_SRC" ]]; then
    grep -vE "UseKeychain|AddKeysToAgent|IdentityFile|IdentitiesOnly" "$SSH_CONFIG_SRC" > "$SSH_CONFIG_CLEAN"
  else
    touch "$SSH_CONFIG_CLEAN"
  fi

  if [[ -f "$GLOBAL_AUTH" ]]; then cp "$GLOBAL_AUTH" "$STATE_DIR/google_accounts.json"; fi
  if [[ -f "$GLOBAL_SETTINGS" ]]; then cp "$GLOBAL_SETTINGS" "$STATE_DIR/settings.json"; fi

  # УБРАН ЛИШНИЙ МАУНТ /tmp_exchange
  docker run $DOCKER_FLAGS --rm \
    --network host \
    -e GOOGLE_CLOUD_PROJECT=gemini-cli-auth-478707 \
    -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
    -v "${SSH_KNOWN_HOSTS}":/root/.ssh/known_hosts \
    -v "${SSH_CONFIG_CLEAN}":/root/.ssh/config \
    -v "${GIT_CONFIG}":/root/.gitconfig \
    -v "${GH_CONFIG_DIR}":/root/.config/gh \
    -w "${CONTAINER_WORKDIR}" \
    -v "${TARGET_DIR}":"${CONTAINER_WORKDIR}" \
    -v "${STATE_DIR}":/root/.gemini \
    gemini-cli "$@"

  if [[ -f "$STATE_DIR/google_accounts.json" ]]; then cp "$STATE_DIR/google_accounts.json" "$GLOBAL_AUTH"; fi
  if [[ -f "$STATE_DIR/settings.json" ]]; then cp "$STATE_DIR/settings.json" "$GLOBAL_SETTINGS"; fi

  if [[ "$IS_INTERACTIVE" == "true" && -n "$GIT_ROOT" ]]; then
    echo -e "\n👋 Сеанс завершен."
    aic
  fi
}

# 4. GEXEC
function gexec() {
  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  local TARGET_DIR
  if [[ -n "$GIT_ROOT" ]]; then TARGET_DIR="$GIT_ROOT"; else TARGET_DIR="$(pwd)"; fi
  
  local PROJECT_NAME=$(basename "$TARGET_DIR")
  local CONTAINER_WORKDIR="/app/$PROJECT_NAME"
  
  local SSH_KNOWN_HOSTS="$HOME/.ssh/known_hosts"
  local GIT_CONFIG="$HOME/.gitconfig"
  local GH_CONFIG_DIR="$HOME/.docker-gemini-config/gh_config"
  local SSH_CONFIG_SRC="$HOME/.ssh/config"
  local TMP_DIR="$HOME/.docker-gemini-config/tmp_exec"
  mkdir -p "$TMP_DIR"
  local SSH_CONFIG_CLEAN="$TMP_DIR/ssh_config_clean"
  
  if [[ -f "$SSH_CONFIG_SRC" ]]; then
    grep -vE "UseKeychain|AddKeysToAgent|IdentityFile|IdentitiesOnly" "$SSH_CONFIG_SRC" > "$SSH_CONFIG_CLEAN"
  else
    touch "$SSH_CONFIG_CLEAN"
  fi

  docker run -it --rm \
    --entrypoint "" \
    --network host \
    -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
    -v "${SSH_KNOWN_HOSTS}":/root/.ssh/known_hosts \
    -v "${SSH_CONFIG_CLEAN}":/root/.ssh/config \
    -v "${GIT_CONFIG}":/root/.gitconfig \
    -v "${GH_CONFIG_DIR}":/root/.config/gh \
    -w "${CONTAINER_WORKDIR}" \
    -v "${TARGET_DIR}":"${CONTAINER_WORKDIR}" \
    gemini-cli "$@"
}

# 5. AIC (Memory-Based, No Files)
function aic() {
  ensure_docker_running
  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$GIT_ROOT" ]]; then echo "❌ Не git-репозиторий"; return 1; fi
  
  cd "$GIT_ROOT"
  
  if ! grep -q ".gemini-state" .gitignore 2>/dev/null; then
    echo "🛡  Безопасность: Добавляю .gemini-state в .gitignore..."
    echo "" >> .gitignore
    echo "# Gemini AI Context" >> .gitignore
    echo ".gemini-state/" >> .gitignore
  fi
  
  git add .
  
  if ! git diff --staged --quiet; then
    
    # --- DIRECT MEMORY CONTEXT ---
    # Читаем данные прямо в переменные (без создания файлов)
    local LOG_CONTENT=$(git log -n 10 --pretty=format:"%h | %an | %s")
    # Ограничиваем размер diff до ~90KB, чтобы влезло в аргумент командной строки
    local DIFF_CONTENT=$(git diff --staged | head -c 90000)
    
    echo "🤖 Анализирую изменения..." >&2
    
    # Формируем единый промпт-строку
    local PROMPT="Act as a Senior DevOps Engineer.
    
    CONTEXT PART 1 (Project History):
    $LOG_CONTENT
    
    CONTEXT PART 2 (Current Changes):
    $DIFF_CONTENT
    
    TASK:
    Write a semantic Conventional Commit message for the changes in PART 2.
    Match the style of PART 1.
    Output ONLY the raw commit message string. No markdown, no quotes."
    
    # Передаем промпт как аргумент. Zsh справится с переносами строк.
    local MSG=$(gemini "$PROMPT" | sed 's/```//g' | sed 's/"//g' | tr -d '\r')
    MSG=$(echo "$MSG" | sed -e 's/^[[:space:]]*//')

    echo -e "\n📝 \033[1;32mПредложенный коммит:\033[0m"
    echo "---------------------------------------------------"
    echo "$MSG"
    echo "---------------------------------------------------"
    
    echo "🚀 Действия: [Enter]=Push, [c]=Commit, [n]=Cancel"
    echo -n "Ваш выбор: "
    read ACTION
    ACTION=${ACTION:-y}

    if [[ "$ACTION" == "y" || "$ACTION" == "Y" ]]; then
      git commit -m "$MSG"
      echo "☁️ Auto-Push..."
      
      local REMOTE_URL=$(git config --get remote.origin.url)
      if [[ "$REMOTE_URL" == https* ]]; then
         echo "⚠️  HTTPS Remote detected. Auth may fail inside Docker."
      fi
      
      gexec git push
    elif [[ "$ACTION" == "c" || "$ACTION" == "C" ]]; then
      git commit -m "$MSG"
      echo "✅ Saved locally."
    else
      echo "❌ Cancelled."
    fi
    return
  fi

  local UNPUSHED_COUNT=$(git log @{u}..HEAD --oneline 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$UNPUSHED_COUNT" -gt 0 ]]; then
    echo -e "\n⚡️ \033[1;33mОбнаружено $UNPUSHED_COUNT неотправленных коммитов.\033[0m"
    git log @{u}..HEAD --oneline --color | head -n 5
    echo -n "🚀 Выполнить git push сейчас? [Y/n]: "
    read PUSH_CONFIRM
    PUSH_CONFIRM=${PUSH_CONFIRM:-y}
    if [[ "$PUSH_CONFIRM" == "y" || "$PUSH_CONFIRM" == "Y" ]]; then echo "☁️ Pushing..."; gexec git push; else echo "🏠 Оставлено локально."; fi
  fi
}
