############################################# Wild Card ACM Certificate ###############################################

resource "aws_acm_certificate" "acm_cert" {
  domain_name       = "*.singhritesh85.com"
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }
}

############################################# Record Set for Certificate Validation ###################################

resource "aws_route53_record" "record_cert_validation" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_name
  type    = tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_type
  records = [tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_value]
  ttl     = 60
}

############################################# Introduced Time Delay of 2 min and 30 sec ###############################

resource "time_sleep" "wait_for_ns_update" {
  create_duration = "150s" # 2 minutes 30 seconds
}

############################################# AWS ACM Certificate Validation ##########################################

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [aws_route53_record.record_cert_validation.fqdn]

  depends_on = [time_sleep.wait_for_ns_update]
}
