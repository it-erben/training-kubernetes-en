# ---------- Stage 1: Builder ----------
FROM maven:3-eclipse-temurin-17 AS builder
WORKDIR /workspace

# only pom.xml for better caching
COPY pom.xml .
RUN mvn -q -DskipTests dependency:go-offline

# now the source code and the build
COPY src ./src
RUN mvn -B -DskipTests package

# ---------- Stage 2: Runtime ----------
FROM eclipse-temurin:25.0.1_8-jre AS runtime
WORKDIR /app

# take only the finished jar
COPY --from=builder /workspace/target/*.jar /app/app.jar

EXPOSE 8080
ENTRYPOINT ["java","-jar","/app/app.jar"]
