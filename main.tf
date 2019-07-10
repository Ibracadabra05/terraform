provider "aws" {
  region  = "us-east-1"
  version = "~> 2.15"
}

data "aws_availability_zones" "available" {}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default = 8080
}

variable "server_elb_port" {
  description = "The port the load balancer will listen on for incoming traffic"
  default = 80
}

resource "aws_launch_configuration" "ibrah-useast" {
  image_id           = "ami-40d28157"
  instance_type = "t2.micro"
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

resource "aws_security_group" "webserver-elb" {
  name = "webserver-lb"

  ingress {
    from_port = "${var.server_elb_port}"
    to_port = "${var.server_elb_port}"
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_autoscaling_group" "ibrah-asg" {
  launch_configuration = "${aws_launch_configuration.ibrah-useast.id}"
  availability_zones = "${data.aws_availability_zones.available.names}"

  load_balancers = ["${aws_elb.ibrah-elb.name}"]
  health_check_type = "ELB"

  min_size = 2
  desired_capacity = 2
  max_size = 10

  tag {
    key = "Name"
    value = "ibrah-asg"
    propagate_at_launch = true
  }
}

resource "aws_elb" "ibrah-elb" {
  name = "ibrah-elb"
  availability_zones = "${data.aws_availability_zones.available.names}"
  security_groups = ["${aws_security_group.webserver-elb.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "${var.server_port}"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:${var.server_port}/"
  }
}

output "ibrah_ASG" {
  value = "${aws_autoscaling_group.ibrah-asg}"
}

output "elb_dns_name" {
	value = "${aws_elb.ibrah-elb.dns_name}"
}
