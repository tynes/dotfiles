packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

variable "project_id" {
  type        = string
  description = "GCP project ID"
  default     = env("GCP_PROJECT_ID")
}

variable "zone" {
  type        = string
  description = "GCP zone for the build VM"
  default     = "us-central1-a"
}

variable "source_image_family" {
  type        = string
  description = "Source image family to use as base"
  default     = "ubuntu-2404-lts-amd64"
}

variable "image_name" {
  type        = string
  description = "Name of the output image"
  default     = "dotfiles-dev-{{timestamp}}"
}

variable "image_family" {
  type        = string
  description = "Image family for the output image"
  default     = "dotfiles-dev"
}

variable "machine_type" {
  type        = string
  description = "Machine type for the build VM"
  default     = "n1-standard-2"
}

variable "disk_size" {
  type        = number
  description = "Disk size in GB"
  default     = 20
}

variable "ssh_username" {
  type        = string
  description = "SSH username for connecting to the build VM"
  default     = "packer"
}

source "googlecompute" "dotfiles" {
  project_id          = var.project_id
  zone                = var.zone
  source_image_family = var.source_image_family
  image_name          = var.image_name
  image_family        = var.image_family
  machine_type        = var.machine_type
  disk_size           = var.disk_size
  ssh_username        = var.ssh_username

  image_description   = "Development environment with dotfiles pre-configured"

  # Add labels for organization
  image_labels = {
    environment = "development"
    managed_by  = "packer"
    created     = "{{timestamp}}"
  }
}

build {
  sources = ["source.googlecompute.dotfiles"]

  # Update system packages
  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y git curl wget build-essential"
    ]
  }

  # Clone dotfiles repo
  provisioner "shell" {
    inline = [
      "git clone https://github.com/tynes/dotfiles.git ~/dotfiles"
    ]
  }

  # Run install script to install all dependencies
  provisioner "shell" {
    inline = [
      "cd ~/dotfiles",
      "chmod +x install.sh",
      "./install.sh"
    ]
    # Increase timeout since this installs many packages
    timeout = "30m"
  }

  # Run setup script to create symlinks
  provisioner "shell" {
    inline = [
      "cd ~/dotfiles",
      "chmod +x setup.sh",
      "./setup.sh"
    ]
  }

  # Re-run install script to initialize Neovim plugins now that config is symlinked
  provisioner "shell" {
    inline = [
      "cd ~/dotfiles",
      "./install.sh"
    ]
    # Allow this to fail gracefully if there are issues with plugin installation
    valid_exit_codes = [0, 1]
  }

  # Clean up
  provisioner "shell" {
    inline = [
      "# Clean package manager cache",
      "sudo apt-get clean",
      "sudo apt-get autoremove -y",

      "# Clear bash history for security",
      "history -c",
      "rm -f ~/.bash_history",

      "# Clear any temporary files",
      "sudo rm -rf /tmp/*",
      "sudo rm -rf /var/tmp/*"
    ]
  }

  # Display completion message
  post-processor "manifest" {
    output = "packer-manifest.json"
    strip_path = true
  }
}
