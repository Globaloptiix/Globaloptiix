

resource "kubernetes_namespace" "traefik-ingress" {
  metadata {
    labels = {
      role = "services"
    }

    name = "traefik-ingress"
  }
depends_on = [module.vpc,module.eks]
}

# Istio

resource "kubernetes_namespace" "istio_system" {
  metadata {
    name = "istio-system"
    labels = {
      namespace = "istio-system"
    }
      
  }
}

# Custom apps
resource "kubernetes_namespace" "applications" {
  metadata {
    name = "applications"
  

   labels = {
      istio-injection = "enabled",
      namespace = "applications"
    }

    }  
}