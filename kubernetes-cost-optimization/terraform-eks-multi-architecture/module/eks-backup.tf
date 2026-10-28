# ==========================================
# 1. AWS BACKUP VAULT (Encrypted Storage)
# ==========================================
resource "aws_backup_vault" "eks_vault" {
  name        = "${var.prefix}-eks-native-backup-vault"
  kms_key_arn = var.backup_kms_key_arn                ### Provide your existing KMS Key ARN here
}

# ==========================================
# 2. AWS BACKUP PLAN (Daily Schedule)
# ==========================================
resource "aws_backup_plan" "eks_plan" {
  name = "daily-eks-backup-plan"

  rule {
    rule_name         = "${var.prefix}-daily-eks-retention-rule"
    target_vault_name = aws_backup_vault.eks_vault.name
    schedule          = "cron(30 5,17 * * ? *)"    ### Runs daily at 11:00 AM and 11:00 PM IST

    lifecycle {
      delete_after = 30                        ### Retain backups for 30 days
    }
  }
}

# ==========================================
# 3. IAM ROLE & POLICIES FOR AWS BACKUP
# ==========================================
resource "aws_iam_role" "backup_role" {
  name = "${var.prefix}-backup-eks-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { 
          Service = "backup.amazonaws.com" 
        }
      }
    ]
  })
}

# General backup operations policy
resource "aws_iam_role_policy_attachment" "backup_core" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

# Restore operations policy (Restore EKS to an operational state)
resource "aws_iam_role_policy_attachment" "backup_restores" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup_role.name
}

# ==========================================
# 4. RESOURCE SELECTION (Targeting EKS)
# ==========================================
resource "aws_backup_selection" "eks_selection" {
  name         = "${var.prefix}-eks-cluster-backup-assignment"
  plan_id      = aws_backup_plan.eks_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  resources = [aws_eks_cluster.eksdemo.arn]  ### Explicitly targeting the EKS Cluster ARN initiates the native agentless backup
}

resource "aws_backup_region_settings" "eks" {
  resource_type_opt_in_preference = {
    EKS = true
  }
}
