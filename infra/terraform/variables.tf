variable "project_id" {
  type = string
}
variable "region" {
  type    = string
  default = "europe-west1"
}
variable "image_tag" {
  type    = string
  default = "v1"
}

# Sizing
variable "run_max_instances_web" {
  type    = number
  default = 1
}
variable "run_max_instances_worker" {
  type    = number
  default = 1
}

variable "make_bucket_public" {
  type = bool
  default = false
}
