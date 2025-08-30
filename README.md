# Dabih Auth Keycloak - Fargate Deployment

Enterprise Identity and Access Management for Trinnvis platform using Keycloak on AWS Fargate.

Dette prosjektet deployer Keycloak til AWS Fargate for autentisering og autorisasjon av Trinnvis-applikasjoner.

## Prosjektstruktur

```
dabih-auth-keycloak/
├── .github/
│   └── workflows/
│       ├── deploy.yml        # Keycloak deployment workflow
│       ├── rollback.yml      # Rollback workflow
│       └── terraform.yml     # Infrastruktur deployment
├── docker/
│   ├── Dockerfile           # Keycloak Docker image
│   └── docker-entrypoint.sh # Custom entrypoint script
├── infrastructure/
│   ├── main.tf              # Hoved OpenTofu konfigurasjon
│   ├── variables.tf         # Variabel definisjoner
│   ├── outputs.tf           # Output definisjoner
│   ├── route53.tf           # DNS konfigurasjon
│   ├── terraform.tfvars.example  # Eksempel variabel fil
│   └── .gitignore           # Gitignore for sensitive filer
└── README.md               # Denne filen
```

## Forutsetninger

1. AWS konto med nødvendige tilganger
2. GitHub repository med følgende secrets konfigurert:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `KEYCLOAK_DB_USERNAME`
   - `KEYCLOAK_DB_PASSWORD`
   - `KEYCLOAK_ADMIN_USER`
   - `KEYCLOAK_ADMIN_PASSWORD`
3. OpenTofu state S3 bucket og DynamoDB tabell (deles med dabih-zero)
4. Eksisterende RDS PostgreSQL database (bruker samme som dabih-zero med egen schema)

## Infrastruktur Oppsett

### 1. Database Setup

Keycloak bruker samme PostgreSQL RDS instans som dabih-zero (`dabih-database`), men med sin egen schema (`keycloak`).

Opprett database bruker og schema for Keycloak:

```sql
-- Koble til dabih_tasks database
CREATE USER keycloak_user WITH PASSWORD 'secure_password';

-- Opprett schema for Keycloak
CREATE SCHEMA IF NOT EXISTS keycloak AUTHORIZATION keycloak_user;

-- Gi nødvendige rettigheter
GRANT ALL PRIVILEGES ON SCHEMA keycloak TO keycloak_user;
GRANT CREATE ON DATABASE dabih_tasks TO keycloak_user;
```

### 2. Deploy Infrastruktur

#### Bruk GitHub Actions

1. Gå til Actions fanen i GitHub repository
2. Velg "OpenTofu Infrastructure" workflow
3. Klikk "Run workflow"
4. Velg action: `apply`
5. Klikk "Run workflow"

#### Manuell Deployment

```bash
cd infrastructure

# Kopier og rediger terraform.tfvars
cp terraform.tfvars.example terraform.tfvars
# Rediger terraform.tfvars med dine verdier

# Initialiser OpenTofu
tofu init

# Se gjennom planen
tofu plan

# Deploy infrastrukturen
tofu apply
```

## Deployment

### Deploy Keycloak

Keycloak deployes automatisk ved push til main branch, eller manuelt via GitHub Actions:

1. Gå til Actions fanen
2. Velg "Deploy Keycloak to AWS Fargate" workflow
3. Klikk "Run workflow"
4. Valgfritt: Spesifiser Keycloak versjon (standard er 26.0)
5. Klikk "Run workflow"

### Manuell deployment via CLI

```bash
# Build og push Docker image
aws ecr get-login-password --region eu-central-1 | docker login --username AWS --password-stdin <ECR_REPOSITORY_URL>
docker build -t dabih-auth-keycloak docker/
docker tag dabih-auth-keycloak:latest <ECR_REPOSITORY_URL>:latest
docker push <ECR_REPOSITORY_URL>:latest

# Deploy ny versjon
aws ecs update-service \
  --cluster dabih-auth-keycloak-cluster \
  --service dabih-auth-keycloak \
  --force-new-deployment
```

## Konfigurasjon

### Keycloak Miljøvariabler

Følgende miljøvariabler konfigureres automatisk:

- `KC_DB`: Database type (postgres)
- `KC_DB_URL`: Full database connection URL med schema
- `KC_DB_USERNAME`: Database bruker
- `KC_DB_PASSWORD`: Database passord
- `KC_DB_SCHEMA`: Database schema (keycloak)
- `KC_HOSTNAME`: Public hostname (auth.trinnvis.no)
- `KC_PROXY`: Proxy mode (edge)
- `KC_HEALTH_ENABLED`: Health check endpoint
- `KC_METRICS_ENABLED`: Metrics endpoint
- `KEYCLOAK_ADMIN`: Admin brukernavn
- `KEYCLOAK_ADMIN_PASSWORD`: Admin passord

### Ressurs Konfigurasjon

Keycloak kjører med følgende ressurser:

- **CPU**: 1 vCPU (1024 units)
- **Minne**: 2 GB (2048 MB)
- **Min/Max instanser**: 1 (kan skaleres ved behov)

## Tilgang og URL-er

- **Keycloak URL**: https://auth.trinnvis.no
- **Admin Console**: https://auth.trinnvis.no/admin
- **Account Console**: https://auth.trinnvis.no/realms/{realm}/account
- **OpenID Connect Discovery**: https://auth.trinnvis.no/realms/{realm}/.well-known/openid-configuration

## Rollback

For å rulle tilbake til en tidligere deployment:

1. Gå til Actions fanen
2. Velg "Rollback Deployment" workflow
3. Klikk "Run workflow"
4. Valgfritt: spesifiser task definition revisjonsnummer
5. Klikk "Run workflow"

## Overvåking

### Se Logger

```bash
# Hent log streams
aws logs describe-log-streams \
  --log-group-name /ecs/dabih-auth-keycloak \
  --order-by LastEventTime \
  --descending

# Se logger
aws logs tail /ecs/dabih-auth-keycloak --follow
```

### Sjekk Service Status

```bash
# Sjekk ECS service status
aws ecs describe-services \
  --cluster dabih-auth-keycloak-cluster \
  --services dabih-auth-keycloak

# Sjekk kjørende tasks
aws ecs list-tasks \
  --cluster dabih-auth-keycloak-cluster \
  --service-name dabih-auth-keycloak
```

## Health Checks

Keycloak har følgende health check endpoints:

- **Container Health Check**: `/health/ready`
- **ALB Health Check**: `/health/ready`
- **Liveness**: `/health/live`
- **Metrics**: `/metrics`
- **Interval**: 30 sekunder
- **Timeout**: 5 sekunder
- **Start Period**: 300 sekunder (5 minutter for oppstart)

## Realm Konfigurasjon

### Opprette ny Realm

1. Logg inn på Admin Console: https://auth.trinnvis.no/admin
2. Klikk på realm dropdown (øverst til venstre)
3. Velg "Create Realm"
4. Konfigurer realm settings

### Konfigurere Clients

For hver applikasjon som skal bruke Keycloak:

1. Naviger til Clients i venstre meny
2. Klikk "Create client"
3. Konfigurer:
   - Client ID: `your-app-name`
   - Client Protocol: `openid-connect`
   - Valid Redirect URIs
   - Web Origins (for CORS)

### Brukeradministrasjon

1. Naviger til Users i venstre meny
2. Klikk "Add user"
3. Fyll ut brukerinformasjon
4. Sett passord under Credentials tab

## Backup og Recovery

### Database Backup

Database backups håndteres av AWS RDS automatisk. Keycloak data ligger i `keycloak` schema.

### Eksportere Realm Konfigurasjon

```bash
# Eksporter realm konfigurasjon
docker exec <container-id> /opt/keycloak/bin/kc.sh export \
  --file /tmp/realm-export.json \
  --realm your-realm

# Kopier fil fra container
docker cp <container-id>:/tmp/realm-export.json ./realm-export.json
```

## Opprydding

For å slette all infrastruktur:

```bash
cd infrastructure
tofu destroy
```

Eller bruk GitHub Actions:
1. Gå til Actions fanen
2. Velg "OpenTofu Infrastructure" workflow
3. Kjør med action: `destroy`

## Sikkerhetshensyn

- Admin credentials lagres i AWS Secrets Manager
- Database credentials lagres separat i Secrets Manager
- HTTPS påtvunget via ALB
- Security groups konfigurert for minimal eksponering
- Keycloak kjører i privat subnet
- Regelmessige sikkerhetspatcher via image updates

## Integrasjon med Applikasjoner

### OpenID Connect

```javascript
// Eksempel konfigurasjon for JavaScript applikasjon
const keycloakConfig = {
  url: 'https://auth.trinnvis.no',
  realm: 'your-realm',
  clientId: 'your-client-id',
};
```

### SAML 2.0

Keycloak støtter også SAML 2.0 for enterprise integrasjoner.

## Support

For problemer eller spørsmål, vennligst opprett en issue i repository.