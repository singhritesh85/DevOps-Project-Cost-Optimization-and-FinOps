resource "google_compute_future_reservation" "gcp_future_capacity_reservations" {
  provider = google-beta  
  name = "${var.prefix[0]}-future-capacity-reservations"
  zone = data.google_compute_zones.available.names[0]

  auto_delete_auto_created_reservations = true  ### Automatically delete future reservation when the window ends.

  # The exact number of VMs you want guaranteed at peak
  specific_sku_properties {
    total_count = 5 
    
    instance_properties {
      machine_type = "n4-standard-4"
    }
  }

  time_window {
    start_time = "2026-12-01T00:00:00Z"
    end_time   = "2026-12-31T00:00:00Z"
  }
}
