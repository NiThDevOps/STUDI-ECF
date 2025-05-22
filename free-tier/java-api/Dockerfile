# Étape 1 : utiliser une image officielle Java
FROM openjdk:17-jdk-slim

# Étape 2 : définir le répertoire de travail dans le conteneur
WORKDIR /app

# Étape 3 : copier le fichier .jar dans le conteneur
COPY target/hello-springboot-1.0.0.jar app.jar

# Étape 4 : exposer le port que l'app utilise
EXPOSE 8080

# Étape 5 : définir la commande pour démarrer l'app
ENTRYPOINT ["java", "-jar", "app.jar"]