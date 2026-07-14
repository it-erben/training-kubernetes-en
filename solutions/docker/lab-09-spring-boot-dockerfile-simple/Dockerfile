FROM eclipse-temurin:25.0.1_8-jre
WORKDIR /app
COPY target/*.jar /app/app.jar
ENTRYPOINT ["java","-jar","/app/app.jar"]
