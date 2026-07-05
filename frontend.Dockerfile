# Frontend image — builds the React/Vite app, then serves it with nginx.
# PLACE THIS AT: frontend/Dockerfile  in your repo.
# Multi-stage: node builds the static files, nginx serves them.

# ---- Stage 1: build the static site ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build          # Vite outputs to /app/dist

# ---- Stage 2: serve with nginx ----
FROM nginx:alpine
# Copy the built static files into nginx's web root
COPY --from=build /app/dist /usr/share/nginx/html
# SPA-friendly nginx config (so client-side routes work on refresh)
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
