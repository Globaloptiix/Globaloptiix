# Istio locals

locals {
  kube_config = "~/.kube/config"

    helmChartValuesIstio = {
    global = {
      jwtPolicy = "first-party-jwt",
      proxy = {
      privileged =true
      }
    }

  }
}


###################Install Istio (Service Mesh) #######################################

## https://istio.io/latest/docs/setup/install/helm/
## https://github.com/istio/istio/tree/master/manifests/charts/base

# Istio Base components like Custom Resource definitions
# Heml_release is a custom resource terraform used for helm charts
resource "helm_release" "istio-base" {
  namespace  = kubernetes_namespace.istio_system.id
  name       = "istio-base"
  chart      = "${path.module}/istio-1.11.2/manifests/charts/base"
  values = [
    file("istio-1.11.2/manifests/charts/base/values.yaml")
  ]
 depends_on = [module.vpc,module.eks,module.acm,kubernetes_namespace.istio_system]
}

# Istio Service Discovery helm chart- like internal dns but not that

resource "helm_release" "istio-discovery" {
  namespace  = kubernetes_namespace.istio_system.id
  name       = "istio-discovery"
  chart      = "${path.module}/istio-1.11.2/manifests/charts/istio-control/istio-discovery"

  values = [
    file("istio-1.11.2/manifests/charts/istio-control/istio-discovery/values.yaml")
    ]
  depends_on = [helm_release.istio-base]
}


# Istio Ingress gateway helm chart- provision lb and configures ingress

resource "helm_release" "istio-ingress" {
  name       = "istio-ingress"
  chart      = "${path.module}/istio-1.11.2/manifests/charts/gateways/istio-ingress"
  namespace  = kubernetes_namespace.istio_system.id

  values = [
    file("istio-1.11.2/manifests/charts/gateways/istio-ingress/values.yaml")
    ]
   set {
    name  = "gateways.istio-ingressgateway.serviceAnnotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-ssl-cert"
    value = module.acm.this_acm_certificate_arn
  }

  
  depends_on = [helm_release.istio-base]
}
