provider "aws" {
  region     = "ap-south-1"
  //  We should not share it and upload it. Hence using user profile.
  //  access_key = "my-access-key"
  //  secret_key = "my-secret-key"
  profile    =  "terraform"
}

resource "aws_instance" "Day3_Instance"{
  ami = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name = "keycloudclass1"
  security_groups = ["launch-wizard-2"]

  //Tags
  tags = {
    Name = "TerraformAMI_D3"
  }

  //Connection (after its launch)
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("/home/ay/Downloads/keycloudclass1.pem")
    host     = aws_instance.Day3_Instance.public_ip
  }

  //Provisioner only work under resource block
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
