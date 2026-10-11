resource "aws_launch_template" "example" {
  name_prefix            = "terraform-asg-example-"
  image_id               = "ami-0d27e0fb3bac4d724"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail
    if ! command -v python3 >/dev/null; then
      dnf install -y python3
    fi

    mkdir -p /var/www/html
    echo "Hello World" > /var/www/html/index.html
    nohup python3 -m http.server ${var.server_port} \
      --bind 0.0.0.0 --directory /var/www/html \
      >/var/log/python-http-server.log 2>&1 &
    EOF
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "example" {
  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns   = [aws_lb_target_group.asg.arn]
  health_check_type   = "ELB"
  min_size            = 2
  max_size            = 10

  tag {
    key                 = "Name"
    value               = "terraform-asg-example"
    propagate_at_launch = true
  }
}
