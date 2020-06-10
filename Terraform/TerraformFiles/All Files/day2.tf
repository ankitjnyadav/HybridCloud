resource "aws_instance" "my_in1"{
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "keycloudclass"
  security_groups = ["launch-wizard-2"]
  tags = {
    Name = "TerraformAMI_1"
  }
}

resource "aws_instance" "my_in2"{
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "keycloudclass"
  security_groups = ["launch-wizard-2"]
  tags = {
    Name = "TerraformAMI_2"
  }
}

output "my_out1" {
  value = "aws_instance.my_in2.availability_zone"
}

resource "aws_ebs_volume" "ebs2" {
  availability_zone = "aws_instance.my_in2.availability_zone"
  size              = 1

  tags = {
    Name = "MyEBS_1"
  }
}
resource "aws_ebs_volume" "ebs_att" {

  availability_zone = "aws_instance.my_in2.availability_zone"
  size              = 1

  tags = {
    Name = "MyEBS_1"
  }
}
