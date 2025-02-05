resource "helm_release" "prometheus_operator_crds" {
  name             = "prometheus-operator-crds"
  namespace        = "monitoring"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "prometheus-operator-crds"
  version          = "17.0.2"
  create_namespace = true
}

resource "helm_release" "cilium" {
  depends_on = [helm_release.prometheus_operator_crds]

  name             = "cilium"
  namespace        = "kube-system"
  repository       = "https://helm.cilium.io"
  chart            = "cilium"
  version          = "1.17.0"
  wait_for_jobs    = true

  values = [
    "${file("../../kubernetes/apps/kube-system/cilium/app/helm-values.yaml")}"
  ]
}

resource "helm_release" "flux_operator" {
  depends_on = [helm_release.cilium]

  name             = "flux-operator"
  namespace        = "flux-system"
  repository       = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart            = "flux-operator"
  version          = "0.13.0"

  values = [
    "${file("../../kubernetes/apps/flux-system/flux-operator/app/values.yaml")}"
  ]
}

resource "helm_release" "flux_instance" {
  depends_on = [helm_release.flux_operator]

  name       = "flux-instance"
  namespace  = "flux-system"
  repository = "oci://ghcr.io/controlplaneio-fluxcd/charts"
  chart      = "flux-instance"
  version    = "0.13.0"

  values = [
    "${file("../../kubernetes/apps/flux-system/flux-operator/instance/values.yaml")}"
  ]
}
