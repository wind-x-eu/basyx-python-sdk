# BaSyx AAS Server – Helm Chart

Deployt die drei BaSyx-Python-Server-Komponenten – **Repository**, **Registry** und
**Discovery** – als getrennte Deployments/Services und exponiert jede über eine
**eigene Subdomain** mit **Let's Encrypt** TLS-Zertifikat (cert-manager, nginx-Ingress).

Die Images stammen aus dem GHCR-Build-Workflow dieses Repos
(`.github/workflows/build-and-publish-ghcr.yaml`).

## Warum getrennte Hosts?

Alle drei Server nutzen denselben Basispfad `/api/v3.1/`, servieren darunter aber
unterschiedliche Ressourcen – und `/api/v3.1/description` sowie der Root-Pfad
kollidieren. Ein gemeinsamer Host+Pfad geht daher nicht sauber; jede Komponente
bekommt einen eigenen Host und behält den Standard-Basispfad.

| Komponente | Host (Default) | Charakteristische Endpoints |
| --- | --- | --- |
| repository | `aas-windx.cluster.swms-cloud.com` | `/api/v3.1/shells`, `/submodels`, `/concept-descriptions` |
| registry | `registry-aas-windx.cluster.swms-cloud.com` | `/api/v3.1/shell-descriptors`, `/submodel-descriptors` |
| discovery | `discovery-aas-windx.cluster.swms-cloud.com` | `/api/v3.1/lookup/shells`, `/lookup/shellsByAssetLink` |

## Voraussetzungen

- Kubernetes-Cluster mit **nginx-ingress-controller** (IngressClass `nginx`)
- **cert-manager** inkl. ClusterIssuer `letsencrypt-prod`
- Eine `StorageClass` für die PVCs (oder `persistence.enabled=false` pro Komponente)
- **DNS:** alle drei Hosts oben zeigen auf die IP des Ingress-Load-Balancers

## Installation

```bash
helm upgrade --install basyx-aas \
  server/example_configurations/helm \
  --namespace windx-aas --create-namespace
```

Die Standardwerte in [values.yaml](values.yaml) sind bereits auf das windx-aas-Deployment
vorkonfiguriert (Hosts, ClusterIssuer `letsencrypt-prod`).

### Privates GHCR-Image

Falls die Packages privat sind, zuerst ein Pull-Secret anlegen und referenzieren:

```bash
kubectl -n windx-aas create secret docker-registry ghcr-pull-secret \
  --docker-server=ghcr.io \
  --docker-username=<github-user> \
  --docker-password=<ghcr-pat>

helm upgrade --install basyx-aas server/example_configurations/helm \
  -n windx-aas --create-namespace \
  --set imagePullSecrets[0].name=ghcr-pull-secret
```

## Struktur der Werte

- `global.imageTag` / `global.imagePullPolicy` – für alle Komponenten
- `ingress.*` – gemeinsame Ingress-Defaults (className, clusterIssuer, Annotationen)
- `defaultResources`, `defaultProbes` – Fallback je Komponente
- `components.<name>` – pro Komponente:
  - `enabled`, `image`, `tag` (optional), `host`, `tlsSecretName`
  - `persistence.*` – eigenes PVC (RWO), gemountet auf `mountPath`
  - `env` – **wörtlich** an den Container übergeben. Deshalb ist die
    unterschiedliche Konfiguration explizit sichtbar:
    - repository/registry: `STORAGE`, `STORAGE_PERSISTENCY`, `STORAGE_OVERWRITE`
    - discovery: `storage_path` (voller Dateipfad; nur dann persistiert die Discovery)

### Einzelne Komponente abschalten

```bash
helm upgrade --install basyx-aas server/example_configurations/helm \
  -n windx-aas --set components.discovery.enabled=false
```

## Zertifikate prüfen

```bash
kubectl -n windx-aas get certificate
# je Host ein Secret: basyx-repository-tls, basyx-registry-tls, basyx-discovery-tls
```

## Smoke-Tests

```bash
curl https://aas-windx.cluster.swms-cloud.com/api/v3.1/shells
curl https://registry-aas-windx.cluster.swms-cloud.com/api/v3.1/shell-descriptors
curl https://discovery-aas-windx.cluster.swms-cloud.com/api/v3.1/lookup/shells
```

## Deinstallation

```bash
helm uninstall basyx-aas -n windx-aas
# PVCs bleiben erhalten; bei Bedarf manuell löschen:
kubectl -n windx-aas delete pvc -l app.kubernetes.io/part-of=basyx-aas-server
```
