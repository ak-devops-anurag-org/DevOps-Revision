# main.tf
#
# Define the actual resources for this module here.
# Reference input variables as var.<name> (declared in variables.tf)
# and expose consumer-facing values via outputs.tf.
#
# Example:
#
# resource "aws_example_resource" "this" {
#   name = "${var.project}-${var.environment}-example"
#
#   tags = merge(var.tags, {
#     Name = "${var.project}-${var.environment}-example"
#   })
# }