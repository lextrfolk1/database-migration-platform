FROM maven:3.9.9-eclipse-temurin-21 AS build
WORKDIR /workspace
COPY pom.xml mvnw mvnw.cmd ./
COPY .mvn .mvn
COPY src src
RUN chmod +x mvnw && ./mvnw -q -DskipTests package

FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /workspace/target/database-migration-platform-0.0.1-SNAPSHOT.jar app.jar
ENV LEXTR_POSTGRES_PASSWORD=admin
ENV LEXTR_CLICKHOUSE_PASSWORD=
EXPOSE 8049
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
