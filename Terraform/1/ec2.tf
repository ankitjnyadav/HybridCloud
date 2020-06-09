provider "aws" {
  region     = "ap-south-1"
  //  We should not share it and upload it. Hence using user profile.
  //  access_key = "my-access-key"
  //  secret_key = "my-secret-key"
  profile    =  "terraform"
}

resource "aws_instance" "my_1st_terra_instance"{
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "keycloudclass"
  security_groups = ["launch-wizard-2"]
  tags = {
    Name = "TerraformAMI_1"
  }
}