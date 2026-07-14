# Base: Maven + JDK 17 (for build AND runtime)
FROM maven:3.9-eclipse-temurin-17

# Working directory inside the container
WORKDIR /workspace

# --- Prepare the dependency cache ---
# 1) Copy pom.xml and cache the dependencies
COPY pom.xml .
RUN mvn -B -q -DskipTests dependency:go-offline

# --- Source code and build ---
# 2) Copy the sources
COPY src ./src

# 3) Maven build inside the container
RUN mvn -B -DskipTests package

# 4) Place the jar at a well-defined location
RUN mkdir -p /app && cp target/*.jar /app/app.jar

# Port documentation (Spring Boot default)
EXPOSE 8080

# 5) Start the application
ENTRYPOINT ["java","-jar","/app/app.jar"]
