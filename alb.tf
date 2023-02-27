resource "aws_lb" "contest_lb" {
  name               = "contest-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.contest_lb_sg.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]

  enable_deletion_protection = false

  tags = {
    env = "contest_lb"
  }
}


resource "aws_lb_target_group" "contest_target_group" {
  name        = "contest-target-group"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.contest_vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "30"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "contest_lb_listener_http" {
  load_balancer_arn = aws_lb.contest_lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.contest_target_group.arn
  }
}
