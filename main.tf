terraform {
  backend "s3" {}
  required_providers {
    archive = {
      source  = "hashicorp/archive"
      version = "~>2.3"
    }
    aws = {
      source  = "registry.terraform.io/hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "archive" {}
provider "aws" {}
provider "aws" {
  region = "us-east-1"
  alias  = "us-east-1"
}

locals {
  image_name     = var.image_name != null ? var.image_name : basename(var.dream_project_dir)
  source_dir     = var.dream_project_dir
  source_dest    = "${local.image_name}/${var.image_tag}.zip"
  repository_url = var.is_public_image ? aws_ecrpublic_repository.public.0.repository_uri : aws_ecr_repository.private.0.repository_url
  ecr_url        = dirname(local.repository_url)
}

resource "aws_ecr_repository" "private" {
  count = var.is_public_image ? 0 : 1
  name  = local.image_name

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecrpublic_repository" "public" {
  count           = var.is_public_image ? 1 : 0
  provider        = aws.us-east-1
  repository_name = local.image_name
}

data "aws_region" "current" {}


data "archive_file" "project_source" {
  type = "zip"

  dynamic "source" {
    for_each = [
      for file in fileset(local.source_dir, "**") : file
      if startswith(file, ".dream") == false
    ]
    content {
      filename = source.value
      content  = file("${local.source_dir}/${source.value}")
    }
  }

  source {
    content = templatefile("${path.module}/buildspec.yml", {
      imageName     = local.image_name
      imageTag      = var.image_tag
      builder       = var.builder
      awsRegion     = var.is_public_image ? "us-east-1" : data.aws_region.current.name
      ecrUrl        = local.ecr_url
      ecrSubCommand = var.is_public_image ? "ecr-public" : "ecr"
    })
    filename = "buildspec.yml"
  }

  output_path = ".source.zip"
}

resource "aws_s3_object" "project_source" {
  bucket = var.source_bucket
  key    = local.source_dest
  source = data.archive_file.project_source.output_path
  etag   = data.archive_file.project_source.output_base64sha256
}

data "aws_iam_policy_document" "codebuild_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "docker_build" {
  name               = "AWSCodeBuild-docker-${local.image_name}-${var.image_tag}"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume_role.json
}

data "aws_s3_bucket" "source" {
  bucket = var.source_bucket
}
data "aws_iam_policy_document" "docker_build" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:*"]
    resources = [
      data.aws_s3_bucket.source.arn,
      "${data.aws_s3_bucket.source.arn}/*",
    ]
  }

  statement {
    effect  = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:GetAuthorizationToken",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr-public:BatchCheckLayerAvailability",
      "ecr-public:CompleteLayerUpload",
      "ecr-public:GetAuthorizationToken",
      "ecr-public:InitiateLayerUpload",
      "ecr-public:PutImage",
      "ecr-public:UploadLayerPart",
      "sts:GetServiceBearerToken"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "example" {
  role   = aws_iam_role.docker_build.name
  policy = data.aws_iam_policy_document.docker_build.json
}

resource "aws_codebuild_project" "docker_build" {
  name         = "docker-${local.image_name}-${var.image_tag}"
  description  = "Builds the ${local.image_name} docker image"
  service_role = aws_iam_role.docker_build.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:7.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type     = "S3"
    location = "${var.source_bucket}/${local.source_dest}"
  }

  logs_config {
    cloudwatch_logs {
      group_name  = "codebuild-${local.image_name}-${var.image_tag}-build"
      stream_name = "codebuild-${local.image_name}-${var.image_tag}-log-stream"
    }
  }
}

resource "terraform_data" "build" {
  triggers_replace = [
    aws_s3_object.project_source.version_id,
  ]

  provisioner "local-exec" {
    command = templatefile("${path.module}/build.tpl", {
      projectName = aws_codebuild_project.docker_build.name
    })
  }
}

output "DOCKER_IMAGE" {
  value = "${local.repository_url}:${var.image_tag}"
}
