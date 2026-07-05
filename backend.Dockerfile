# Backend image — packages the Spring Boot jar built by Maven.
# PLACE THIS AT: backend/Dockerfile  in your repo.
# Build context is the backend/ folder, so target/ (with the jar) is available.

FROM eclipse-temurin:21-jre
WORKDIR /app

# Jenkins runs `mvn package` first, so backend/target/*.jar exists.
COPY target/expense-tracker-1.0.0.jar app.jar

EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
