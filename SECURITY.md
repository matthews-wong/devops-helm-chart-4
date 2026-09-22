# Security policy

This chart has no tagged releases yet - the latest commit on `main` is the
supported version.

## Reporting a vulnerability

Please open a private report via
[GitHub Security Advisories](https://github.com/matthews-wong/devops-helm-chart-4/security/advisories/new)
rather than a public issue. Include the chart version (or commit SHA), the
values used to render the affected manifest, and the impact you observed.

## Scope

Things worth reporting here: a default value that weakens the pod's
`securityContext`, an unpinned image reference, or a template that could
render a manifest granting broader access than the values imply (for example
a `NetworkPolicy` `allowFrom` that's wider than documented).
