#!/usr/bin/env bash
# Invariants of the RENDERED overlay (what Argo applies), beyond schema
# validity. Each one guards a homelab#1931 decision:
#   - one replica + Recreate: one poller, one Deco admin session
#   - AC8 mesh stats off: device_list may interrupt wireless backhaul
#   - the password comes from the Infisical-managed Secret, not a literal
#   - the ServiceMonitor carries the label Prometheus selects on, and selects
#     a label the Service actually has
set -euo pipefail
cd "$(dirname "$0")/.."
out=$(kubectl kustomize overlays 2>/dev/null || kustomize build overlays)
fail() { echo "FAIL: $*"; exit 1; }
doc() { awk -v k="kind: $1" 'BEGIN{RS="\n---\n"} index($0, k) {print}' <<<"$out"; }

dep=$(doc Deployment)
grep -q '^  replicas: 1$' <<<"$dep" || fail "replicas must be 1"
grep -q 'type: Recreate' <<<"$dep" || fail "strategy must be Recreate"
grep -A1 'name: DECO_MESH_STATS_ENABLED' <<<"$dep" | grep -q 'value: "false"' \
  || fail "DECO_MESH_STATS_ENABLED must render as \"false\" (AC8 needs an AC2 measurement first)"
grep -A4 'name: DECO_PASSWORD$' <<<"$dep" | grep -q 'name: deco-exporter-password' \
  || fail "DECO_PASSWORD must come from secretKeyRef deco-exporter-password"
if grep -A1 'name: DECO_PASSWORD$' <<<"$dep" | grep -q 'value:'; then fail "literal DECO_PASSWORD"; fi
grep -q 'limits:' <<<"$dep" && grep -A1 'limits:' <<<"$dep" | grep -q 'memory:' || fail "memory limit required"

grep -q 'kind: Secret$' <<<"$out" && fail "a literal Secret is rendered; use InfisicalSecret"

sm=$(doc ServiceMonitor)
grep -q 'release: prometheus' <<<"$sm" || fail "ServiceMonitor lacks release=prometheus"
svc=$(doc Service)
grep -q 'app.kubernetes.io/name: deco-exporter' <<<"$svc" || fail "Service lacks the label the ServiceMonitor selects"
grep -q 'name: metrics' <<<"$svc" || fail "Service has no 'metrics' port for the ServiceMonitor"
echo "RENDER-INVARIANTS-OK"
