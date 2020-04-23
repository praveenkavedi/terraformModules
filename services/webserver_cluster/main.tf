resource "aws_instance" "GruntWorkInstance" {
  ami = "ami-54d2a63b"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.GurntWorksSG.id]

  tags = {
    Name = "GruntWorkInstance"
  }

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p "${var.server_port} &

EOF
}

resource "aws_security_group" "GurntWorksSG" {
  name = "${var.cluster_name}-SG"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = "8080"
}

output "public_ip" {
  value = aws_instance.GruntWorkInstance.id
  description = "The public IP of the web server"
}


resource "aws_launch_configuration" "ASGLaunchCongif" {
  image_id = "ami-54d2a63b"
  instance_type = "${var.instance_type}"
  security_groups = [aws_security_group.GurntWorksSG.id]

  user_data = <<-EOF
    #!/bin/bash
    echo "Hello, World" > index.html
    nohup busybox httpd -f -p "${var.server_port} &

EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "GruntWorksAutoScalingGroup" {
  launch_configuration = aws_launch_configuration.ASGLaunchCongif.id
  availability_zones = ["ap-south-1a","ap-south-1b","ap-south-1c"]
  max_size = "${var.max_size}"
  min_size = "${var.min_size}"

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

resource "aws_security_group" "elb" {
  name = "${var.cluster_name}-elb"
  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Inbound HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

variable "elb_port" {
  default = 80
}

resource "aws_elb" "example" {
  name               = "${var.cluster_name}-ASG"
  security_groups    = [aws_security_group.elb.id]
  availability_zones = ["ap-south-1a","ap-south-1c"]
  health_check {
    target              = "HTTP:${var.server_port}/"
    interval            = 30
    timeout             = 3
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
  # This adds a listener for incoming HTTP requests.
  listener {
    lb_port           = var.elb_port
    lb_protocol       = "http"
    instance_port     = var.server_port
    instance_protocol = "http"
  }
}
resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.ASGLaunchCongif.id
  availability_zones   = ["ap-south-1a","ap-south-1b","ap-south-1c"]
  min_size = "${var.min_size}"
  max_size = "${var.max_size}"
  load_balancers    = [aws_elb.example.name]
  health_check_type = "ELB"
  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}

output "clb_dns_name" {
  value       = aws_elb.example.dns_name
  description = "The domain name of the load balancer"
}


