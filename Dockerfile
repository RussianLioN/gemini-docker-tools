FROM node:22-alpine

# 1. Системные пакеты
RUN apk add --no-cache bash coreutils ncurses git python3 make g++ openssh-client github-cli

# 2. Фикс проблемы "locale: not found" в Alpine
# Устанавливаем переменную и создаем фейковый бинарник, чтобы Node.js не ругался
ENV LANG=C.UTF-8
RUN echo "#!/bin/sh" > /usr/bin/locale && \
    echo "echo C.UTF-8" >> /usr/bin/locale && \
    chmod +x /usr/bin/locale

# 3. Создание команд 'll' и 'l' (как бинарников, чтобы работали везде)
RUN echo '#!/bin/bash' > /usr/local/bin/ll && \
    echo 'ls -lh --color=auto "$@"' >> /usr/local/bin/ll && \
    chmod +x /usr/local/bin/ll

RUN echo '#!/bin/bash' > /usr/local/bin/l && \
    echo 'ls -F --color=auto "$@"' >> /usr/local/bin/l && \
    chmod +x /usr/local/bin/l

# 4. Установка Gemini CLI
RUN npm install -g @google/gemini-cli --no-audit

# 5. Настройка SSH
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

WORKDIR /app
ENTRYPOINT ["gemini"]
