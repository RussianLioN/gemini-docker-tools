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
  local DOCKER_FLAGS
  if [ -t 1 ]; then DOCKER_FLAGS="-it"; else DOCKER_FLAGS="-i"; fi

  if [[ -n "$GIT_ROOT" ]]; then
    TARGET_DIR="$GIT_ROOT"
    STATE_DIR="$GIT_ROOT/.gemini-state"
  else
    TARGET_DIR="$(pwd)"
    STATE_DIR="$HOME/.docker-gemini-config/global_state"
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

# 3. AI Commit (Context-Aware Edition)
function aic() {
  ensure_docker_running
  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$GIT_ROOT" ]]; then echo "❌ Не git-репозиторий"; return 1; fi
  
  cd "$GIT_ROOT"
  git add .
  
  # Файл контекста
  local CTX_FILE="_gemini_context_tmp.txt"
  
  # 1. Собираем историю (последние 10 коммитов)
  echo "=== PART 1: PROJECT HISTORY (Context only) ===" > "$CTX_FILE"
  # Формат: "хеш | автор | сообщение"
  git log -n 10 --pretty=format:"%h | %an | %s" >> "$CTX_FILE"
  echo -e "\n\n=== PART 2: CURRENT CHANGES (The Diff) ===" >> "$CTX_FILE"
  
  # 2. Собираем Diff
  git diff --staged | head -c 100000 >> "$CTX_FILE"
  
  # Проверяем, есть ли изменения (Diff должен быть не пуст, а файл теперь содержит историю, так что проверяем grep-ом или размером diff)
  # Проще проверить через git diff --quiet
  if git diff --staged --quiet; then echo "🤷‍♂️ Нет изменений."; rm "$CTX_FILE"; return; fi
  
  echo "🤖 Анализирую контекст (History + Diff)..." >&2
  
  # ПРОМПТ
  local PROMPT="Analyze the file @$CTX_FILE. 
  
  Structure of file:
  - PART 1: Recent commit history. Use this to understand the project's style, ongoing tasks, and naming conventions.
  - PART 2: The actual code changes (Diff) you need to describe.
  
  Task: Write a semantic git commit message (Conventional Commits) for the changes in PART 2.
  
  Guidance:
  - If the Diff updates documentation described in History, mention that.
  - Match the brevity or detail level of the History.
  - Output ONLY the raw commit message."
  
  local MSG=$(gemini "$PROMPT" | sed 's/```//g' | sed 's/"//g' | tr -d '\r')
  rm "$CTX_FILE"
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

# 4. Gemini Executor
function gexec() {
  local GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
  local TARGET_DIR
  if [[ -n "$GIT_ROOT" ]]; then TARGET_DIR="$GIT_ROOT"; else TARGET_DIR="$(pwd)"; fi
  
  local SSH_KNOWN_HOSTS="$HOME/.ssh/known_hosts"
  local GIT_CONFIG="$HOME/.gitconfig"
  local GH_CONFIG_DIR="$HOME/.docker-gemini-config/gh_config"

  docker run -it --rm \
    --entrypoint "" \
    --network host \
    -e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock \
    -v /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock \
    -v "${SSH_KNOWN_HOSTS}":/root/.ssh/known_hosts \
    -v "${GIT_CONFIG}":/root/.gitconfig \
    -v "${GH_CONFIG_DIR}":/root/.config/gh \
    -v "${TARGET_DIR}":/app \
    gemini-cli "$@"
}
