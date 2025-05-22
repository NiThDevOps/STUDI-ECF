# Étape 1 : Image Java légère
FROM eclipse-temurin:17

# Définir le dossier de travail
WORKDIR /app

# Copier ton JAR compilé
COPY target/hello-springboot-1.0.0.jar app.jar

# Exposer le port utilisé par Spring Boot
EXPOSE 8080

# Lancer l'application
ENTRYPOINT ["java", "-jar", "app.jar"]