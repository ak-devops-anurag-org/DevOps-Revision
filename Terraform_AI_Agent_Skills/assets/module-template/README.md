# \<module-name\>

One-paragraph description of what this module creates and why.

## Usage

```hcl
module "example" {
  source = "../../modules/<module-name>"

  project     = var.project
  environment = var.environment
  tags        = local.common_tags

  # module-specific inputs...
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project | Project/system name | string | n/a | yes |
| environment | Deployment environment | string | n/a | yes |
| tags | Common tags/labels | map(string) | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| \<output_name\> | \<description\> |