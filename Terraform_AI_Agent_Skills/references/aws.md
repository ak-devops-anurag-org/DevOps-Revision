# AWS provider conventions

## Backend

```hcl
terraform {
  backend "s3" {
    bucket         = "<project>-tfstate-<account_id>"
    key            = "<env>/<component>/terraform.tfstate"
    region         = "<region>"
    dynamodb_table = "<project>-tf-locks"
    encrypt        = true
  }
}
```

The S3 bucket needs versioning + encryption enabled, and the DynamoDB table
needs a `LockID` (string) primary key. Bootstrap these two resources once,
outside of the Terraform config that uses them as a backend (chicken-and-egg
problem otherwise) — a small one-off `bootstrap/` module is the usual pattern.

## VPC / networking

- One VPC per environment, CIDR blocks non-overlapping across environments
  (matters if you ever peer or connect via Transit Gateway/VPN).
- Public + private subnet pairs per AZ, minimum 2 AZs for anything beyond a
  sandbox.
- Route tables: public subnets → Internet Gateway; private subnets → NAT
  Gateway (one per AZ for HA, or one shared NAT for dev/cost savings — call
  out the tradeoff rather than picking silently).
- Use `aws_vpc`, `aws_subnet`, `aws_route_table`, `aws_nat_gateway`,
  `aws_internet_gateway` as primitives, or the community
  `terraform-aws-modules/vpc/aws` module for anything non-trivial — don't
  hand-roll VPC wiring from scratch when a well-maintained module exists.

## EC2 / Security Groups

- Never use `0.0.0.0/0` in an ingress rule unless the resource is genuinely
  meant to be public (e.g. an ALB on 443) — flag it explicitly if the user's
  config has this and the resource looks internal.
- Reference security groups by ID/`aws_security_group.x.id`, not by
  hardcoded strings.
- For SQL Server / database EC2 instances (relevant to migration-style work):
  lock ingress to the app-tier SG only, never to a CIDR block, and disable
  public IP assignment unless there's an explicit reason.
- Use `aws_instance` with an explicit `ami` data source lookup
  (`data "aws_ami"` with owner + name filters) rather than a hardcoded AMI ID
  — hardcoded AMI IDs silently go stale/region-locked.

## IAM

- Least privilege: scope policies to specific resource ARNs, not `"*"`,
  wherever the resource type supports it.
- Prefer IAM roles + instance profiles / IRSA (for EKS) over long-lived
  access keys baked into config.
- One role per function, not one broad role reused everywhere.

## Tagging

```hcl
tags = {
  Environment = var.environment
  Project     = var.project
  Owner       = var.owner
  ManagedBy   = "terraform"
}
```

Set a `default_tags` block on the `provider "aws"` block so every resource
inherits these without repeating them per-resource:

```hcl
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      ManagedBy = "terraform"
      Project   = var.project
    }
  }
}
```