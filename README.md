# echo-web

[![validate](https://github.com/matthews-wong/devops-helm-chart-4/actions/workflows/validate.yaml/badge.svg)](https://github.com/matthews-wong/devops-helm-chart-4/actions/workflows/validate.yaml)

A small Helm chart for a static nginx web service. Built to try out chart
patterns I don't get to use day-to-day: per-environment values files, a
hardened pod spec, and validating the rendered output instead of just the
templates.

## What's in the box

- `templates/` - Deployment, Service, ServiceAccount, HorizontalPodAutoscaler,
  PodDisruptionBudget, NetworkPolicy, and a ConfigMap holding the page nginx
  serves.
- `templates/tests/` - a `helm test` hook that curls the Service.
- `values.yaml` - sane defaults for a single environment, checked against
  `values.schema.json` by `helm lint`.
- `values-dev.yaml` / `values-prod.yaml` - overrides layered on top of the
  defaults with `-f values.yaml -f values-<env>.yaml`.

## Usage

```sh
helm template echo-web . -f values.yaml -f values-dev.yaml
helm install echo-web . -f values.yaml -f values-prod.yaml
helm test echo-web
```

## Validation

```sh
./validate.sh
# or, for individual steps:
make lint
make template
```

Runs `helm lint` against the base values and each environment overlay, then
renders every combination and checks it against the Kubernetes schema with
[kubeconform](https://github.com/yannh/kubeconform). Neither tool needs to be
preinstalled - the script downloads pinned, checksum-verified releases into
`~/.cache` if they're missing. The same script runs in CI on every push and
pull request against `main`.

## Design decisions

- **Image pinned by digest.** `image.tag` stays human-readable in `values.yaml`
  while the container actually pulls `repository:tag@digest`, so a rebuild
  can't silently change what ships.
- **Read-only root filesystem.** nginx still needs to write to `/tmp`,
  `/var/cache/nginx` and `/var/run` - those are mounted as `emptyDir` volumes
  rather than loosening `readOnlyRootFilesystem`.
- **`replicas` is omitted when autoscaling is enabled.** Otherwise every
  `helm upgrade` would fight the HPA back down to `replicaCount`.
- **A `checksum/config` pod annotation** hashes the ConfigMap template so
  editing `indexHtml` triggers a rollout instead of leaving old pods serving
  stale content until they're recycled for some other reason.
- **`startupProbe` gates `livenessProbe`/`readinessProbe`.** Their
  `initialDelaySeconds` stay at 0 - the startup check already covers "give the
  container time to come up", so there's only one place that timing is tuned.
- **PodDisruptionBudget and NetworkPolicy are off by default, on in prod.**
  A single dev replica has nothing left to evict once `minAvailable` is met,
  and the default NetworkPolicy `allowFrom` (same-namespace) would need
  tuning for clusters where the ingress controller lives elsewhere - both are
  the kind of thing you want on before a real rollout, not before a local
  `helm template`.
- **`preStop: sleep 5` plus a matching `terminationGracePeriodSeconds`.** A pod
  can still receive traffic for a moment after it's removed from the Service's
  endpoints, so nginx keeps running just long enough to drain those requests
  instead of dropping them.
- **Pod anti-affinity defaults to `soft`.** `preferredDuringScheduling` spreads
  replicas across nodes without blocking scheduling on a single-node dev
  cluster; `podAntiAffinity: hard` is available for clusters where you want it
  enforced.
