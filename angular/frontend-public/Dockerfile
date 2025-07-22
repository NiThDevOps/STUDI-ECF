# Étape 1 : Build de l’app Angular
FROM node:20 AS build-stage

WORKDIR /app
COPY . .
RUN npm install
RUN npm run build -- --configuration production --project frontend-public

# Étape 2 : Serveur web statique NGINX
FROM nginx:alpine

# Supprimer le contenu NGINX par défaut
RUN rm -rf /usr/share/nginx/html/*

# Copier les fichiers Angular buildés
COPY --from=build-stage /app/dist/frontend-public/browser /usr/share/nginx/html

# Copier la config NGINX (optionnel si tu veux des routes propres)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]