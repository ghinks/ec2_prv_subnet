variable "region" {
  description = "The region where the resources will be created"
  default     = "us-west-2"
}
variable "availability_zone" {
  description = "The availability zone where the resources will be created"
  default     = "us-west-2a"
}
variable "instance_count" {
  description = "The number of instances to create"
  default     = 3
}