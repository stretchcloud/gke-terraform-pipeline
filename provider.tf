provider "google" {
  credentials = "${file("./creds/serviceaccount.json")}"
  project     = "GCP-Project-Name"
  region      = "europe-west4"
}
