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

---

 ## Oppgave 2: ECS Express med Terraform (25p)

 ### 2A: Infrastruktur for tjenesten

**Offentlig URL til tjenesten:** https://wi-97007aeba8eb418bb591ff07be39cddf.ecs.eu-west-1.on.aws

**Eksempel på testkommando (curl):** 
curl -F "image=@samples/sample_image.png" https://wi-97007aeba8eb418bb591ff07be39cddf.ecs.eu-west-1.on.aws/api/analyze


### All Terraform-kode for infrastrukturen ligger i mappen infra/. Løsningen oppretter følgende komponenter:

**S3 Bucket (wishifai-images-k28):**

* Opprettet S3-bucket for lagring av bilder lastet opp til applikasjonen. Bucketen har force_destroy = true for ryddig ressurshåndtering, og blokkerer offentlig tilgang direkte via aws_s3_bucket_public_access_block.

**IAM Task Role (wishifai-task-role-k28):**

* Opprettet en dedikert task role for applikasjonen for å sikre "least privilege". Rollen har en inline-policy med tillatelser til:

**S3:** Lese, skrive og liste objekter i wishifai-images-k28.

**AWS Rekognition:** DetectLabels og DetectText for å hente ut objekter fra bilder.

**AWS Bedrock:** InvokeModel for å generere gaveforslag via LLM.

**CloudWatch:** PutMetricData for at Spring Boot (Micrometer) skal få levert metrikker under kjøring.

**ECS Express Service (aws_ecs_express_gateway_service):**

* Tjenesten benytter de eksisterende fellesrollene i AWS-kontoen for execution (ecsTaskExecutionRole) og infrastruktur (ecsInfrastructureRoleForExpressServices), samt den nyopprettede task-rollen.

* Miljøvariabelen S3_BUCKET settes automatisk i Terraform ved å hente navnet fra S3-ressursen (aws_s3_bucket.images.bucket).

* Helsesjekksti er eksplisitt satt til health_check_path = "/actuator/health" slik at ECS Express gjenkjenner at Spring Boot-containeren er frisk og kan rute trafikk til den.

* Variabler benyttes for region, kandidatnummer og Docker-image for fleksibel konfigurasjon.

---
### 2B: Remote State
**Terraform-state er konfigurert til å lagres i en S3 backend i stedenfor lokalt på maskinen.**
* **Backend Bucket:** pgr301-terraform-state
* **State Key Path:** Wishifai/k28/terraform.tfstate
* **Region:** eu-west-1

---
### 2C: GitHub Actions-job for Terraform
Pipelinen i `.github/workflows/docker.yml` har to jobber som kjører etter hverandre: `push_to_registry` og `terraform`.

### Hvorfor Terraform må kjøre ETTER container-build:
1. **Unngå feil ved utrulling:** Hvis Terraform oppdaterer ECS før imaget ligger i ECR, prøver ECS å hente et bilde som ikke finnes ennå, og containeren krasjer.
2. **Sikre at koden bygger:** Hvis bygget av Docker-imaget feiler, kjører ikke Terraform. Dermed ruller vi ikke ut ødelagte endringer.
3. **Riktig versjon:** Terraform må vite den nøyaktige Commit SHA-tagen fra bygg-steget for å oppdatere ECS med riktig image.



## Oppgave 3: Observability (20p)

### 3A: Metrikker i applikasjonen

For å finne ut hvorfor applikasjonen svarer tregt og se hvordan den brukes, har vi lagt inn metrikker med Micrometer. Disse sendes automatisk til AWS CloudWatch under navnerommet `wishifai-28`.

Vi har valgt å måle følgende:

1. **`rekognition.execution.time` (Timer)**
   - **Hva den gjør:** Måler hvor mange sekunder AWS Rekognition bruker på å finne objekter i bildet.
   - **Hvorfor:** Siden dette er et eksternt kall, vil vi se om det er bildegjenkjenningen som gjør at brukerne må vente. En `Timer` gir oss både gjennomsnittstid og toppene (p95/p99).

2. **`bedrock.execution.time` (Timer)**
   - **Hva den gjør:** Måler hvor lang tid AWS Bedrock (Claude LLM) bruker på å generere gaveforslagene.
   - **Hvorfor:** AI-modeller bruker ofte lang tid på å svare. Metrikken bekrefter om det er Bedrock som er hovedårsaken til tregheten (i testene våre tok dette ca. 15,6 sekunder).

3. **`wishifai.images.analyzed` (Counter — Business-metrikk)**
   - **Hva den gjør:** Teller totalt antall bilder som har blitt sendt inn og analysert.
   - **Hvorfor:** Dette viser den faktiske bruken av tjenesten over tid. Det gir nyttig innsikt for investorer og driftsteamet om hvor populær appen er, helt uavhengig av tekniske feil.