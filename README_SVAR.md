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


---

### 1B: CI-pipeline og tagging-strategi
* Jeg har opprettet en GitHub Actions workflow (`.github/workflows/docker.yml`) som bygger og pusher Spring Boot-containeren til Amazon ECR.
* Workflowen er konfigurert til å kun kjøre automatisk ved `push` til `main`-bransjen.
* Autentiseringsnøkler (`AWS_ACCESS_KEY_ID` og `AWS_SECRET_ACCESS_KEY`) er lagret i GitHub Secrets, og ingen følsom informasjon er eksponert i workflow-filen.
* ECR-repositoryet `wishifai-app-k28` ble opprettet i AWS-region `eu-west-1` via AWS CLI.

#### Begrunnelse for tagging-strategi:
I min pipeline har jeg valgt en kombinert tagging-strategi som pusher med både **kort commit-SHA (`$rev`)** og **`latest`**:

1. **Commit-SHA (`git rev-parse --short HEAD`):**  
   Dette gir full sporbarthet og uforanderlighet. Hver commit som merges til `main` genererer en unik tagg koblet direkte til kildekoden. Dette gjør det enkelt å spore nøyaktig hvilken kildekodeversjon som kjører i miljøet, samt rulle tilbake dersom en feil oppstår.
2. **`latest`:**  
   `latest`-taggen oppdateres ved hver vellykkede kjøring. Dette gjør det praktisk for sensor og andre utviklere å hente ut det til enhver tid nyeste imaget uten å måtte slå opp den spesifikke SHA-koden.

**Lenke til vellykket workflow-kjøring:**
https://github.com/Phankev24/PGR301-Eksamen-2026/actions/runs/41540353639/job/125605785656