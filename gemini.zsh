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

# 2. Main Wrapper
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

  # --- SSH CONFIG DEEP CLEAN ---
  # Убираем: UseKeychain, AddKeysToAgent, IdentityFile, IdentitiesOnly
  # Это заставляет Docker использовать ключи из Агента, а не искать файлы.
  local SSH_CONFIG_CLEAN="$STATE_DIR/ssh_config_clean"
  if [[ -f "$SSH_CONFIG_SRC" ]]; then
    grep -vE "UseKeychain|AddKeysToAgent|IdentityFile|IdentitiesOnly" "$SSH_CONFIG_SRC" > "$SSH_CONFIG_CLEAN"
  else
    touch "$SSH_CONFIG_CLEAN"
  fi
  # -----------------------------

  if [[ -f "$GLOBAL_AUTH" ]]; then cp "$GLOBAL_AUTH" "$STATE_DIR/google_accounts.json"; fi
  if [[ -f "$GLOBAL_SETTINGS" ]]; then cp "$GLOBAL_SETTINGS" "$STATE_DIR/settings.json"; fi

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

  if [[ -f "$STATE_DIR/google_accounts.json" ]]; then
    cp "$STATE_DIR/google_accounts.json" "$GLOBAL_AUTH"
  fi

  if [[ "$IS_INTERACTIVE" == "true" && -n "$GIT_ROOT" ]]; then
    echo -e "\n👋 Сеанс завершен."
    aic
  fi
}

# 3. GEXEC (Updated Clean)
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
  
  # Тот же фильтр для gexec
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

# 4. AIC
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
    local CTX_FILE="_gemini_context_tmp.txt"
    echo "=== PART 1: PROJECT HISTORY ===" > "$CTX_FILE"
    git log -n 10 --pretty=format:"%h | %an | %s" >> "$CTX_FILE"
    echo -e "\n\n=== PART 2: CURRENT DIFF ===" >> "$CTX_FILE"
    git diff --staged | head -c 100000 >> "$CTX_FILE"
    
    echo "🤖 Анализирую изменения..." >&2
    local PROMPT="Analyze file @$CTX_FILE. Part 1 is history, Part 2 is changes. Write a semantic Conventional Commit message. Match the style of History. Output ONLY raw text."
    
    local MSG=$(gemini "$PROMPT" | sed 's/```//g' | sed 's/"//g' | tr -d '\r')
    rm "$CTX_FILE"
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
    if [[ "$PUSH_CONFIRM" == "y" || "$PUSH_CONFIRM" == "Y" ]]; then 
       echo "☁️ Pushing..."
       gexec git push
    else 
       echo "🏠 Оставлено локально."
    fi
  fi
}
