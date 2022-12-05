provider "aws" {
  region = "ap-south-1"
  access_key = ""
  secret_key = ""
  }


#create security group and attach to EC2

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.sam_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#create instance
resource "aws_instance" "sam_instance" {
  ami           = "ami-074dc0a6f6c764218"
  instance_type = "t2.micro"
  vpc_security_group_ids      = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

   tags = {
        Name: "sam_ins2"
    }
}



#IAM roleof SSM attach to ec2

resource "aws_iam_policy" "ssm_policy" {
  name               = "ssm_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}


resource "aws_iam_role" "ec2_role" {
    name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_role" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ssm_policy.arn
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2_role.name
}

resource "aws_instance" "sam_instance" {
  ami           = "ami-074dc0a6f6c764218"
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true

   tags = {
        Name: "sam_ins2"
    }
}



#IAM role only access to ec2

resource "aws_iam_policy" "ec2_policy" {
  name               = "ec2_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "ec2_role" {
    name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_role" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_policy.arn
}



##IAM role only access to s3

resource "aws_iam_policy" "s3_policy" {
  name               = "S3_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:GetObject"
          "s3:DeleteObject",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}



resource "aws_iam_role" "ec2_role" {
    name = "ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_policy_role" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

#Create EC2 with multiple attach EBS

resource "aws_ebs_volume" "sameer" {
  availability_zone = "ap-south-1a"
  size              = 1

  tags = {
    Name = "SAMeer${count.index}"
  }
}

resource "aws_volume_attachment" "ebs_attach" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.sameer.id
  instance_id = aws_instance.web.id
}

resource "aws_instance" "web" {
  ami               = "ami-074dc0a6f6c764218"
  availability_zone = "south-ap-1a"
  instance_type     = "t2.micro"

  tags = {
    Name = "SAM1"
  }
}

#Create EFS using terraform

resource "aws_efs_file_system" "hi" {
  creation_token = "my-efs"

  tags = {
    Name = "hello-MULTIVERSE"
  }
}

#create efs attach to EC2
resource "aws_instance" "sam-instance" {
  ami = "ami-0b0dcb5067f052a63"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "my-keypair"

   tags = {
    name = "web-server"
  }
}
#creating EFS FILE SYSTEM 
resource "aws_efs_file_system" "hi" {
  creation_token = "my-efs"

  tags = {
    Name = "hello-MULTIVERSE"
  }
}



#Mounting EFS File System

resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.hi.id
  instance      = aws_instance.sam-instance.id
}

# Create Apllication load balancer and Network load balancer and attach to EC2

#Create Network Load balancer

resource "aws_lb" "sam_nlb" {
  name               = "sam-lb"
  internal           = false
  load_balancer_type = "network"
  subnets            = ["subnet-04f1f4e4343e2a3ef"]

  enable_deletion_protection = false

  tags = {
    Environment = "developer"
  }
}

# Application load balancer

resource "aws_s3_bucket" "sam-buckkket" {
  bucket = "sam-buckkket"

  tags = {
    Name        = "s3-bucket"
    Environment = "dev"
  }
}


resource "aws_lb" "sam-alb" {
  name               = "sam-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["sg-0c7ac4ef39feaf919"]
  subnets            = ["subnet-03b2b86cbe1107575","subnet-04f1f4e4343e2a3ef"]

  enable_deletion_protection = false

  access_logs {
    bucket  = aws_s3_bucket.sam-buckkket.bucket
    prefix  = "sam"
    enabled = true
  }

  tags = {
    Environment = "developer"
  }
}


#attaching ALB & NLB to EC2

resource "aws_elb_attachment" "baz" {
  elb      = aws_lb.sam-alb.id
  elb      = aws_lb.sam_nlb.id
  instance = aws_instance.sam_instance.id
  }
  
  
 resource "aws_instance" "sam_instance" {
  ami           = "ami-074dc0a6f6c764218"
  instance_type = "t2.micro"
  associate_public_ip_address = true

   tags = {
        Name: "sam_ins2"
    }
}


#Create classic load balancer

resource "aws_elb" "sam_elb" {
  name               = "sam-elb"
  availability_zones = ["ap-south-1a"]

  access_logs {
    bucket        = "sam-buckkket"
    bucket_prefix = "sam"
    interval      = 60
  }

  listener {
    instance_port     = 8000
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8000
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "arn:aws:iam::123456789012:server-certificate/certName"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8000/"
    interval            = 30
  }

  instances                   = [aws_instance.sam_instance.id]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "Sameer-elb"
  }
}


# auto scaling group with launch templte
resource "aws_launch_template" "hi-sam" {
  name_prefix   = "hiii"
  image_id      = "ami-sam23"
  instance_type = "t2.micro"
}

resource "aws_autoscaling_group" "hi-sam" {
  availability_zones = ["ap-south-1a"]
  desired_capacity   = 1
  max_size           = 1
  min_size           = 1

  launch_template {
    id      = aws_launch_template.hi-sam.id
    version = "$Latest"
  }
}


#ec2 attach with auto scaling group

resource "aws_autoscaling_attachment" "hi-sam" {
  autoscaling_group_name = aws_autoscaling_group.hi-sam.id
  instance = aws_instance.sam_instance.id
}

 resource "aws_instance" "sam_instance" {
  ami           = "ami-074dc0a6f6c764218"
  instance_type = "t2.micro"
  associate_public_ip_address = true

   tags = {
        Name: "sam_ins2"
    }
}


#Mount efs to ec2

resource "aws_vpc" "my-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-vpc"
  }
}

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.my-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "my-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my-vpc.id

}



resource "aws_route_table" "my-route-table" {
  vpc_id = aws_vpc.my-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id             = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "my-route"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.my-route-table.id
}
 


resource "aws_route" "default_route" {
    route_table_id = aws_route_table.my-route-table.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
}


resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow web inbound traffic"
  vpc_id      =aws_vpc.my-vpc.id

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  
  ingress {
    description = "NFS"
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }


  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_instance" "web-server-instance" {
  ami = "ami-0b0dcb5067f052a63"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "my-keypair"

   tags = {
    name = "web-server"
  }
}
#creating EFS FILE SYSTEM 

resource "aws_efs_file_system" "my_nfs" {
  depends_on = [ aws_security_group.allow_web,aws_instance.web-server-instance, ]
  creation_token = "my_nfs"

  tags = {
    Name = "my_nfs"
  }
}

#Mounting EFS File System


resource "aws_efs_mount_target" "mount" {
  file_system_id = aws_efs_file_system.my_nfs.id
  subnet_id      = aws_subnet.subnet-1.id
}



