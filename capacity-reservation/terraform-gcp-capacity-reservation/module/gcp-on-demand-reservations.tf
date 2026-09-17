resource "google_compute_reservation" "on_demand_reservation" {
  count = 2
  name  = count.index == 0 ? "${var.prefix[0]}-on-demand-open-reservation" : "${var.prefix[0]}-on-demand-targeted-reservation"
  zone  = data.google_compute_zones.available.names[count.index]

  share_settings {
    share_type = "LOCAL"
  }

  specific_reservation_required = count.index == 0 ? false : true  ### Open Reservation allows any matching VM to automatically consume it. 

  specific_reservation {
    count = 1
    
    instance_properties {
      machine_type     = var.machine_type[2]
    }
  }
}
