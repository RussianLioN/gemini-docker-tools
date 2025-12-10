FROM node:22-alpine

# GLM-4.6 AI Container for Multi-Session AI IDE
# Optimized for Z.AI GLM models through Claude Code interface

# Аргументы для управления версией
ARG GLM_VERSION=latest
ARG CLAUDE_CODE_VERSION=latest

# 1. Системные пакеты
RUN apk add --no-cache bash coreutils ncurses git python3 make g++ openssh-client github-cli curl wget jq

# 2. Фикс локали
ENV LANG=C.UTF-8
RUN echo "#!/bin/sh" > /usr/bin/locale && \
    echo "echo C.UTF-8" >> /usr/bin/locale && \
    chmod +x /usr/bin/locale

# 3. Создание удобных команд
RUN echo '#!/bin/bash' > /usr/local/bin/ll && \
    echo 'ls -lh --color=auto "$@"' >> /usr/local/bin/ll && \
    chmod +x /usr/local/bin/ll

RUN echo '#!/bin/bash' > /usr/local/bin/l && \
    echo 'ls -F --color=auto "$@"' >> /usr/local/bin/l && \
    chmod +x /usr/local/bin/l

# 4. Установка Claude Code (для GLM interface)
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION} --no-audit

# 5. Установка дополнительных утилит для GLM
RUN npm install -g @z_ai/coding-helper@${GLM_VERSION} --no-audit || echo "GLM CLI not available, using fallback"

# 6. Создание GLM конфигурационных файлов
RUN mkdir -p /root/.claude && \
    echo '{"model": "glm-4.6", "max_tokens": 8192, "temperature": 0.7, "system_prompt": "You are GLM-4.6, an advanced AI assistant specialized in coding and development tasks.", "features": {"multi_session": true, "max_concurrent_sessions": 5, "session_management": true, "code_analysis": true, "debugging": true, "refactoring": true, "documentation": true, "parallel_processing": true}, "integrations": {"git": true, "github": true, "docker": true, "z_ai_platform": true}}' > /root/.claude/glm-config.json && \
    echo '{"env": {"ANTHROPIC_DEFAULT_HAIKU_MODEL": "glm-4.5-air", "ANTHROPIC_DEFAULT_SONNET_MODEL": "glm-4.6", "ANTHROPIC_DEFAULT_OPUS_MODEL": "glm-4.6"}}' > /root/.claude/settings.json

# 7. Настройка SSH для GLM
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

# 8. GLM специфичные переменные окружения
ENV GLM_MODEL=glm-4.6
ENV ZAI_API_KEY=""
ENV SESSION_ID=""
ENV MAX_CONCURRENT_SESSIONS=5
ENV GLM_WORKSPACE_ROOT=/workspace

# 9. Создание точки входа для GLM
COPY glm-entrypoint.sh /usr/local/bin/glm-entrypoint.sh
RUN chmod +x /usr/local/bin/glm-entrypoint.sh

# 10. Рабочая директория
WORKDIR /workspace

# 11. Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD claude --version || exit 1

ENTRYPOINT ["/usr/local/bin/glm-entrypoint.sh"]
