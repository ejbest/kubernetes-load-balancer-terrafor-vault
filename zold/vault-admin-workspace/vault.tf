

resource "vault_aws_secret_backend" "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region =  var.aws_region
  default_lease_ttl_seconds = "120"
  max_lease_ttl_seconds     = "240"
}
resource "vault_aws_secret_backend_role" "aws" {
  backend = vault_aws_secret_backend.aws.path
  name    = "dynamic-aws-creds-vault-admin"
  credential_type = "iam_user"
  policy_document = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:*", "*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}
