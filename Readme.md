## はじめに

terraformを使用したAWS環境の構築。  
ECSを使用したコンテナオーケストレーションを用いてアプリケーションをAWS環境にデプロイします。  
terraformtとは、、についてはここでは割愛します。

## １. インストール

### テラフォームのインストール
```
$ brew install terraform

$ terraform --version
    Terraform v0.11.13
```

### tfenv(テラフォームのバージョンマネージャー)のインストール
```
$ brew install tfenv

$ tfenv --version
    tfenv 0.6.0
```

### tfenvへのテラフォームインストール。  
「.terraform-version」にバージョンを記述すると、そのバージョンを自動的にインストールできます。
```
$ echo 0.12.0-beta1 > .terraform-version

$ tfenv install
```

### クレデンシャルの付与。
AWSCLIを使用しても構いません。  
「AdministratorAccess」ポリシーをアタッチした IAM ユーザのアクセスキーを前提とします。

```
$ export AWS_ACCESS_KEY_ID=xxxxxxxxxxxxxxxxx
$ export AWS_SECRET_ACCESS_KEY=yyyyyyyyyyyyyyyyyy
$ export AWS_DEFAULT_REGION=ap-northeast-1
```

## ２. terraformの基礎

### リソースの作成
適当なディレクトリに「main.tf」を作成しましょう。

```
$ mkdir example
$ cd example
$ touch main.tf
```

### awsに反映

最初にバケット名だけ世界で一意の名前にしてください。  

「S3.tf」を編集します。「bucket =」の箇所を全て書き換えてください。

```
bucket = 「一意の名前」

```

「terraform init」で初期化
```
$ terraform init
Initializing the backend...
```

「terraform plan」で実行計画の確認。  
破壊的な変更・その他予期しない動作がないかよく確認しましょう。
```
$ terraform plan

    An execution plan has been generated and is shown below.
    Resource actions are indicated with the following symbols:
      + create

    Terraform will perform the following actions:
    
    # aws_instance.example will be created
    + resource "aws_instance" "example" {
      + ami
      + id
      + instance_type
      ......
    }
```

「terraform apply」で変更を実際のAWS環境に適用しましょう。
```
 $ terraform apply
    ......
    Do you want to perform these actions?
      Terraform will perform the actions described above.
      Only 'yes' will be accepted to approve.
      Enter a value:
```

もし、以下のエラーが出たら、既存のAWS環境のDefaultVPCに任意のサブネットを作成してあげましょう。
```
Error: Error launching source instance: MissingInput: No subnets found for the default VPC 'vpc-312c7656'. Please specify a subnet.
```

反映が完了したか、実際にAWSの管理画面から確認してみましょう.  
コードを変更後も「terraform plan」「terraform apply」で変更を適用できます。

### 変数・出力値

「variable」を使うと変数が定義できます。  
「output」を使うと出力値が定義でき、apply時にターミナルで値を確認できます。
```
provider "aws" {
  region = "ap-northeast-1"
}

#「local」にすると上書きできなくなる。
variable "example_instance_type" {
  default = "t3.micro"
}

resource "aws_instance" "example" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = var.example_instance_type
}

output "example_instance_id" {
  value = aws_instance.example.id
}
```

「variable」で定義した変数は「-var」オプションで上書きできます。
「variable」の箇所を「local」にすると、上書きできなくなります。

```
$ terraform plan -var 'example_instance_type=t3.nano'
```

「terraform apply」するとoutputの値が確認できるかと思います。
```
$ terraform apply
    ......
    Outputs:
    example_instance_id = i-02bd77505ab68856f
```

### 条件分岐

Terraform では、三項演算子が使えます。

```
variable "env" {}

resource "aws_instance" "example" {
  ami           = "ami-0f9ae750e8274075b"
  instance_type = var.env == "prod" ? "m5.large" : "t3.micro"
}
```

env変数をTerraform実行時に切り替えるとplanの結果が変わります。
```
$ terraform plan -var 'env=prod'
$ terraform plan -var 'env=dev'
```

### モジュール化

適当にディレクトリを切ってその配下に「main.tf」作成します。  
iam_roleディレクトリのmain.tfとかみてみましょう。  

そんでもってルートディレクトリのmain.tfの以下の記述でモジュールの呼び出しをしています。  
```
# モジュール[iam_role]呼出
module "describe_regions_for_ec2" {
  source     = "./iam_role"
  name       = "describe-regions-for-ec2"
  identifier = "ec2.amazonaws.com"
  policy     = data.aws_iam_policy_document.allow_describe_regions.json
}
```

### リソースの削除

ここまでで作成したリソースを削除しましょう。  

```
$ terraform destroy
    ......
      # aws_instance.example will be destroyed
      - resource "aws_instance" "example" {
          - ami                          = "ami-0f9ae750e8274075b" -> null
    Plan: 0 to add, 0 to change, 1 to destroy.
```

削除後実際にAWSの管理画面から確認してみましょう.
