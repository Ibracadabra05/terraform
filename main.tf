provider "aws" {
  region  = "us-east-1"
  version = "~> 2.15"
}

resource "aws_instance" "ibrah-useast1a" {
  ami           = "ami-40d28157"
  instance_type = "t2.micro"
}
