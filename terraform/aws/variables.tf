###
# Required variables without default values
###
variable "client" {
  description = "Client name, lower case and without spaces. This will be used to set tags and name resources"
  type        = string
}
variable "environment" {
  description = "environment name, lower case and without spaces. This will be used for tagging"
  type        = string
}
variable "domain" {
  description = "Base domain to attach the tenant to."
  type        = string
}

variable "tags" {
  description = "Contains default tags for this project"
  type        = map(string)
  default     = {}
}



###
# Optional variables with defaults 
###

variable "region" {
  description = "AWS Region to deploy into"
  type        = string
  default     = "eu-west-1"
}

variable "k3s_storage_endpoint" {
  default     = "sqlite"
  type        = string
  description = "Storage Backend for K3S cluster to use. Valid options are 'sqlite' or 'postgres'"
}

variable "vpc_cidr" {
  default     = "10.105.0.0/16"
  type        = string
  description = "CIDR Subnet to use for the VPC, will be split into multiple /24s for the required private and public subnets"
}

variable "create_public_zone" {
  default = "yes"
  type = string
  description = "Whether to create public zone in route53. true or false, default true"
}

variable "create_private_zone" {
  default = "yes"
  type = string
  description = "Whether to create private zone in route53. true or false, default true"
}

variable "master_node_count" {
  type        = number
  default     = 1
  description = "Number of master nodes to deploy"
}
variable "master_volume_size" {
  type        = number
  default     = 50
  description = "EBS Volume size (GB) attached to the master instance"
}
variable "master_instance_type" {
  type    = string
  default = "t3.large"
}

variable "agent_volume_size" {
  type        = number
  default     = 50
  description = "EBS Volume size (GB) attached to the agent/node instances"
}
variable "agent_node_count" {
  type        = number
  default     = 3
  description = "Number of agent nodes to deploy"
}
variable "agent_instance_type" {
  type    = string
  default = "t3.large"
}

###
# RDS Database configuration, when using postgres as k3s_storage_endpoint
###
variable "db_node_count" {
  type        = number
  default     = 1
  description = "Number of RDS database instances to launch"
}
variable "db_instance_type" {
  type        = string
  description = "Size of RDS database instances to launch"
  default     = "db.r5.large"
}

variable "db_name" {
  default     = null
  type        = string
  description = "Name of database to create in RDS, will use the client name if not specified"
}

variable "db_user" {
  default     = null
  type        = string
  description = "Username for RDS database, will use the client name if not specified"
}

variable "db_password" {
  default     = null
  type        = string
  description = "Password for RDS user, one will be generated if not specified"
}
variable "skip_final_snapshot" {
  default     = true
  type        = bool
  description = "Boolean that defines whether or not the final snapshot should be created on RDS cluster deletion"
}
variable "create_vpc_peering" {
  default     = false
  type        = bool
  description = "Boolean for creating peering to allow for running of test scripts/etc in priv network"
}
variable "peer_vpc_id" {
  default     = "na"
  type        = string
  description = "VPC ID where CI Runner is located, to create peering to allow for running of test scripts/etc in priv network"
}
###
# Local copies of variables to allow for parsing
###
locals {
  name = "${replace(var.client, "-", "")}-${var.environment}"
  base_domain     = "${replace(var.client, "-", "")}.${var.domain}"
  common_tags = merge(
    { Client      = var.client,
      Environment = var.environment,
      Domain      = local.base_domain
    },
  var.tags)
  deploy_rds      = var.k3s_storage_endpoint != "sqlite" ? 1 : 0
  db_name         = var.db_name != null ? var.db_name : local.name
  db_user         = var.db_user != null ? var.db_user : local.name
  db_password     = var.db_password != null ? var.db_password : random_password.db_password.result
  db_node_count   = var.k3s_storage_endpoint != "sqlite" ? var.db_node_count : 0
  ssh_keys        = [] # This has been replaced with a dynamically generated key, but could be extended to allow passing additional ssh keys if needed
  public_subnets  = [cidrsubnet(var.vpc_cidr, 8, 1), cidrsubnet(var.vpc_cidr, 8, 2), cidrsubnet(var.vpc_cidr, 8, 3)]
  private_subnets = [cidrsubnet(var.vpc_cidr, 8, 4), cidrsubnet(var.vpc_cidr, 8, 5), cidrsubnet(var.vpc_cidr, 8, 6)]
  public_zone_id  = var.create_public_zone == "yes" ? aws_route53_zone.public[0].zone_id : data.aws_route53_zone.public[0].zone_id
  private_zone_id  = var.create_private_zone == "yes" ? aws_route53_zone.private[0].zone_id : data.aws_route53_zone.private[0].zone_id
}