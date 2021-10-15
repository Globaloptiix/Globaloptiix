resource "aws_route53_record" "istio-gateway" {
  allow_overwrite = true
  zone_id         = var.domain_hosted_zone
  name            = "*.${var.domain_name }"
  type            = "A"
  alias {
    name                   = data.kubernetes_service.load_balancer_istio.load_balancer_ingress[0].hostname
    zone_id                = data.aws_elb.elbv1_istio.zone_id
    evaluate_target_health = false
  }

}
#### Amazon is able to point a A record directly to a load balancer name. This is how kubernetes retrieves the hosted zone ID from AWS API. Terraform nor Kubernetes knew about this being provisioned.
