variable "cluster_name" {
  description = "The name of the cluster for each environment"
  type = string
}

variable "instance_type" {
  description = "Instances going to use for the respective environments"
  type = string
}

variable "min_size" {
  description = "Minimum instance type"
  type = number
}

variable "max_size" {
  description = "Maximum instance type"
  type = number
}

