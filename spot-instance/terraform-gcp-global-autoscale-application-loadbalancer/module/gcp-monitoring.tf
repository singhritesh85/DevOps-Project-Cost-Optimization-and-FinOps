###################################################### GCP Cloud Monitor Notification Channel ####################################################

resource "google_monitoring_notification_channel" "email" {
  display_name = "Notification Alert Email on Group Email ID"

  type = "email"

  labels = {
    email_address = var.notification_email
  }
}

####################### GCP Cloud SQL CPU Utilization, Memory Utilization, Disk Utilization and High Connection Alert ############################

resource "google_monitoring_alert_policy" "cloud_sql_cpu" {
  display_name = "Cloud SQL - High CPU"

  project = var.project_name
  combiner = "OR"

  conditions {
    display_name = "Cloud SQL CPU > 80%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloudsql_database"
        AND resource.labels.database_id = "${var.project_name}:${google_sql_database_instance.db_instance.name}"
        AND metric.type = "cloudsql.googleapis.com/database/cpu/utilization"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 0.80
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content = <<-EOT
      Cloud SQL instance google_sql_database_instance.db_instance.name 
      CPU utilization has been above 80% for 5 minutes.
    EOT
  }

  user_labels = {
    service = "cloud-sql"
    severity = "warning"
  }
}

resource "google_monitoring_alert_policy" "cloud_sql_memory" {
  display_name = "Cloud SQL - High Memory"

  project  = var.project_name
  combiner = "OR"

  conditions {
    display_name = "Cloud SQL Memory > 80%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloudsql_database"
        AND resource.labels.database_id = "${var.project_name}:${google_sql_database_instance.db_instance.name}"
        AND metric.type = "cloudsql.googleapis.com/database/memory/utilization"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 0.80
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content = <<-EOT
      Cloud SQL instance var.project_namevar.project_name
      memory utilization has been above 80% for 5 minutes.
    EOT
  }

  user_labels = {
    service  = "cloud-sql"
    severity = "warning"
  }
}

resource "google_monitoring_alert_policy" "cloudsql_disk_utilization" {
  project      = var.project_name
  display_name = "Cloud SQL - Disk Utilization > 75%"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL disk utilization > 75%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloudsql_database"
        AND resource.labels.database_id = "${var.project_name}:${google_sql_database_instance.db_instance.name}"
        AND metric.type = "cloudsql.googleapis.com/database/disk/utilization"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 0.75
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content = <<-EOT
      Cloud SQL instance ${google_sql_database_instance.db_instance.name} 
      disk utilization has exceeded 75% for 5 minutes.

      Please check database storage usage and consider increasing
      the Cloud SQL storage capacity.
    EOT
  }

  user_labels = {
    service  = "cloud-sql"
    severity = "warning"
  }
}

resource "google_monitoring_alert_policy" "cloudsql_high_connections" {
  project      = var.project_name
  display_name = "Cloud SQL - High Connections"
  combiner     = "OR"

  conditions {
    display_name = "Cloud SQL connections > 80%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "cloudsql_database"
        AND resource.labels.database_id = "${var.project_name}:${google_sql_database_instance.db_instance.name}"
        AND metric.type = "cloudsql.googleapis.com/database/network/connections"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 80
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content = <<-EOT
      Cloud SQL instance ${google_sql_database_instance.db_instance.name}
      has more than 80 active database connections for 5 minutes.

      Check connection pooling, application connection leaks,
      and the Cloud SQL max_connections configuration.
    EOT
  }

  user_labels = {
    service  = "cloud-sql"
    severity = "warning"
  }
}

################################################## GCP Spot VM Instance CPU, Memory and Disk Utilization Percentage ##########################################

resource "google_monitoring_alert_policy" "vm_cpu_high" {
  count        = 2
  project      = var.project_name
  display_name = "Ondemand GitLab Server and Spot GitLab Runner VM - CPU Utilization > 80% (${google_compute_instance.vm_instance[count.index].name})"
  combiner     = "OR"

  conditions {
    display_name = "VM CPU utilization > 80%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "gce_instance"
        AND resource.labels.instance_id = "${google_compute_instance.vm_instance[count.index].instance_id}"
        AND resource.labels.zone = "${google_compute_instance.vm_instance[count.index].zone}"
        AND metric.type = "compute.googleapis.com/instance/cpu/utilization"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 0.80
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name] 

  documentation {
    content = "Ondemand GitLab Server and GitLab Runner Spot VM google_compute_instance.vm_instance[count.index].name (ID: ${google_compute_instance.vm_instance[count.index].instance_id}) CPU utilization has exceeded 80% for 5 minutes."
  }
}

resource "google_monitoring_alert_policy" "vm_memory_high" {
  count        = 2
  project      = var.project_name
  display_name = "Ondemand GitLab Server and GitLab Runner Spot VM - Memory Utilization > 80% (${google_compute_instance.vm_instance[count.index].name})"
  combiner     = "OR"

  conditions {
    display_name = "VM memory utilization > 80%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "gce_instance"
        AND resource.labels.instance_id = "${google_compute_instance.vm_instance[count.index].instance_id}"
        AND resource.labels.zone = "${google_compute_instance.vm_instance[count.index].zone}"
        AND metric.type = "agent.googleapis.com/memory/percent_used"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 80
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name] 

  documentation {
    content = "Ondemand GitLab Server and GitLab Runner Spot VM google_compute_instance.vm_instance[count.index].name (ID: ${google_compute_instance.vm_instance[count.index].instance_id}) memory utilization has exceeded 80% for 5 minutes."
  }
}

resource "google_monitoring_alert_policy" "vm_disk_high" {
  count        = 2
  project      = var.project_name
  display_name = "Ondemand GitLab Server and GitLab Runner Spot VM - Disk Utilization > 75% (${google_compute_instance.vm_instance[count.index].name})"
  combiner     = "OR"

  conditions {
    display_name = "VM disk utilization > 75%"

    condition_threshold {
      filter = <<-EOT
        resource.type = "gce_instance"
        AND resource.labels.instance_id = "${google_compute_instance.vm_instance[count.index].instance_id}"
        AND resource.labels.zone = "${google_compute_instance.vm_instance[count.index].zone}"
        AND metric.type = "agent.googleapis.com/disk/percent_used"
      EOT

      comparison      = "COMPARISON_GT"
      threshold_value = 75
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_MEAN"

        cross_series_reducer = "REDUCE_MEAN"

        group_by_fields = [
          "metric.label.device",
          "metric.label.state"
        ]
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name] 

  documentation {
    content = "Ondemand GitLab Server and GitLab Runner Spot VM google_compute_instance.vm_instance[count.index].name (ID: ${google_compute_instance.vm_instance[count.index].instance_id}) disk utilization has exceeded 75% for 5 minutes."
  }
}

######################################## Synthetic Monitoring using GCP Cloud Monitor ##################################################

resource "google_monitoring_uptime_check_config" "login_webapp" {
  project      = var.project_name
  display_name = "Cost Optimization - Login WebApp"
  timeout      = "30s"
  period       = "60s"
  
  selected_regions = [
    "USA_OREGON",
    "ASIA_PACIFIC",
    "EUROPE"
  ]

  monitored_resource {
    type = "uptime_url"

    labels = {
      project_id = var.project_name
      host       = "costoptimization.singhritesh85.com"
    }
  }

  http_check {
    path         = "/"
    port         = 443
    use_ssl      = true
    validate_ssl = true

    request_method = "GET"

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_2XX"
    }

    accepted_response_status_codes {
      status_class = "STATUS_CLASS_3XX"
    }
  }

  user_labels = {
    service  = "cost-optimization"
    endpoint = "login-webapp"
  }
  
  depends_on = [
    google_compute_backend_service.gcp_alb_backend,
    google_compute_url_map.costoptimization_urlmap,
    google_compute_url_map.http_redirect,
    google_compute_target_https_proxy.gcp_target_https_proxy,
    google_compute_global_forwarding_rule.lb_frontend_https,
  ]
}

resource "google_monitoring_alert_policy" "login_webapp_down" {
  project      = var.project_name
  display_name = "Cost Optimization - Login WebApp Down"
  combiner     = "OR"

  conditions {
    display_name = "Login WebApp uptime check failed"

    condition_threshold {
      filter = <<-EOT
        resource.type = "uptime_url"
        AND metric.type = "monitoring.googleapis.com/uptime_check/check_passed"
        AND metric.labels.check_id = "${google_monitoring_uptime_check_config.login_webapp.uptime_check_id}"
      EOT

      comparison      = "COMPARISON_LT"
      threshold_value = 1
      duration        = "300s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_FRACTION_TRUE"
        cross_series_reducer = "REDUCE_MAX" ### Combines all regional streams into one
        group_by_fields      = []           ### Empty means group everything globally into 1 stream
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]

  documentation {
    content = <<-EOT
      Cost Optimization Login WebApp is unavailable.

      URL:
      https://costoptimization.singhritesh85.com/

      The uptime check has failed for 5 minutes.
    EOT
  }

  user_labels = {
    service  = "cost-optimization"
    severity = "critical"
  }
}

resource "google_monitoring_alert_policy" "login_webapp_ssl_expiry" {
  project      = var.project_name
  display_name = "Cost Optimization - SSL Certificate Expiry"
  combiner     = "OR"

  conditions {
    display_name = "SSL certificate expires within 30 days"

    condition_threshold {
      filter = <<-EOT
        resource.type = "uptime_url"
        AND metric.type = "monitoring.googleapis.com/uptime_check/time_until_ssl_cert_expires"
        AND metric.labels.check_id = "${google_monitoring_uptime_check_config.login_webapp.uptime_check_id}"
      EOT

      comparison      = "COMPARISON_LT"
      threshold_value = 2592000
      duration        = "300s"

      aggregations {
        alignment_period     = "300s"
        per_series_aligner   = "ALIGN_NEXT_OLDER"
        cross_series_reducer = "REDUCE_MAX" ### Combines all regional streams into one
        group_by_fields      = []           ### Empty means group everything globally into 1 stream
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.name
  ]

  documentation {
    content = <<-EOT
      SSL certificate for:

      https://costoptimization.singhritesh85.com/

      is approaching expiration. The certificate expires within
      30 days.

      Please renew the SSL certificate.
    EOT
  }

  user_labels = {
    service  = "cost-optimization"
    severity = "warning"
  }
}
