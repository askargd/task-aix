variable "security_group_id" {
    default = "sg-04c70fd99ecd74d54"
}

variable "subnet_id" {
  default = "subnet-086e32c6efd99323a"
}

variable "ami_id" {
    default = "ami-04a20f4b19f8a7a88"
  
}

variable "user-data" {
  default = "C:/Users/a.daldabay/Documents/simple web-site/patches/v1/Configuration/user-data.sh"
}

variable "instance_name" {
  type = string
  default = "ec2-nginx-dev-askar011"
}

