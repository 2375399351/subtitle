# ---------- 构建阶段 ----------
FROM node:22-alpine AS builder

WORKDIR /app

# 固定 pnpm 9.x，避免 pnpm 10+ 的严格构建脚本策略
RUN corepack enable && corepack prepare pnpm@9.15.0 --activate

# 先复制依赖清单，利用 Docker 缓存层
COPY package.json pnpm-lock.yaml ./

# 安装依赖
RUN pnpm install --frozen-lockfile

# 复制项目源码并构建
COPY . .
RUN pnpm run build

# ---------- 运行阶段 ----------
FROM node:22-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs

COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

RUN mkdir -p /app/data && chown -R nextjs:nodejs /app/data

USER nextjs

EXPOSE 3000

CMD ["node", "server.js"]
