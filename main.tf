provider "aws" {
  region  = "us-east-1"
  version = "~> 2.15"
}

data "aws_availability_zones" "available" {}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

resource "aws_launch_configuration" "ibrah-useast" {
  image_id        = "ami-40d28157"
  instance_type   = "t2.micro"
  security_groups = ["${aws_security_group.webserver.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "webserver" {
  name = "webserver"

  ingress {
    from_port = "${var.server_port}"
    to_port = "${var.server_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "ibrah-asg" {
  launch_configuration = "${aws_launch_configuration.ibrah-useast.id}"
  availability_zones = "${data.aws_availability_zones.available.names}"

  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "ibrah-asg"
    propagate_at_launch = true
  }
}

output "ibrah_ASG" {
  value = "${aws_autoscaling_group.ibrah-asg}"
}
