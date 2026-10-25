FROM oven/bun:1
WORKDIR /app

COPY package.json bun.lock ./
RUN bun install --frozen-lockfile

COPY bunfig.toml tsconfig.json ./
COPY src ./src
COPY styles ./styles

ENV NODE_ENV=production
USER bun
EXPOSE 3000
CMD ["bun", "src/index.ts"]

