# Generate a secure random password for MySQL root
resource "random_password" "mysql_root_password" {
  length  = 20
  special = false ### Adjust based on MySQL special character constraints if needed
}

# Create AWS Secrets Manager Secret
resource "aws_secretsmanager_secret" "mysql_credentials" {
  name_prefix = "${var.prefix}-mysql-root-credentials"
  description = "Root credentials for MySQL deployed via ArgoCD"
}

# Store the password and database name inside the Secret
resource "aws_secretsmanager_secret_version" "mysql_credentials_val" {
  secret_id = aws_secretsmanager_secret.mysql_credentials.id
  secret_string = jsonencode({
    mysql-root-password = random_password.mysql_root_password.result
    mysql-database      = "dexter-db"
  })
}

# Generate the Web Identity Trust Policy for the External Secrets Operator Service Account
data "aws_iam_policy_document" "ekseso_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:external-secrets:external-secrets"]
    }
  }
}

# Create the IAM Role for ESO using the generated trust policy (Fixed reference name below)
resource "aws_iam_role" "eso_secrets_role" {
  name               = "eso-secrets-manager-role"
  assume_role_policy = data.aws_iam_policy_document.ekseso_assume_role_policy.json
}

# Attach AWS managed policy to read Secrets Manager
resource "aws_iam_role_policy_attachment" "eso_secrets_attach" {
  role       = aws_iam_role.eso_secrets_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}
