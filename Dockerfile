# syntax=docker/dockerfile:1
# =============================================================================
#  Dockerfile - multi-stage build cho Spring Boot 4 / Java 21 / Gradle
# =============================================================================

# ---------- Stage 1: build ----------
FROM gradle:8.14-jdk21-alpine AS builder
WORKDIR /workspace

# Copy Gradle metadata trước để tận dụng cache layer
COPY build.gradle settings.gradle ./
COPY gradlew ./
COPY gradle ./gradle
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon

# Copy toàn bộ mã nguồn project
COPY . .
RUN ./gradlew build -x test --no-daemon

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:21-jre-alpine AS runtime

ARG APP_VERSION=dev
ENV APP_VERSION=${APP_VERSION} \
    JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75"

WORKDIR /app

RUN addgroup -S spring && adduser -S spring -G spring
COPY --from=builder /workspace/build/libs/app.jar /app/app.jar
USER spring

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "/app/app.jar"]
