resource "aws_iam_role" "ecs_instance_role" {
  name_prefix = "ecs-instance-role-web"
  path        = "/"

  assume_role_policy = <<EOF
{
"Version": "2008-10-17",
"Statement": [
{
"Action": "sts:AssumeRole",
"Principal": {
"Service": ["ec2.amazonaws.com"]
},
"Effect": "Allow"
}
]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_attachment" {
  role       = aws_iam_role.ecs_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_service_role" {
  role = aws_iam_role.ecs_instance_role.name
}



resource "aws_iam_user" "smtp_user" {
  name = "${terraform.workspace}-smtp_user"
}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.smtp_user.name
}

data "aws_iam_policy_document" "sqs_sender" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }
  statement {
    actions = ["s3:PutObject",
      "s3:GetObject",
      "s3:AbortMultipartUpload",
      "s3:ListBucket",
      "s3:DeleteObject",
      "s3:GetObjectVersion",
    "s3:ListMultipartUploadParts"]
    resources = ["*"]
  }

  statement {
    actions   = ["sqs:*"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqs_sender" {
  name_prefix = "sqs"
  description = "Allows use SQS"
  policy      = data.aws_iam_policy_document.sqs_sender.json
}


resource "aws_iam_user_policy_attachment" "test-attach2" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.sqs_sender.arn
}
