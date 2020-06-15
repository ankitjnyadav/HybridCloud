/*
Have to create/launch Application using Terraform

1. Create the key and security group which allow the port 80.
2. Launch EC2 instance.
3. In this Ec2 instance use the key and security group which we have created in step 1.
4. Launch one Volume (EBS) and mount that volume into /var/www/html
5. Developer have uploded the code into github repo also the repo has some images.
6. Copy the github repo code into /var/www/html
7. Create S3 bucket, and copy/deploy the images from github repo into the s3 bucket and change the permission to public readable.
8 Create a Cloudfront using s3 bucket(which contains images) and use the Cloudfront URL to  update in code in /var/www/html

*Optional*
1) Those who are familiar with jenkins or are in devops AL have to integrate jenkins in this task wherever you feel can be integrated
2) create snapshot of ebs

Above task should be done using terraform
*/

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

resource "tls_private_key" "Tf_Private_Key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "Tf_Public_Key" {
  key_name   = "Tf_Public_Key"
  public_key = tls_private_key.Tf_Private_Key.public_key_openssh


  depends_on = [
    tls_private_key.Tf_Private_Key
  ]
}

resource "local_file" "key-file" {
  content  = tls_private_key.Tf_Private_Key.private_key_pem
  filename = "Tf_Private_Key.pem"


  depends_on = [
    tls_private_key.Tf_Private_Key
  ]
}


resource "aws_security_group" "allow_http" {
  depends_on = [  aws_default_vpc.main ]
  name        = "Allow_HTTP"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_default_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "TerraformAMI_Assignment1"{
  ami = var.Default_AMI_id
  instance_type = var.Default_InstanceType
  key_name = aws_key_pair.Tf_Public_Key.key_name
  security_groups = [aws_security_group.allow_http.name]
  tags = {
    Name = "TerraformAMI_Assignment1"
  }

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.Tf_Private_Key.private_key_pem
    //file("/home/ay/PycharmProjects/DevOps/Terraform-Assignment1.pem")
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
    command = "echo ${aws_instance.TerraformAMI_Assignment1.public_ip} > publicIP.txt"
  }
}

resource "null_resource" "OpenTheWebSite" {
  depends_on=[null_resource.OpenTheWebSite1]
  provisioner "local-exec" {
    command = "firefox ${aws_instance.TerraformAMI_Assignment1.public_ip}"
  }
}

resource "aws_ebs_volume" "Terra_EBS3" {
  availability_zone = aws_instance.TerraformAMI_Assignment1.availability_zone
  size              = 1
  tags = {
    Name = "Terra_EBS_D3"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.Terra_EBS3.id
  instance_id = aws_instance.TerraformAMI_Assignment1.id
  force_detach = true
}

resource "null_resource" "OpenTheWebSite1" {
  depends_on = [  aws_volume_attachment.ebs_att ]
  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = tls_private_key.Tf_Private_Key.private_key_pem
    //file("/home/ay/PycharmProjects/DevOps/Terraform-Assignment1.pem")
    host     = aws_instance.TerraformAMI_Assignment1.public_ip
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

resource "aws_s3_bucket" "Bucket_Provisioning" {
  bucket = "ankitjnyadav-tf-github-bucket"
  acl    = "public-read"

  tags = {
    Name        = "ankitjnyadav-tf-github-bucket"
    Environment = "Dev"
  }
}


locals {
  s3_origin_id = "myS3Origin"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.Bucket_Provisioning.bucket_regional_domain_name
    origin_id   = local.s3_origin_id
    custom_origin_config {
            http_port = 80
            https_port = 80
            origin_protocol_policy = "match-viewer"
            origin_ssl_protocols = ["TLSv1", "TLSv1.1", "TLSv1.2"]
        }
    }
    enabled = true
    default_cache_behavior {
        allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
        cached_methods = ["GET", "HEAD"]
        target_origin_id = local.s3_origin_id
        forwarded_values {
            query_string = false
            cookies {
               forward = "none"
            }
        }
        viewer_protocol_policy = "allow-all"
        min_ttl = 0
        default_ttl = 3600
        max_ttl = 86400
    }

    restrictions {
        geo_restriction {
            restriction_type = "none"
        }
    }
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}


//output "myTest" {
//  value = [aws_security_group.allow_http]
//}