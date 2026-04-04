# e_smart_check_in

Pre-arrival guest check-in **web application** (Spring Boot), deployed with Docker (e.g. Render).

The **PMS Flutter client** lives in a separate project (e.g. `pms-test`); it is not in this repository.

## Check-in app

- **Backend / UI:** Java 17, Thymeleaf — `src/`, `pom.xml`
- **Deploy:** `Dockerfile`, `render.yaml`
- **Edge functions:** `supabase/functions/` (TypeScript)

Build locally:

```bash
./mvnw clean package -DskipTests
```

Run the JAR from `target/` or use your IDE Spring Boot run configuration.

## Environment

Configure Supabase and public URL variables as required for your environment (see `render.yaml` and application configuration).
