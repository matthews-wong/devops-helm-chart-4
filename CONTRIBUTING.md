# Contributing

## Local setup

Nothing to install up front - `./validate.sh` downloads pinned, checksum-
verified `helm` and `kubeconform` binaries into `~/.cache` the first time you
run it if they're not already on `PATH`.

## Making a change

1. Edit the templates or values.
2. If you added or renamed a key in `values.yaml`, update
   `values.schema.json` to match - `helm lint` checks values against it.
3. Run `./validate.sh` (or `make validate`). It lints the chart and each
   environment overlay, then renders and schema-checks the output.
4. If a default's rationale isn't obvious from the diff, add a line to the
   README's "Design decisions" section.

## Commit style

Small, focused commits with a
[Conventional Commits](https://www.conventionalcommits.org/) subject, e.g.
`feat(chart): add topology spread constraints`.
