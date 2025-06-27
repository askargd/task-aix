variable app_name {
    description = "Application name"
    default = "nginxdemos-hello"
    type = string
}

variable environment {
    description = "Environment type"
    default = "test"
    type = string
}

variable username {
  default = "askar011"
}

variable vpc_id {
    description = "Default vpc ID"
    default = "vpc-091ecb6696a6ed277"
}

variable subnet_3b-1 {
    default = "subnet-076d191974cb8e069"
}

variable subnet_3b-2 {
    default = "subnet-049c2f0c621109158"
}

variable natgw_id {
    description = "Manually created NAT Gateway ID"
    default = "nat-03d93011a07ef61ac"
}

# variable alb_ingress_port {
#     default = "80"
# }

variable alb_ingress_proto {
    default = "HTTP"
}

variable container_port {
    description = "Port the container listens on"
    type = number
    default = "80"
}

variable container_image {
    description = "Image used to launch containers"
    default = "nginxdemos/hello"
    type = string
}

variable "health_check_path" {
  description = "Health check path"
  type        = string
  default     = "/"
}

variable "min_capacity" {
    description = "Minimum number of tasks"
    type = number
    default = 1
}

variable "max_capacity" {
    description = "Maximum number of tasks"
    type = number
    default = 10
}