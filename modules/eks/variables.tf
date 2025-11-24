variable "cluster_name" {
  type    = string
  default = "lesson-7-eks"
}

variable "subnet_ids" {
  type = list(string)
}

variable "node_group_name" {
  type    = string
  default = "lesson-7-ng"
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "desired_size" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}
