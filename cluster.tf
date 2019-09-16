#
# This file describes the infrastructure
# for a Kubernetes setup on DigitalOcean.
#


# Prompt for the DigitalOcean access token
variable "do_api_token" {}

# The public ssh key to authorize on each cluster node
# NOTE: we do this with the public key file directly instead of via a
# digitalocean_ssh_key resource, since the latter insecurely authorizes root
# login over SSH.
variable "public_key" {}

# Create a user with the given password hash
variable "password_hash"   {}

# Where the cluster lives
variable "cluster_domain_name" {}

# Deploy to San Francisco region 2 by default
variable "cluster_region" {
  default = "sfo2"
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
  region             = "${var.cluster_region}"
  size               = "2gb"
  tags               = ["${digitalocean_tag.cluster.id}"]
  backups            = true
  ipv6               = true
  private_networking = true
  user_data          = "${templatefile("cloud-config.yaml", { password_hash = var.password_hash, public_key = var.public_key })}"
}

resource "digitalocean_droplet" "node_2" {
  name               = "cluster-${random_id.node_2_id.hex}"
  image              = "ubuntu-16-04-x64"
  region             = "${var.cluster_region}"
  size               = "2gb"
  tags               = ["${digitalocean_tag.cluster.id}"]
  backups            = true
  ipv6               = true
  private_networking = true
  user_data          = "${templatefile("cloud-config.yaml", { password_hash = var.password_hash, public_key = var.public_key })}"
}

resource "digitalocean_droplet" "node_3" {
  name               = "cluster-${random_id.node_3_id.hex}"
  image              = "ubuntu-16-04-x64"
  region             = "${var.cluster_region}"
  size               = "2gb"
  tags               = ["${digitalocean_tag.cluster.id}"]
  backups            = true
  ipv6               = true
  private_networking = true
  user_data          = "${templatefile("cloud-config.yaml", { password_hash = var.password_hash, public_key = var.public_key })}"
}


# Create a DigitalOcean firewall, and open ports 22, 80, 443, and 3000-3500
# per Flynn recommendations.
# https://flynn.io/docs/installation/manual#set-up-nodes
resource "digitalocean_firewall" "flynn_firewall" {
  name = "flynn-recommended-firewall-with-ssh"

  tags = ["${digitalocean_tag.cluster.id}"]

  inbound_rule {
      protocol         = "tcp"
      port_range       = "1-65535"
      source_tags      = ["${digitalocean_tag.cluster.id}"]
  }

  inbound_rule {
      protocol         = "udp"
      port_range       = "1-65535"
      source_tags      = ["${digitalocean_tag.cluster.id}"]
  }

  outbound_rule {
      protocol         = "tcp"
      port_range       = "1-65535"
      destination_tags = ["${digitalocean_tag.cluster.id}"]
  }

  outbound_rule {
      protocol         = "udp"
      port_range       = "1-65535"
      destination_tags = ["${digitalocean_tag.cluster.id}"]
  }

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

  outbound_rule {
      protocol                = "tcp"
      port_range              = "80"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
      protocol                = "tcp"
      port_range              = "443"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
      protocol                = "udp"
      port_range              = "53"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
      protocol                = "tcp"
      port_range              = "53"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
      protocol                = "icmp"
      destination_addresses   = ["0.0.0.0/0", "::/0"]
  }
}


# Configure DNS for the main cluster domain
resource "digitalocean_domain" "cluster_domain" {
  name = "${var.cluster_domain_name}"
}


# Point the domain at our cluster's IPs
resource "digitalocean_record" "cluster_domain_a1" {
  name   = "@"
  type   = "A"
  domain = "${digitalocean_domain.cluster_domain.name}"
  value  = "${digitalocean_droplet.node_1.ipv4_address}"
}

resource "digitalocean_record" "cluster_domain_a2" {
  name   = "@"
  type   = "A"
  domain = "${digitalocean_domain.cluster_domain.name}"
  value  = "${digitalocean_droplet.node_2.ipv4_address}"
}

resource "digitalocean_record" "cluster_domain_a3" {
  name   = "@"
  type   = "A"
  domain = "${digitalocean_domain.cluster_domain.name}"
  value  = "${digitalocean_droplet.node_3.ipv4_address}"
}


# Output our DigitalOcean Droplet names and IPV4 addresses.
output "node_1_name" { value = digitalocean_droplet.node_1.name }
output "node_2_name" { value = digitalocean_droplet.node_2.name }
output "node_3_name" { value = digitalocean_droplet.node_3.name }
output "node_1_ipv4" { value = digitalocean_droplet.node_1.ipv4_address }
output "node_2_ipv4" { value = digitalocean_droplet.node_2.ipv4_address }
output "node_3_ipv4" { value = digitalocean_droplet.node_3.ipv4_address }
