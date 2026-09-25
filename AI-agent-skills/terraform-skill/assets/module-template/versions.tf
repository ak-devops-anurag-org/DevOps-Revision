# versions.tf
#
# Pin Terraform core and provider versions — never leave this
# unconstrained. But also never hardcode a version number from memory:
# Terraform core and every provider release continuously, so a remembered
# "latest" version is stale by the time this module gets used.
#
# Before filling in a version constraint below:
#   - If a Terraform MCP server is connected (e.g. hashicorp/terraform-mcp-server),
#     use its provider-version lookup to get the current stable release.
#   - Otherwise check the provider's page on registry.terraform.io directly
#     rather than relying on a remembered version.
#
# Once known, pin with a pessimistic constraint (~> MAJOR.MINOR) rather
# than an exact version — allows patch releases in, blocks unreviewed
# minor/major bumps.

terraform {
  required_version = ">= <current-stable-terraform-core-version>"  # look up, don't guess

  required_providers {
    # Uncomment and pin the provider(s) this module actually uses.
    # Replace <current-major.minor> with the version found via the
    # lookup guidance above — do not fill in a version from memory.

    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> <current-major.minor>"
    # }

    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "~> <current-major.minor>"
    # }

    # google = {
    #   source  = "hashicorp/google"
    #   version = "~> <current-major.minor>"
    # }
  }
}