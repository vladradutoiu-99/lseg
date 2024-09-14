terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.54.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "2.13.2"
    }
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}
provider "google" {
  alias   = "google2"
  project = "spiritual-oxide-435516-u4"
  region  = "europe-west3"
}
provider "google-beta" {
  project = "spiritual-oxide-435516-u4"
  region  = "europe-west3"
}