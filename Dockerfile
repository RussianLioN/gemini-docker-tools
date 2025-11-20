FROM node:22-alpine

# Устанавливаем bash (для shell) и coreutils (для ls, cp, mv)
# ncurses нужен для правильной работы UI терминала
RUN apk add --no-cache bash coreutils ncurses git python3 make g++ openssh-client github-cli

# Устанавливаем Gemini CLI
RUN npm install -g @google/gemini-cli --no-audit

# Настройка SSH
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# По умолчанию рабочая директория /app, но мы будем переопределять её при запуске
WORKDIR /app
ENTRYPOINT ["gemini"]
