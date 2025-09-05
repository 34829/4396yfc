FROM node:lts-alpine3.21

# Arguments
ARG APP_HOME=/home/node/app

# Install system dependencies
RUN apk add --no-cache gcompat tini git git-lfs

# Create app directory
WORKDIR ${APP_HOME}

# Set NODE_ENV to production
ENV NODE_ENV=production

# Bundle app source
COPY . ./

RUN \
  echo "*** Install npm packages ***" && \
  npm i --no-audit --no-fund --loglevel=error --no-progress --omit=dev && npm cache clean --force

# Create config directory and link config.yaml
RUN \
  rm -f "config.yaml" || true && \
  ln -s "./config/config.yaml" "config.yaml" || true && \
  mkdir "config" || true

# Pre-compile public libraries
RUN \
  echo "*** Run Webpack ***" && \
  node "./docker/build-lib.js"

# Set the entrypoint script
RUN \
  echo "*** Cleanup ***" && \
  mv "./docker/docker-entrypoint.sh" "./" && \
  rm -rf "./docker" && \
  echo "*** Make docker-entrypoint.sh executable ***" && \
  chmod +x "./docker-entrypoint.sh" && \
  echo "*** Convert line endings to Unix format ***" && \
  dos2unix "./docker-entrypoint.sh"

# Fix extension repos permissions
RUN git config --global --add safe.directory "*"

RUN git clone https://github.com/N0VI028/JS-Slash-Runner.git
RUN git clone https://github.com/zonde306/ST-Prompt-Template

EXPOSE 8000
RUN mkdir data
CMD ["node", "server.js"]

# Ensure proper handling of kernel signals
ENTRYPOINT ["tini", "--", "./docker-entrypoint.sh"]
