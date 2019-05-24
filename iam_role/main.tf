# ロール・ポリシーの定義を外部から渡せるようにする
variable "name" {}
variable "policy" {}
variable "identifier" {}

# 信頼ポリシードキュメントの定義 (awsの[var.identifier]サービスにロールを関連づける)
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

# [var.name]ロールに信頼ポリシーを紐付ける
resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# [var.name]ポリシーに[var.policy]ポリシードキュメントを紐付ける
resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy
}

# [aws_iam_role]と[aws_iam_policy]を紐付ける
resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  value = aws_iam_role.default.arn
}

output "iam_role_name" {
  value = aws_iam_role.default.name
}