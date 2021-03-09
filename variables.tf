variable "region" {
  default = "ap-southeast-2"
}
variable "name" {
  description = "Name of the Instance"
  default = "dronenginxdemo"
}
variable "costcode" {
  description = "Cost Code for the instance"
  default = "apcjsa"
}
variable "ttl" {
  description = "TTL"
  default = "7"
}

variable "environment" {
  description = "Type of Environment Deployed in"
  default = "non-prod"
}