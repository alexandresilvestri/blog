FROM oven/bun:1
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY bunfig.toml tsconfig.json ./
COPY src ./src

ENV NODE_ENV=production
ENV BUN_PUBLIC_SENTRY_DSN=${BUN_PUBLIC_SENTRY_DSN}
ENV SENTRY_DSN=${SENTRY_DSN}
USER bun
EXPOSE 3000
CMD ["bun", "--preload", "./src/server/instrument.ts", "src/index.ts"]

