# Ludilê — imagem do app Next.js, isolada do UpVia (seção 19).
# Build multi-stage com output "standalone" para uma imagem final enxuta.

FROM node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1

RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 ludile

COPY --from=builder /app/public ./public
COPY --from=builder --chown=ludile:nodejs /app/.next/standalone ./
COPY --from=builder --chown=ludile:nodejs /app/.next/static ./.next/static

USER ludile
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"

CMD ["node", "server.js"]
