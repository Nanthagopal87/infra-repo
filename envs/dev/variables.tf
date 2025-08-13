variable "project_id" {
  type = string
}
variable "region" {
  type = string
}
variable "zone" {
  type = string
}
variable "env_name" {
  type = string
}
variable "subnet_cidr" {
  type = string
}
variable "machine_type" {
  type = string
}
variable "image" {
  type = string
}
variable "enable_private_dns" {
  type    = bool
  default = false
}
variable "dns_name" {
  type = string
}
