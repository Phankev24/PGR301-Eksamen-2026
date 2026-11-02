## Oppgave 1: Container og CI (20p)

### 1A: Containerisér Spring Boot-applikasjonen
I denne Dockerfilen brukes det multi-stage build til å bygge og kjøre applikasjonen:

1. **Builder-steget:**
    * `maven:3.9-eclipse-temurin-21` er valgt fordi applikasjonen og utviklingsmiljøet bruker Java 21.
    * Oppretter `/app` som working directory.
    * Kopierer over `pom.xml` og hele `src`-mappen.
    * Kjører `mvn package -DskipTests` for å kompilere koden og lage JAR-filen. Ved å hoppe over testene under imagestarten går byggingen raskere.

2. **Runtime-steget:**
    * Bytter til et minimalistisk `eclipse-temurin:21-jre-alpine`-image og kopierer den ferdig bygde `.jar`-filen over til `/app/application.jar`.
    * Resultat: Ved å gjøre det på denne måten slipper jeg å drasse med meg Maven, kildekoden og tunge byggeverktøy inn i det endelige imaget. Imaget blir mye mindre i størrelse, det starter raskere, og det er bedre for sikkerheten fordi det inneholder færre ubrukte filer.

3. **Bygge og kjøre Dockerfilen:**
    1. Stå i rotmappen i prosjektet
    2. Kjør denne kommandoen for å bygge: `docker build -t wishifai-app .`
    3. Kjør denne kommandoen for på starte på port 9999: `docker run -p 9999:8080 --name wishifai-container wishifai-app`