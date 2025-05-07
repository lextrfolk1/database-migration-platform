
# Spring Cloud Config Server - Documentation

## Overview

This project sets up a **Spring Cloud Config Server** to manage externalized configurations across multiple services in a centralized way.

Spring Cloud Config provides server and client-side support for externalized configuration in a distributed system.

---

## How to Use the Config Server

1. **Start the Config Server**:
   - Make sure your configuration files are available in the configured Git repository or local directory.
   - Start the Config Server by running:

   ```bash
   ./mvnw spring-boot:run
   ```
   or
   ```bash
   java -jar config-server.jar
   ```

2. **Client Applications Setup**:
   - Add these properties to your client application's `bootstrap.yml` or `application.yml` (preferably `bootstrap.yml`):

     ```yaml
     spring:
       application:
         name: your-service-name
       cloud:
         config:
           uri: http://localhost:8888
     ```

   - Here:
     - `spring.application.name` must match the property file name stored in the config repository.
     - `spring.cloud.config.uri` is the URL where the config server is running.

3. **Configuration File Naming Conventions**:
   - Common configurations: `application-common.yml`
   - Service-specific configurations: `<service-name>.yml` (Example: `workflow-service.yml`)
   - Environment-specific profiles: `<service-name>-<profile>.yml` (Example: `workflow-service-dev.yml`)

---

## Example - Profile Based Configuration

Suppose your service name is `workflow-service`.

You can have the following config files:

| File Name                        | Purpose                                  |
| --------------------------------- | ---------------------------------------- |
| `application-common.yml`         | Common/shared configurations             |
| `workflow-service.yml`            | Service-specific configurations (default profile) |
| `workflow-service-dev.yml`        | Service-specific configurations for `dev` profile |
| `workflow-service-prod.yml`       | Service-specific configurations for `prod` profile |

**URL Example for fetching config via Config Server**:

- Default profile:
  ```
  http://localhost:8888/workflow-service/default
  ```
- Dev profile:
  ```
  http://localhost:8888/workflow-service/dev
  ```
- Prod profile:
  ```
  http://localhost:8888/workflow-service/prod
  ```

---

# Guidelines for Configuration Files

1. Files from this directory should be moved to the respective service's `resources` directory if local fallback is needed.
2. The `application.yml` file on the **client side** should only contain **client-specific properties** like:
   - Port numbers
   - Application names
   - Logging levels/configurations
   - Local settings if necessary (e.g., actuator endpoints)

---

## Property Loading Order

1. **Common properties** (`application-common.yml`) are loaded **first**.
2. **Service-specific properties** (`<service-name>.yml`) are loaded **afterward**.

> **Important**:  
> If a property is defined in **both** the common and service-specific files,  
> ➔ The **service-specific property will take precedence** and **override** the common property.

---

# Notes

- Keep **sensitive credentials** (like passwords) encrypted or secured.
- Avoid hardcoding environment-specific settings inside `application-common.yml`.
- Use profiles (`dev`, `prod`, `uat`) wisely to separate environments cleanly.
- Maintain version control (like Git) for all configuration files to track changes safely.

