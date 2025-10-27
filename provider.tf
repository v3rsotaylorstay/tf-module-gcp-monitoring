provider "google" {
  project     = var.project
  region      = var.region
  credentials = "/workspace/credential.json"
}
