terraform {
  required_version = ">= 0.13.1"

  required_providers {
    aws        = ">= 3.22.0"
    local      = ">= 1.4"
    random     = ">= 2.1"
    kubernetes = "~> 1.11"
  }
}
### Local defines variable- name and value, you can use variables inside of local variables.
### Random generates random numbers.
### Define Global Things in Variable files.
