# allure-docker-service-chart

[![Chart](https://github.com/Think-Cube/allure-docker-service-chart/actions/workflows/chart.yml/badge.svg)](https://github.com/Think-Cube/allure-docker-service-chart/actions/workflows/chart.yml)
[![Release](https://img.shields.io/github/v/release/Think-Cube/allure-docker-service-chart)](https://github.com/Think-Cube/allure-docker-service-chart/releases)
[![License](https://img.shields.io/github/license/Think-Cube/allure-docker-service-chart)](LICENSE)

Helm chart for [Allure Docker Service](https://github.com/fescobar/allure-docker-service) on Kubernetes, with an optional Allure UI, ingress and persistent report storage.

The chart is published to GitHub Container Registry as an OCI artifact and signed with keyless Cosign. It is tested with Helm 4 and also installs with Helm 3.8 or newer, the first version with OCI support.

## Install

```bash
helm install allure oci://ghcr.io/think-cube/charts/allure-docker-service \
  --version 1.0.0 \
  --namespace allure --create-namespace \
  --set api.security.adminUser=admin \
  --set api.security.adminPassword='change-me'
```

Security is on by default, so the install fails until you set an admin user and password, or point `api.security.existingSecret` to a Secret you manage. That Secret needs the keys `SECURITY_USER` and `SECURITY_PASS`, and optionally `SECURITY_VIEWER_USER` and `SECURITY_VIEWER_PASS`.

Without an ingress, reach the API with a port-forward; the install notes print the command.

### With ingress and the UI

```yaml
api:
  urlPrefix: /allure-api
  tls: true
  security:
    existingSecret: allure-credentials
ui:
  enabled: true
ingress:
  enabled: true
  className: nginx
  annotations:
    nginx.ingress.kubernetes.io/proxy-body-size: 500m
  api:
    host: allure-api.example.com
  ui:
    host: allure.example.com
  tls:
    - secretName: allure-tls
      hosts:
        - allure-api.example.com
        - allure.example.com
```

The UI is off by default because upstream has not updated it since January 2021; the API serves reports on its own. When the UI is enabled, it reaches the API at the ingress host and prefix, or at `ui.publicApiUrl` if you set it.

## Storage

Reports are stored in a PersistentVolumeClaim of the cluster's default storage class. The claim is kept when the release is uninstalled, so reports survive a reinstall; set `persistence.keepOnUninstall: false` to delete it with the release. Allure runs as a single replica because all reports live on one volume.

## Values

| Key | Default | Description |
|---|---|---|
| `api.image.repository` | `frankescobar/allure-docker-service` | API image |
| `api.image.tag` | `2.44.0` | API image tag |
| `api.urlPrefix` | `""` | Path prefix the API is served under, for example `/allure-api` |
| `api.checkResultsEverySeconds` | `NONE` | Seconds between checks for new results, or `NONE` to generate reports on request |
| `api.keepHistory` | `true` | Keep the history of previous reports |
| `api.tls` | `false` | Set when clients reach the API over HTTPS |
| `api.security.enabled` | `true` | Require a login |
| `api.security.makeViewerEndpointsPublic` | `false` | Let anyone read reports without logging in |
| `api.security.existingSecret` | `""` | Existing Secret with the credentials |
| `api.security.adminUser` / `adminPassword` | `""` | Admin credentials, required without an existing Secret |
| `api.security.viewerUser` / `viewerPassword` | `""` | Optional read-only user |
| `api.extraEnv` | `[]` | Extra environment variables for the API |
| `api.resources` | requests `250m`/`1Gi`, limit `2Gi` | Resources of the API container |
| `ui.enabled` | `false` | Deploy the Allure UI |
| `ui.image.tag` | `7.0.3` | UI image tag |
| `ui.urlPrefix` | `""` | Path prefix the UI is served under |
| `ui.publicApiUrl` | `""` | URL browsers use to reach the API; required without an ingress |
| `service.type` | `ClusterIP` | Service type |
| `service.apiPort` / `uiPort` | `5050` / `5252` | Service ports |
| `ingress.enabled` | `false` | Create an Ingress |
| `ingress.className` | `""` | Ingress class |
| `ingress.annotations` | `{}` | Ingress annotations |
| `ingress.api.host` / `ingress.ui.host` | `allure-api.example.com` / `allure.example.com` | Hosts |
| `ingress.tls` | `[]` | TLS settings |
| `persistence.enabled` | `true` | Store reports in a PersistentVolumeClaim |
| `persistence.existingClaim` | `""` | Use an existing claim |
| `persistence.storageClass` | `""` | Storage class; `-` disables dynamic provisioning |
| `persistence.size` | `5Gi` | Size of the claim |
| `persistence.keepOnUninstall` | `true` | Keep the claim when the release is uninstalled |
| `serviceAccount.create` | `true` | Create a ServiceAccount |
| `podSecurityContext` | non-root UID `1000`, `RuntimeDefault` seccomp | Pod security context |
| `securityContext` | no privilege escalation, all capabilities dropped | Container security context |
| `nodeSelector`, `tolerations`, `affinity` | empty | Scheduling |

`values.schema.json` validates every value, so a typo in a key fails the install instead of being ignored.

## Verify the chart

```bash
cosign verify ghcr.io/think-cube/charts/allure-docker-service:1.0.0 \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  --certificate-identity-regexp '^https://github\.com/Think-Cube/workflows/\.github/workflows/helm-chart\.yml@refs/tags/v.+$'
```

## Moving from allure-docker-helm-chart

Releases of the earlier `allure-docker-helm-chart` chart are no longer published. This chart replaces it with release-based resource names, installation into the release namespace and report storage in a claim of your storage class instead of a `hostPath` volume.

Install this chart as a new release. To keep existing reports, copy the contents of the old volume (`/allure/projects` on the node) into the new claim, for example with `kubectl cp` into the running API pod at `/app/projects`.

## Development

Pull requests lint the chart, validate the rendered manifests with kubeconform and install it into a kind cluster with each file in `ci/`, then run `helm test`. Pushing a `vX.Y.Z` tag that matches `version` in `Chart.yaml` publishes the chart.

## License

This project is licensed under the [MIT License](LICENSE).
