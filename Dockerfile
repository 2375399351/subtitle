# ---------- 构建阶段 ----------
FROM node:20-alpine AS builder

WORKDIR /app

# 安装 pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

# 先复制依赖清单，利用 Docker 缓存层
COPY package.json pnpm-lock.yaml ./

# 安装依赖（包含 devDependencies，构建需要）
RUN pnpm install --frozen-lockfile

# 复制项目源码并构建
COPY . .
RUN pnpm run build

# ---------- 运行阶段 ----------
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

# 创建非 root 用户运行（安全最佳实践）
RUN addgroup --system --gid 1001 nodejs \
 && adduser --system --uid 1001 nextjs

# 从构建阶段复制 standalone 产物
# standalone 模式已自动打包了生产所需的最小 node_modules
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# 创建持久化数据目录（用于缓存等本地数据）
RUN mkdir -p /app/data && chown -R nextjs:nodejs /app/data

USER nextjs

EXPOSE 3000

# standalone 模式生成的是 server.js，直接运行即可
CMD ["node", "server.js"]
