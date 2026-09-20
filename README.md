# echo-web

A small Helm chart for a static nginx web service. Built to try out chart
patterns I don't get to use day-to-day: per-environment values files, a
hardened pod spec, and validating the rendered output instead of just the
templates.

## What's in the box

- `templates/` - Deployment, Service, ServiceAccount, HorizontalPodAutoscaler,
  and a ConfigMap holding the page nginx serves.
- `values.yaml` - sane defaults for a single environment.
- `values-dev.yaml` / `values-prod.yaml` - overrides layered on top of the
  defaults with `-f values.yaml -f values-<env>.yaml`.

## Usage

```sh
helm template echo-web . -f values.yaml -f values-dev.yaml
helm install echo-web . -f values.yaml -f values-prod.yaml
```

## Design decisions

More detail lands here as the chart grows.
