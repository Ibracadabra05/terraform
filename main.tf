provider "aws" {
  region  = "us-east-1"
  version = "~> 2.15"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  default     = 8080
}

resource "aws_instance" "ibrah-useast-1a" {
  ami                    = "ami-40d28157"
  instance_type          = "t2.micro"
  vpc_security_group_ids = ["${aws_security_group.webserver.id}"]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p "${var.server_port}" &
              EOF

  tags = {
    Name = "ibrah-useast-1a"
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
}

output "public_ip" {
  value = "${aws_instance.ibrah-useast-1a.public_ip}"
}
