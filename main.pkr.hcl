# Variables
variable "access_key" {
  type    = string
  default = "${env("AWS_ACCESS_KEY_ID")}"
}
variable "secret_key" {
  type    = string
  default = "${env("AWS_SECRET_ACCESS_KEY")}"
}
variable "region" {
  type    = string
  default = "${env("AWS_DEFAULT_REGION")}"
}

locals {
  purpose   = "cache"
  name      = "ami-${local.purpose}-base"
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
  common_tags = {
    Purpose = local.purpose
  }
  provisiner_path = "playbooks"
}


# Data Sources
data "amazon-ami" "ubuntu-20-04" {
  filters = {
    name                = "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
    root-device-type    = "ebs"
    virtualization-type = "hvm"
  }
  most_recent = true
  owners      = ["099720109477"]
  region      = "${var.region}"
}


source "amazon-ebs" "ami" {
  ami_name        = local.name
  ami_description = "AMI para desenvolvimnento"
  instance_type   = "t3.medium"
  region          = var.region
  source_ami      = data.amazon-ami.ubuntu-20-04.id
  ssh_username    = "ubuntu"
  tags = merge(local.common_tags,
    {
      Name     = "${local.name}"
      CreateAt = "${local.timestamp}"
  })
}

build {
  sources = ["source.amazon-ebs.ami"]

  provisioner "ansible" {
    ansible_env_vars = ["ANSIBLE_HOST_KEY_CHECKING=False"]
    extra_arguments = ["--extra-vars", "ansible_python_interpreter=/usr/bin/python3",
    "--extra-vars", "@${local.provisiner_path}/vars/main.yml"]
    roles_path           = "${local.provisiner_path}/roles"
    galaxy_file          = "${local.provisiner_path}/roles/requirements.yml"
    galaxy_force_install = true
    playbook_file        = "${local.provisiner_path}/provision.yml"
    user                 = "ubuntu"
  }

  provisioner "file" {
    destination = "/tmp/test.py"
    source      = "test.py"
  }

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install python3-pip -y",
      "sudo pip3 install --upgrade pip pytest pytest-testinfra importlib",
      "sudo pytest -v /tmp/test.py"
    ]
  }
}
