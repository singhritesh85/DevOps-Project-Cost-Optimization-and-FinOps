############################################# Wild Card ACM Certificate ###############################################

resource "aws_acm_certificate" "acm_cert" {
  domain_name       = join(".", ["*", "${var.domain_name}"])    ###"*.singhritesh85.com"
  validation_method = "DNS"

  tags = {
    Environment = var.env
  }
}

## Introduced a time sleep of 150 seconds to do the AWS Route53 Nameserver entry in your domain name provider's nameserver ##
resource "time_sleep" "wait_150_seconds" {
  depends_on = [aws_route53_zone.hosted_zone]
  create_duration = "150s"  ### 2 min 30 seconds
}

############################################# Record Set for Certificate Validation ###################################

resource "aws_route53_record" "record_cert_validation" {
  zone_id = aws_route53_zone.hosted_zone.zone_id
  name    = tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_name
  type    = tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_type
  records = [tolist(aws_acm_certificate.acm_cert.domain_validation_options).0.resource_record_value]
  ttl     = 60

  depends_on   = [time_sleep.wait_150_seconds]
}

############################################# AWS ACM Certificate Validation ##########################################

resource "aws_acm_certificate_validation" "acm_certificate_validation" {
  certificate_arn         = aws_acm_certificate.acm_cert.arn
  validation_record_fqdns = [aws_route53_record.record_cert_validation.fqdn]
}
