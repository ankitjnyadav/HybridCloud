
//To set a variable in Terraform
variable "my_variable_name" {
  type= string    //We can specify the DataType of the variable
  default = "default_value"
}

output "name_of_op_variable"{
  //It will help to print
  value = "This is the value ${var.my_variable_name}"
}