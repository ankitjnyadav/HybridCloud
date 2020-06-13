provider "aws" {
  region     = "ap-south-1"
  //  We should not share it and upload it. Hence using user profile.
  //  access_key = "my-access-key"
  //  secret_key = "my-secret-key"
  profile    =  "terraform"
}

variable "Default_AMI_id" {
  type    = string
  default = "ami-0447a12f28fddb066"
}

variable "Default_InstanceType" {
  type    = string
  default = "t2.micro"
}
resource "aws_default_vpc" "main" {
  tags = {
    Name = "Default VPC"
  }
}
resource "aws_key_pair" "TfAssignment1Key" {
  key_name   = "Terraform-Assignment1"
  public_key = file("/home/ay/PycharmProjects/DevOps/aws_terraform_key.pub")
}

resource "aws_security_group" "allow_http" {
  depends_on = [  aws_default_vpc.main ]
  name        = "Allow_HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_default_vpc.main.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "http"
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "TerraformAMI_Assignment1"{
  ami = var.Default_AMI_id
  instance_type = var.Default_InstanceType
  key_name = aws_key_pair.TfAssignment1Key.key_name
  security_groups = [aws_security_group.allow_http.name]
  tags = {
    Name = "TerraformAMI_Assignment1"
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/ay/Downloads/keycloudclass1.pem")
    host     = aws_instance.TerraformAMI_Assignment1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd"
    ]
  }

}

resource "null_resource" "MyPublicIpRedirection" {
  provisioner "local-exec" {
    command = "echo ${aws_instance.Day3_Instance.public_ip} > publicIP.txt"
  }
}

resource "null_resource" "OpenTheWebSite" {
  depends_on=[null_resource.OpenTheWebSite1]
  provisioner "local-exec" {
    command = "firefox ${aws_instance.Day3_Instance.public_ip}"
  }
}

resource "aws_ebs_volume" "Terra_EBS3" {
  availability_zone = aws_instance.Day3_Instance.availability_zone
  size              = 1
  tags = {
    Name = "Terra_EBS_D3"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.Terra_EBS3.id
  instance_id = aws_instance.Day3_Instance.id
  force_detach = true
}

resource "null_resource" "OpenTheWebSite1" {
  depends_on = [  aws_volume_attachment.ebs_att ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/ay/Downloads/keycloudclass1.pem")
    host     = aws_instance.Day3_Instance.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/ankitjnyadav/DevOps.git /var/www/html"
    ]
  }
}

output "myTest" {
  value = [aws_key_pair.TfAssignment1Key,
          aws_security_group.allow_http]
}