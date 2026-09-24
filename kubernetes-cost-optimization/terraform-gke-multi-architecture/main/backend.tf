terraform {
  backend "gcs" {
    bucket  = "dolo-dempo"
    prefix  = "state/cloud-dns"
  }
}
