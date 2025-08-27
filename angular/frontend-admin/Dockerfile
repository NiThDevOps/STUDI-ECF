# Étape 1 : Build de l’app Angular
FROM node:20 AS build-stage
WORKDIR /app
COPY . .
RUN npm install
RUN npm run build -- --configuration production --project frontend-admin

# Étape 2 :  Serveur web statique NGINX
FROM nginx:alpine
RUN rm -rf /usr/share/nginx/html/*
# ⬇️ Ici la différence clé
COPY --from=build-stage /app/dist/frontend-admin/browser /usr/share/nginx/html/
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]