###################################################### Route53 Hosted Zone #######################################################

resource "aws_route53_zone" "hosted_zone" {
  name = var.name
  comment = "Public"

  tags = {
    Environment = var.env
  }
}

resource "aws_route53_record" "jenkins_record_set" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "jenkins-ms.${aws_route53_zone.hosted_zone.name}"
  type    = "A"
  alias {
    name                   = aws_lb.test-application-loadbalancer.dns_name
    zone_id                = aws_lb.test-application-loadbalancer.zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "application_record_set" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = "dexter.${aws_route53_zone.hosted_zone.name}"
  type    = "A"
  alias {
    name                   = aws_lb.application-loadbalancer.dns_name
    zone_id                = aws_lb.application-loadbalancer.zone_id
    evaluate_target_health = false
  }
}
