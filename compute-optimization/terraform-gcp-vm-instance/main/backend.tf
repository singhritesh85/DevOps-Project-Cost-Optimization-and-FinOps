terraform {
  backend "gcs" {
    bucket  = "dolo-dempo"
    prefix  = "state/dexter-vm-instance"
  }
}
