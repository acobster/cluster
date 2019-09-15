#
# This file describes the infrastructure
# for a Kubernetes setup on DigitalOcean.
#


# Prompt for the DigitalOcean access token
variable "do_api_token" {}

# Deploy to San Francisco region 2
variable "cluster_region" {
  default = "sfo2"
}


# Which ssh key to place on each cluster node
# To list SSH keys with the DO CLI, do:
#
#   doctl compute ssh-key list
#
# If you're applying this plan from any machine other than Coby's laptop,
# you'll probably want to update this first.
variable "ssh_key" {
  default = 23249233
}


# Import the Random provider.
# We'll use this to generate names for each Droplet in our cluster.
provider "random" {
  version = "~> 2.2"
}

# Import the DigitalOcean provider.
# This allows us to deploy DO resources.
provider "digitalocean" {
  token   = "${var.do_api_token}"
  version = "~> 1.7"
}


# droplet tags
resource "digitalocean_tag" "cluster" {
  name = "cluster-v2"
}


# Create three Droplets on DigitalOcean, generating a random name for each one.
resource "random_id" "node_1_id" { byte_length = 8 }
resource "random_id" "node_2_id" { byte_length = 8 }
resource "random_id" "node_3_id" { byte_length = 8 }

resource "digitalocean_droplet" "node_1" {
  name               = "cluster-${random_id.node_1_id.hex}"
  image              = "ubuntu-16-04-x64"
  region             = "sfo2"
  size               = "2gb"
  tags               = ["${digitalocean_tag.cluster.id}"]
  backups            = true
  ipv6               = true
  private_networking = true
  ssh_keys           = ["${var.ssh_key}"]
}

resource "digitalocean_droplet" "node_2" {
  name               = "cluster-${random_id.node_2_id.hex}"
  image              = "ubuntu-16-04-x64"
  region             = "sfo2"
  size               = "2gb"
  tags               = ["${digitalocean_tag.cluster.id}"]
  backups            = true
  ipv6               = true
  private_networking = true
  ssh_keys           = ["${var.ssh_key}"]
}

resource "digitalocean_droplet" "node_3" {
  name               = "cluster-${random_id.node_3_id.hex}"
  image              = "ubuntu-16-04-x64"
  region             = "sfo2"
  size               = "2gb"
  tags               = ["${digitalocean_tag.cluster.id}"]
  backups            = true
  ipv6               = true
  private_networking = true
  ssh_keys           = ["${var.ssh_key}"]
}


# Create a DigitalOcean firewall, and open ports 22, 80, 443, and 3000-3500
# per Flynn recommendations.
# https://flynn.io/docs/installation/manual#set-up-nodes
resource "digitalocean_firewall" "flynn_firewall" {
  name = "flynn-recommended-firewall-with-ssh"

  droplet_ids = ["${digitalocean_droplet.node_1.id}",
                 "${digitalocean_droplet.node_2.id}",
                 "${digitalocean_droplet.node_3.id}"]

  inbound_rule {
      protocol           = "tcp"
      port_range         = "22"
      source_addresses   = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
      protocol           = "tcp"
      port_range         = "80"
      source_addresses   = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
      protocol           = "tcp"
      port_range         = "443"
      source_addresses   = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
      protocol           = "tcp"
      port_range         = "3000-3500"
      source_addresses   = ["0.0.0.0/0", "::/0"]
  }
}


# Output our DigitalOcean Droplet names and IPV4 addresses.
output "node_1_name" { value = digitalocean_droplet.node_1.name }
output "node_2_name" { value = digitalocean_droplet.node_2.name }
output "node_3_name" { value = digitalocean_droplet.node_3.name }
output "node_1_ipv4" { value = digitalocean_droplet.node_1.ipv4_address }
output "node_2_ipv4" { value = digitalocean_droplet.node_2.ipv4_address }
output "node_3_ipv4" { value = digitalocean_droplet.node_3.ipv4_address }
