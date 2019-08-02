provider "google" {
  credentials = "${file("./creds/serviceaccount.json")}"
  project     = "nth-record-246512"
  region      = "europe-west4"
}
