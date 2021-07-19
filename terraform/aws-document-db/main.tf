provider "aws" {
    region     = "${var.AWS_REGION}"
    version    = "v2.70.0"
}

# Get VPC by sandbox id
data "aws_vpc" "sandbox_vpc" {
    filter {
        name = "tag:colony-sandbox-id"
        values = ["${var.SANDBOX_ID}"]
    }    
}

# Get app subnets by sandbox id
data "aws_subnet" "sandbox_app_subnet_0" {
    vpc_id = "${data.aws_vpc.sandbox_vpc.id}"

    filter {
        name = "tag:Name"
        values = ["app-subnet-0"]
    }
}
data "aws_subnet" "sandbox_app_subnet_1" {
    vpc_id = "${data.aws_vpc.sandbox_vpc.id}"

    filter {
        name = "tag:Name"
        values = ["app-subnet-1"]
    }
}

resource "aws_security_group" "docdb_sg" {
  name        = "docdb"
  description = "dobdb Security Group"
  vpc_id      = "${data.aws_vpc.sandbox_vpc.id}"

  ingress {
    description = "MongoDB from VPC"
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["${data.aws_vpc.sandbox_vpc.cidr_block}"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "docdb_allow_sandbox_traffic"
    colony-sandbox-id = "${var.SANDBOX_ID}"
  }
}

resource "aws_docdb_cluster_parameter_group" "no_tls" {
  family      = "docdb4.0"
  name        = "param-group-${var.SANDBOX_ID}"
  description = "colony sandbox docdb cluster parameter group without tls"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}

resource "aws_docdb_subnet_group" "default" {
  name       = "main-${var.SANDBOX_ID}"
  subnet_ids = ["${data.aws_subnet.sandbox_app_subnet_0.id}", "${data.aws_subnet.sandbox_app_subnet_1.id}"]

  tags = {
    Name = "colony document db sugnet group"
    colony-sandbox-id = "${var.SANDBOX_ID}"
  }
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
    count              = 1
    identifier         = "colony-sandbox-docdb-${var.SANDBOX_ID}"
    cluster_identifier = "${aws_docdb_cluster.default.id}"
    instance_class     = "db.r5.large"
    tags = {
        colony-sandbox-id = "${var.SANDBOX_ID}"
    }
}

resource "aws_docdb_cluster" "default" {
    cluster_identifier    = "colony-sandbox-docdb-cluster-${var.SANDBOX_ID}"
    master_username       = "${var.USERNAME}"
    master_password       = "${var.PASSWORD}"
    db_subnet_group_name  = "${aws_docdb_subnet_group.default.id}"
    skip_final_snapshot = true
    vpc_security_group_ids = ["${aws_security_group.docdb_sg.id}"]
    db_cluster_parameter_group_name = "${aws_docdb_cluster_parameter_group.no_tls.id}"
    tags = {
        colony-sandbox-id   = "${var.SANDBOX_ID}"
    }
}

resource "null_resource" "insert_data" {
    count = "${var.INSERT_DATA ? 1 : 0}"

    provisioner "local-exec" {
        command = "chmod 777 insert_data.sh && ./insert_data.sh ${aws_docdb_cluster.default.endpoint} ${var.USERNAME} ${var.PASSWORD} ${var.DB_NAME} ${var.COLLECTION_NAME} \"${var.DATA}\" ${aws_docdb_cluster_instance.cluster_instances.arn}"
        interpreter = ["/bin/bash", "-c"]
    }
}

output "connection_string" {
    value = "mongodb://${var.USERNAME}:${var.PASSWORD}@${aws_docdb_cluster.default.endpoint}:27017"
}
