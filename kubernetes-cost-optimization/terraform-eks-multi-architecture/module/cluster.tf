#-----------------------
# EKS CLuster Definition
#-----------------------

resource "aws_eks_cluster" "eksdemo" {
  name     = "${var.eks_cluster}-${var.env}"
  role_arn = aws_iam_role.eksdemorole.arn
  version = var.kubernetes_version[13] 

  vpc_config {
    subnet_ids = aws_subnet.private_subnet.*.id       ### concat("${aws_subnet.public_subnet.*.id}", "${aws_subnet.private_subnet.*.id}")
#    subnet_ids = ["subnet-05dd16bc3a73a55ad", "subnet-0ff097df94318f90d", "subnet-06fb9c70358c599e2", "subnet-0a8f252083967e8ba", "subnet-075a21d1c5d03c63d", "subnet-0c6da32ab01e5a2f2" ]                ##### Private and Public Subnet List for Private EKS    
    endpoint_public_access  = false
    endpoint_private_access = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = false
  }


#  encryption_config {
#    provider {
#      key_arn = var.kms_key_id
#    }
#    resources = ["secrets"]
#  }

  tags = {
    Environment = var.env     ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  } 

  depends_on = [
    aws_iam_role_policy_attachment.eksdemorole-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.eksdemorole-AmazonEKSVPCResourceController,
    aws_route_table_association.public_route_table_association,
    aws_route_table_association.private_route_table_association_1,
    aws_route_table_association.private_route_table_association_2,
    aws_route_table_association.private_route_table_association_3,
    aws_nat_gateway.nat_gateway, 
    aws_internet_gateway.testIGW, 
  ]
}


#-------------------------
# IAM Role for EKS Cluster
#-------------------------

resource "aws_iam_policy" "iam_policy_for_eks_logs_to_cloudwatch" {
  name        = "eks-logs-to-cloudwatch"
  description = "IAM Policy for Sending EKS Logs to CloudWatch Log Group"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${data.aws_caller_identity.G_Duty.account_id}:log-group:/aws/eks/${var.eks_cluster}-${var.env}/cluster:log-stream:*"
      },
    ]
  })
}

resource "aws_iam_role" "eksdemorole" {
  name = "${var.eks_iam_role_name}-${var.env}"

  assume_role_policy = file("trust-relationship.json")
  
  tags = {
    Environment = var.env     ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_iam_role_policy_attachment" "eksdemorole-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eksdemorole.name
}

resource "aws_iam_role_policy_attachment" "eksdemorole-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eksdemorole.name
}

resource "aws_iam_role_policy_attachment" "eks-logs-to-cloudwatch" {
  policy_arn = aws_iam_policy.iam_policy_for_eks_logs_to_cloudwatch.arn
  role       = aws_iam_role.eksdemorole.name
}

#--------------------------------------
# Enabling IAM Role for Service Account
#--------------------------------------

data "tls_certificate" "ekstls" {
  url = aws_eks_cluster.eksdemo.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eksopidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.ekstls.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eksdemo.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eksdoc_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}

#------------------------------------------
#Create Launch Template for EKS Worker Node
#------------------------------------------

resource "aws_launch_template" "eks_launch_template" {
  count                  = 2 
#  image_id              = var.eks_ami_id[1]          ## You can use https://github.com/awslabs/amazon-eks-ami/releases 
  instance_type          = count.index == 0 ? var.instance_type[5] : var.instance_type[8] 
  name                   = count.index == 0 ? "${var.launch_template_name}-${var.env}-spot" : "${var.launch_template_name}-${var.env}-graviton"
#  update_default_version = true

  key_name = "eks-test"

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.disk_size
      encrypted = true
      kms_key_id = var.kms_key_id     ### Provide the kms_key_id for your AWS Account.
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Environment = var.env        ##"Dev"
      Owner       = "Ops"
      Billing     = "MyProject"
      "kubernetes.io/cluster/${var.eks_cluster}-${var.env}" = "owned"
    }
  }
  
  tag_specifications {
     resource_type = "volume"
     tags = {
       Environment = var.env       ##"Dev"
       Owner       = "Ops"
       Billing     = "MyProject"
       "kubernetes.io/cluster/${var.eks_cluster}-${var.env}" = "owned"
    }
  } 

#  user_data = filebase64("user_data.sh")

#  user_data = base64encode(templatefile("userdata.tpl", { CLUSTER_NAME = aws_eks_cluster.cluster.name, B64_CLUSTER_CA = aws_eks_cluster.cluster.certificate_authority[0].data, API_SERVER_URL = aws_eks_cluster.cluster.endpoint }))
  
  depends_on = [ aws_eks_cluster.eksdemo ]

}


#-------------------------
# Creating the Worker Node
#-------------------------

resource "aws_eks_node_group" "eksnode" {
  count           = 2
  cluster_name    = "${var.eks_cluster}-${var.env}"
  node_group_name = count.index == 0 ? "${var.node_group_name}-${var.env}-AMD-spot-instances" : "${var.node_group_name}-${var.env}-Graviton-on-demand"
  node_role_arn   = aws_iam_role.eksnoderole.arn
  subnet_ids      = aws_subnet.private_subnet.*.id   ###[element(aws_subnet.private_subnet[*].id,count.index)]    #var.subnet_ids
  
#  subnet_ids = ["subnet-05dd16bc3a73a55ad", "subnet-0ff097df94318f90d", "subnet-06fb9c70358c599e2"]    #### Private Subnet List for Private EKS NodeGroup  
  
#  instance_types  = [ var.instance_types[1] ]
#  disk_size       = var.disk_size
  ami_type        = count.index == 0 ? var.ami_type[0] : var.ami_type[2]
  capacity_type   = count.index == 0 ? var.capacity_type[1] : var.capacity_type[0]
  release_version = var.release_version[13] 

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
  
  launch_template {
    id      = aws_launch_template.eks_launch_template[count.index].id
    version = "$Latest"                  ##aws_launch_template.eks_launch_template.version
#    name    = var.launch_template_name
  } 

  scaling_config {
    desired_size = 2
    max_size     = 2
    min_size     = 2
  }

  update_config {
    max_unavailable_percentage = 50       ### Maximum percentage of unavailable worker nodes while performing node group update.
  }

  depends_on = [
    aws_launch_template.eks_launch_template,
    aws_iam_role.eksnoderole,
    aws_eks_cluster.eksdemo,
    aws_iam_role_policy_attachment.eksnode-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.eksnode-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.eksnode-AmazonEC2ContainerRegistryReadOnly,
  ]
}

#----------------------------
# IAM Role for EKS Node Group
#----------------------------

resource "aws_iam_role_policy" "eksnode_policy" {
  name = "eksnode-policy-${var.env}"
  role = aws_iam_role.eksnoderole.id

  policy = file("autoscalepolicy.json")

}

resource "aws_iam_role" "eksnoderole" {
  name = "${var.eks_nodegrouprole_name}-${var.env}"

  assume_role_policy = file("trust-relationship-nodegroup.json")              ## This is the trust relationship for IAM Role.

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_iam_role_policy_attachment" "eksnode-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eksnoderole.name
}

resource "aws_iam_role_policy_attachment" "eksnode-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eksnoderole.name
}

resource "aws_iam_role_policy_attachment" "eksnode-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eksnoderole.name
}

#----------------------------------------------------
# create EKS Node Health Monitoring Agent Add ons
#----------------------------------------------------

resource "aws_eks_addon" "node_monitoring_agent" {
  cluster_name                = aws_eks_cluster.eksdemo.name
  addon_name                  = "eks-node-monitoring-agent"
  addon_version               = var.node_monitoring_version     ### Replace with the exact version matching your 1.36 cluster build
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

#---------------------------------------
# create EKS EBS CSI Driver Add ons
#---------------------------------------

data "aws_iam_policy_document" "csi" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_ebs_csi_driver" {
  assume_role_policy = data.aws_iam_policy_document.csi.json
  name               = "eks-ebs-csi-driver-${var.env}"
  
  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }

}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver" {
  role       = aws_iam_role.eks_ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_iam_policy" "eks_ebs_csi_driver_kms" {
  name        = "KMS_Key_For_Encryption_On_EBS_Policy-${var.env}"
  description = "Policy to encrypt ebs volume created using ebs csi driver"
  policy = file("kms-key-for-encryption-on-ebs.json")   

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_iam_role_policy_attachment" "amazon_ebs_csi_driver_kms" {
   role       = aws_iam_role.eks_ebs_csi_driver.name
   policy_arn = aws_iam_policy.eks_ebs_csi_driver_kms.arn
}

resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name      = aws_eks_cluster.eksdemo.id
  addon_name        = var.ebs_csi_name
  addon_version     = var.ebs_csi_version
  service_account_role_arn = aws_iam_role.eks_ebs_csi_driver.arn
  resolve_conflicts_on_create = "NONE"
  resolve_conflicts_on_update = "OVERWRITE"     # use resolve_conflicts_on_update for updating a kubernetes cluster  #resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.eksdemo,
    aws_eks_node_group.eksnode
  ]
  
  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_eks_addon" "csi_snapshot_controller" {
  cluster_name      = aws_eks_cluster.eksdemo.id
  addon_name        = "snapshot-controller"
  addon_version     = var.csi_snapshot_controller_version
  resolve_conflicts_on_create = "NONE"
  resolve_conflicts_on_update = "OVERWRITE"     # use resolve_conflicts_on_update for updating a kubernetes cluster  #resolve_conflicts = "OVERWRITE"

  depends_on = [
    aws_eks_cluster.eksdemo,
    aws_eks_node_group.eksnode
  ]

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_eks_addon" "core_dns" {
  cluster_name                = aws_eks_cluster.eksdemo.name
  addon_name                  = "coredns"
  addon_version               = var.addon_version_coredns      ###  "v1.10.1-eksbuild.4"
  resolve_conflicts_on_create = "NONE"
  resolve_conflicts_on_update = "OVERWRITE"    # use resolve_conflicts_on_update for updating a kubernetes cluster 

  ### configuration_values =   ### Configuration value can be provided as per the requirement if needed.

  depends_on = [
    aws_eks_cluster.eksdemo,
    aws_eks_node_group.eksnode
  ]

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

#---------------------------------------
# create EKS VPC CNI Add ons
#---------------------------------------

data "aws_iam_policy_document" "vpc_cni" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "vpc_cni_role" {
  assume_role_policy = data.aws_iam_policy_document.vpc_cni.json
  name               = "vpc-cni-role-${var.env}"
}

resource "aws_iam_role_policy_attachment" "vpc_cni_policy_attach" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.vpc_cni_role.name
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.eksdemo.name
  addon_name                  = "vpc-cni"
  addon_version               = var.addon_version_vpc_cni    ### "v1.15.1-eksbuild.1"                ### "v1.16.2-eksbuild.1"
  service_account_role_arn    = aws_iam_role.vpc_cni_role.arn
  resolve_conflicts_on_create = "NONE"
  resolve_conflicts_on_update = "OVERWRITE"      # use resolve_conflicts_on_update for updating a kubernetes cluster
  
  depends_on = [
    aws_eks_cluster.eksdemo,
#    aws_eks_node_group.eksnode
  ]

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.eksdemo.name
  addon_name                  = "kube-proxy"
  addon_version               = var.addon_version_kubeproxy   ### "v1.27.6-eksbuild.2"         ### "v1.28.6-eksbuild.2"  
  resolve_conflicts_on_create = "NONE"
  resolve_conflicts_on_update = "OVERWRITE"      # use resolve_conflicts_on_update for updating a kubernetes cluster

  depends_on = [
    aws_eks_cluster.eksdemo,
#    aws_eks_node_group.eksnode
  ]

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }

}

########################################## EKS VPC Endpoint and Guard Duty ###############################################

data "aws_vpc_endpoint_service" "guardduty" {
  service_type = "Interface"
  filter {
    name   = "service-name"
    values = ["${data.aws_partition.amazonwebservices.reverse_dns_prefix}.${data.aws_region.reg.region}.guardduty-data"]
  }
}

data "aws_iam_policy_document" "eks_vpc_guardduty" {
  statement {
    actions = ["*"]

    effect = "Allow"

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }

  statement {
    actions = ["*"]

    effect = "Deny"

    resources = ["*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"

      values = [data.aws_caller_identity.G_Duty.account_id]
    }
  }
}

resource "aws_vpc_endpoint" "eks_vpc_guardduty" {
  vpc_id            = aws_vpc.test_vpc.id
  service_name      = data.aws_vpc_endpoint_service.guardduty.service_name
  vpc_endpoint_type = "Interface"

  policy = data.aws_iam_policy_document.eks_vpc_guardduty.json

  security_group_ids  = [aws_security_group.eks_vpc_endpoint_guardduty.id]
  subnet_ids          = aws_subnet.public_subnet[*].id         # VPC endpoint should be run in the public subnet.
  private_dns_enabled = true      # Private DNS names should be enabled as the agent is looking for guardduty-data.eu-west-2.amazonaws.com endpoint

  tags = {
    Name = "GuarDduty-data-${var.env}"
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }

  depends_on = [
    aws_eks_cluster.eksdemo,
  ]

}

resource "aws_security_group" "eks_vpc_endpoint_guardduty" {
  name_prefix = "vpc-endpoint-guardduty-sg-${var.env}"
  description = "Security Group used by VPC Endpoints."
  vpc_id      = aws_vpc.test_vpc.id

  tags = {
    Name = "vpc-endpoint-guardduty-sg-${var.env}"
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }

  depends_on = [
    aws_eks_cluster.eksdemo,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_vpc_guardduty" {
  security_group_id = aws_security_group.eks_vpc_endpoint_guardduty.id
  description       = "Ingress for port 443."

  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  ip_protocol = "tcp"
  to_port     = 443
}

resource "aws_eks_addon" "guard_duty" {
  cluster_name      = aws_eks_cluster.eksdemo.name
  addon_name        = "aws-guardduty-agent"
  addon_version     = var.addon_version_guardduty       ### "v1.4.1-eksbuild.2"
  resolve_conflicts_on_create = "NONE"
  resolve_conflicts_on_update = "OVERWRITE"      # use resolve_conflicts_on_update for updating a kubernetes cluster

  depends_on = [
    aws_eks_cluster.eksdemo,
#    aws_eks_node_group.eksnode
  ]

  tags = {
    Environment = var.env        ##"Dev"
    Owner       = "Ops"
    Billing     = "MyProject"
  }

}

##################################Pod Identity Agent Add-Ons###########################################

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.eksdemo.name
  addon_name   = "eks-pod-identity-agent"
  addon_version      = var.addon_version_podidentityagent  # Replace with desired version
}

##################################Container Insight Add-Ons ###########################################

resource "aws_iam_role" "cloudwatch_observability_role" {
  name                = "amazon-cloudwatch-observability-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    "Statement": [
        {
            "Sid": "AllowEksAuthToAssumeRoleForPodIdentity",
            "Effect": "Allow",
            "Principal": {
                "Service": "pods.eks.amazonaws.com"
            },
            "Action": [
                "sts:AssumeRole",
                "sts:TagSession"
            ]
        }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent_policy_attachment" {
  role       = aws_iam_role.cloudwatch_observability_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

#resource "aws_iam_role_policy_attachment" "xray_policy_attachment" {
#  role       = aws_iam_role.cloudwatch_observability_role.name
#  policy_arn = "arn:aws:iam::aws:policy/AWSXRayWriteOnlyAccess"
#}

resource "aws_eks_addon" "amazon_cloudwatch_observability" {
  cluster_name  = aws_eks_cluster.eksdemo.name
  addon_name    = "amazon-cloudwatch-observability"
  addon_version = var.addon_version_observability       ###"v1.7.0-eksbuild.1"
  configuration_values = file("amazon-cloudwatch-observability.json")
  pod_identity_association {
    role_arn = aws_iam_role.cloudwatch_observability_role.arn
    service_account = "cloudwatch-agent"
  }
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_cluster.eksdemo, aws_eks_node_group.eksnode]
}

################################### Metrics Server Add-Ons ############################################

resource "aws_eks_addon" "metrics_server" {
  cluster_name  = aws_eks_cluster.eksdemo.name
  addon_name    = "metrics-server"
  addon_version = var.addon_version_metrics_server  # Replace with desired version
  depends_on = [aws_eks_cluster.eksdemo, aws_eks_node_group.eksnode]
}

##################################### Create Kubeconfig file ##########################################

resource "null_resource" "kubectl" {
    provisioner "local-exec" {
        command = "aws eks --region ${data.aws_region.reg.region} update-kubeconfig --name ${aws_eks_cluster.eksdemo.name} && chmod 600 ~/.kube/config"
    }

    depends_on = [aws_eks_cluster.eksdemo, aws_eks_node_group.eksnode]
}

######################## Allow Jump box (K8S Management) to access EKS Cluster #########################

resource "aws_security_group_rule" "allow_jumpbox_to_eks_api" {
  type                     = "ingress"
  from_port                = 443  # EKS API endpoint uses HTTPS
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.k8s_management.id 
  security_group_id        = aws_eks_cluster.eksdemo.vpc_config[0].cluster_security_group_id
  description              = "Allow jump box (K8S Managemnt) to access EKS private endpoint"
}

################################## Tag the EKS Cluster Security Group #################################

resource "aws_ec2_tag" "cluster_security_group" {
  resource_id = aws_eks_cluster.eksdemo.vpc_config[0].cluster_security_group_id
  key         = "karpenter.sh/discovery" 
  value       = "${var.eks_cluster}-${var.env}"
  
  depends_on = [aws_eks_node_group.eksnode]
}

################################### Karpenter Controller ##############################################

data "aws_iam_policy_document" "karpenter_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eksopidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eksopidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "karpenter_controller_role" {
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role_policy.json
  name               = "karpenter-controller-role"
}

resource "aws_iam_role_policy_attachment" "karpenter_controller_policy_attach" {
  role       = aws_iam_role.karpenter_controller_role.name
  policy_arn = aws_iam_policy.karpenter_controller_policy.arn
}


resource "aws_iam_policy" "karpenter_controller_policy" {
  name = "karpenter-controller-policy"
  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "VisualEditor0",
          "Effect" : "Allow",
          "Action" : "ec2:TerminateInstances",
          "Resource" : "arn:aws:ec2:${data.aws_region.reg.region}:${data.aws_caller_identity.G_Duty.account_id}:instance/*",
          "Condition" : {
            "ForAnyValue:StringLike" : {
              "ec2:ResourceTag/karpenter.sh/nodepool": "*"
            }
          }
        },
        {
          "Sid" : "VisualEditor1",
          "Effect" : "Allow",
          "Action" : [
            "eks:DescribeCluster",
            "ec2:DescribeSpotPriceHistory",
            "ec2:DescribeImages",
            "ec2:DescribeInstances",
            "ec2:DescribeInstanceTypeOfferings",
            "ec2:DescribeAvailabilityZones",
            "ec2:DescribeLaunchTemplates",
            "ec2:DescribeInstanceTypes",
            "ec2:RunInstances",
            "ec2:CreateFleet",
            "ec2:DescribeSubnets",
            "ec2:DescribeSecurityGroups",
            "ec2:CreateTags",
            "pricing:GetProducts",
            "iam:GetInstanceProfile",
            "iam:PassRole"
          ],
          "Resource" : "*"
        },
        {
          "Sid" : "VisualEditor2",
          "Effect" : "Allow",
          "Action" : [
            "ec2:DeleteLaunchTemplate",
            "ec2:CreateLaunchTemplate",
            "ec2:CreateTags"
          ],
          "Resource" : "arn:aws:ec2:${data.aws_region.reg.region}:${data.aws_caller_identity.G_Duty.account_id}:launch-template/*"
        },
        {
          "Sid" : "VisualEditor3",
          "Effect" : "Allow",
          "Action" : [
            "iam:PassRole",
            "ssm:GetParameter"
          ],
          "Resource" : [
            "arn:aws:iam::${data.aws_caller_identity.G_Duty.account_id}:role/karpenter-node*",
            "arn:aws:ssm:${data.aws_region.reg.region}:*:parameter/*"
          ]
        },
        {
          "Sid" : "karpenterInstanceProfile",
          "Effect" : "Allow",
          "Action" : [
            "iam:CreateInstanceProfile",
            "iam:TagInstanceProfile",
            "iam:AddRoleToInstanceProfile",
            "iam:RemoveRoleFromInstanceProfile",
            "iam:DeleteInstanceProfile",
            "iam:GetInstanceProfile",
            "iam:ListInstanceProfiles"
          ],
          "Resource" : [
            "arn:aws:iam::${data.aws_caller_identity.G_Duty.account_id}:instance-profile/*"
          ]
        }
      ]
} 
  )

}

############################################# Nodes Spun-up using Karpenter ########################################### 

# IAM Role which allows Karpenter to spin up nodes
data "aws_iam_policy_document" "karpenter_node_iam_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      identifiers = ["ec2.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_iam_role" "karpenter_node_iam_role" {
  assume_role_policy = data.aws_iam_policy_document.karpenter_node_iam_role_policy.json
  name               = "karpenter-eks-noderole"
}

resource "aws_iam_role_policy_attachment" "karpenter_workernode" {
  role       = aws_iam_role.karpenter_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "karpenter_cni" {
  role       = aws_iam_role.karpenter_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "karpenter_ecr" {
  role       = aws_iam_role.karpenter_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "karpenter_ssm" {
  role       = aws_iam_role.karpenter_node_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "karpenter_instance_profile" {
  name = "karpenter-eks-instance-profile"
  role = aws_iam_role.karpenter_node_iam_role.name
}

#################################################### Grant EKS Console Access ################################################

resource "aws_eks_access_entry" "console_access" {
  cluster_name = aws_eks_cluster.eksdemo.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.G_Duty.account_id}:root"
  type = "STANDARD"
}


resource "aws_eks_access_policy_association" "console_access" {
  cluster_name = aws_eks_cluster.eksdemo.name
  principal_arn = aws_eks_access_entry.console_access.principal_arn
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  access_scope {
    type = "cluster"
  }
}

resource "aws_eks_access_entry" "admin" {
  cluster_name  = aws_eks_cluster.eksdemo.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.G_Duty.account_id}:role/Administrator_Access"
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "admin" {
  cluster_name  = aws_eks_cluster.eksdemo.name
  principal_arn = aws_eks_access_entry.admin.principal_arn

  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}
