# outputs.tf
#
# Only output what downstream consumers actually need — don't dump
# entire resource objects.
#
# Example:
#
# output "id" {
#   description = "ID of the created resource."
#   value       = aws_example_resource.this.id
# }