# deco-exporter

Kubernetes deploy manifests (kustomize, Argo CD-managed) for the Deco traffic
exporter. The image is built in
[`dvystrcil/deco-exporter-docker`](https://github.com/dvystrcil/deco-exporter-docker),
which documents the metrics and configuration.

Tracking issue: [dvystrcil/homelab#1931](https://github.com/dvystrcil/homelab/issues/1931).

## Layout

| Path | What |
|---|---|
| `base/deployment.yaml` | one replica, `Recreate`: one poller, one Deco admin session |
| `base/deco-password-secret.yaml` | InfisicalSecret → `deco-exporter-password` (`DECO_PASSWORD` only) |
| `base/harbor-pull-secret.yaml` | InfisicalSecret → Harbor pull credentials |
| `base/servicemonitor.yaml` | `release: prometheus`, 60 s |
| `base/image-updater-rbac.yaml` | lets argocd-image-updater read the pull secret |
| `base/vpa.yaml` | `updateMode: Off`, for re-sizing from measured peaks |
| `overlays/kustomization.yaml` | the image tag; argocd-image-updater writes it |
| `image-updater/` | the `ImageUpdater` CR (semver tags from Harbor `ai/deco-exporter`) |

## Safety defaults

`DECO_MESH_STATS_ENABLED` is `"false"`. It turns on the exporter's
`device_list` read (homelab#1931 AC8), which is the call reported to interrupt
wireless backhaul on some Deco firmware. Turn it on only after an AC2-style
side-by-side measurement (`homelab/bin/network-leg-speedtest.sh`) shows it
doesn't hurt MAIN↔CORE RTT or loss. `tests/test-render.sh` fails CI if it
renders as anything else, so turning it on is a deliberate, reviewed change to
that test too.

## Checks

```bash
tests/test-render.sh   # rendered-overlay invariants (also run in validate.yaml)
```

## License

[MIT](LICENSE).
