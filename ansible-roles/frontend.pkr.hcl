packer {
  required_plugins {
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

source "amazon-ebs" "amz3_gp3" {
  ami_name      = "frontend-{{timestamp}}"
  instance_type = "t3.micro"
  region        = "ap-south-1"

  source_ami_filter {
    filters = {
      name             = "al2023-ami-2023*"
      architecture     = "x86_64"
      root-device-type = "ebs"
    }
    most_recent = true
    owners      = ["amazon"]
  }

  ssh_username = "ec2-user"
  tags = {
    Name        = "frontend"
    Environment = "Development"
    Owner       = "Konka"
    CreatedBy   = "Packer"
    Monitor     = "true"
  }
}

build {
  name    = "frontend"
  sources = ["source.amazon-ebs.amz3_gp3"]


  provisioner "shell" {
    inline = [
      "sudo dnf install git ansible -y",
      "git clone https://github.com/konka-devops-lab/ansible-roles.git /tmp/ansible-roles",
      "ansible-playbook /tmp/ansible-roles/playbooks/frontend.yml",
      "rm -rf /tmp/ansible-roles",
      "sudo dnf remove git ansible -y"
    ]
  }
}