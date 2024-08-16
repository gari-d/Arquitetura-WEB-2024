provider "aws" {
  region = "us-west-2"  # Defina a região da AWS que você deseja usar
}

# Route 53 DNS
resource "aws_route53_zone" "dns" {
  name = "example.com"
}

# Load Balancer (ALB)
resource "aws_lb" "load_balancer" {
  name               = "game-store-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = aws_subnet.main[*].id
}

# ECS Cluster
resource "aws_ecs_cluster" "web_cluster" {
  name = "game-store-web-cluster"
}

# ECS Web Servers
resource "aws_ecs_service" "web_service" {
  name            = "web-service"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.web_task.id
  desired_count   = 2
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = aws_lb_target_group.web_target_group.arn
    container_name   = "web-container"
    container_port   = 80
  }
}

# ECS Application Servers
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.web_cluster.id
  task_definition = aws_ecs_task_definition.app_task.id
  desired_count   = 2
  launch_type     = "EC2"
  load_balancer {
    target_group_arn = aws_lb_target_group.app_target_group.arn
    container_name   = "app-container"
    container_port   = 8080
  }
}

# SQS Queue
resource "aws_sqs_queue" "order_queue" {
  name = "order-queue"
}

# Lambda Functions
resource "aws_lambda_function" "payment_processor" {
  function_name = "payment-processor"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "payment_processor.handler"
  runtime       = "python3.8"
  source_code_hash = filebase64sha256("path/to/deployment.zip")

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.order_queue.url
    }
  }
}

resource "aws_lambda_function" "inventory_check" {
  function_name = "inventory-check"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "inventory_check.handler"
  runtime       = "python3.8"
  source_code_hash = filebase64sha256("path/to/deployment.zip")
}

resource "aws_lambda_function" "order_confirmation" {
  function_name = "order-confirmation"
  role          = aws_iam_role.lambda_exec_role.arn
  handler       = "order_confirmation.handler"
  runtime       = "python3.8"
  source_code_hash = filebase64sha256("path/to/deployment.zip")
}

# RDS Database for Users
resource "aws_db_instance" "user_db" {
  identifier              = "user-db"
  allocated_storage       = 20
  engine                  = "mysql"
  instance_class          = "db.t3.micro"
  name                    = "userdb"
  username                = "admin"
  password                = "password"
  parameter_group_name    = "default.mysql8.0"
  skip_final_snapshot     = true
}

# S3 Bucket for Game Storage
resource "aws_s3_bucket" "game_storage" {
  bucket = "game-storage-bucket"
  acl    = "private"
}

# Redshift for Analytics
resource "aws_redshift_cluster" "sales_analytics" {
  cluster_identifier = "sales-analytics"
  database_name      = "analyticsdb"
  master_username    = "admin"
  master_password    = "password"
  node_type          = "dc2.large"
  cluster_type       = "single-node"
}
