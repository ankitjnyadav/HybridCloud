provider "aws" {
  region = "ap-south-1"
  profile = "ay"
}

//To set a variable in Terraform
variable "ami_id" {
  type= string    //We can specify the DataType of the variable
  default = "ami-0732b62d310b80e97"
}

module "module_1"{
    source = "./module_1"
    //We would have to initialize the module folder as well
}

resource "aws_instance" "my_wc2_instance" {
  ami = var.ami_id
  instance_type = var.ami_type
}
output "whats_my_AZ" {
  value = aws_instance.my_wc2_instance.availability_zone
}