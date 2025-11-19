FROM node:22-alpine

# Устанавливаем системные пакеты:
# - openssh-client: для git clone/push через SSH
# - github-cli: для создания репозиториев (gh repo create)
# - git, python3, make, g++: база для Gemini
RUN apk add --no-cache git python3 make g++ openssh-client github-cli

# Устанавливаем Gemini CLI
RUN npm install -g @google/gemini-cli --no-audit

# Настройка SSH
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

WORKDIR /app
ENTRYPOINT ["gemini"]
