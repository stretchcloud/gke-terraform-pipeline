terraform {
  backend "gcs" {
    bucket      = "projectname-tfstate"
    credentials = "./creds/serviceaccount.json"
  }
}