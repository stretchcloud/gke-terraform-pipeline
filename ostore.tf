terraform {
  backend "gcs" {
    bucket      = "nth-record-246512-tfstate"
    credentials = "./creds/serviceaccount.json"
  }
}