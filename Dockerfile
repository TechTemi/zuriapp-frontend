FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./

RUN npm ci

COPY . .

ARG VITE_API_URL=http://localhost:5000
ARG VITE_STORE_NAME="Zuri Market"

ENV VITE_API_URL=$VITE_API_URL
ENV VITE_STORE_NAME=$VITE_STORE_NAME

RUN npm run build

FROM nginx:stable-alpine

# Patch Alpine packages so Trivy does not fail on outdated OpenSSL libraries.
RUN apk update \
    && apk upgrade \
    && rm -rf /var/cache/apk/*

COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/dist /usr/share/nginx/html

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD wget --spider -q http://127.0.0.1/ || exit 1

CMD ["nginx", "-g", "daemon off;"]