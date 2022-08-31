# config AWS Connection
#-----------------
provider "aws"{
	region = "ap-south-1"
}

# config AWS availibility zones in current region
#-----------------

data "aws_availibility_zones" "all" {}

# creating security groups that controlls traffic
#-----------------

resource "aws_security_group" "elb" {
	name = "arjun-elb-practise"

	#allow all outbound 
	egress{
		from_port = 0
		to_port   = 0
		protocol  ="-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

	#inbound HTTP connetion

	ingress{
		from_port = var.elb_program
		to_port   = var.elb_program
		protocol  ="tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

# creating security group to connect each EC2
#-------------------------

resource "aws_security_group" "instance"{
	name = "arjun-instance"

	#inbound for HTTP from anywhere to instance
	
	ingress{
		from_port = var.server_port
		to_port   = var.server_port
		protocol  ="tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

#elb creattion with setting

resource "aws_elb" "example"
	name   = "arjun-elb-example"
	security_groups = [aws_security_group.elb.id]
	availability_zones =data.aws_availability_zones.all.names

	health_check {	
		target   = "HTTP:${var.server_port}/"
		interval = 30
		timeout  = 3
		healthy_threshold = 2
		unhealthy_threshold  = 2
	}

# this adds 

	listener {	
		lb_port   = var.elb_port
		lb_protocol = "http"
		instance_port  = var.server_port
		instance_protocol = "http"
	}
}

#creatimg  launch config that defines each EC2 instance in ASG
#---------------

resource "aws_launch_configuration" "example"{
	name = "arjun-launch-config"
	image_id="ami-0620d12a9cf777c87"
	instance_type= "t2.micro"
	security_groups=[aws_security_group.instance.id]

	user_data = <<-EOF
		    #!/bin/bash
		    echo '<html><body><h1 style="front-size:50px;color:red;">ARJUN IS STILL LEARNING TERRAFORM <br> <font>
		    nohup busybox httpd -f -p "${var.server_port}"&
	            EOF

	lifyclycle{
		create_before_destroy = true
	}
}

#autoscaling group

resource "aws_autoscaling_group" "example"{
	name= "arjun-asg"
	launch_configuration = aws_launch_configuration.example.id
	availavility_zones= data.aws_availability_zones.all.names
	
	min_size = 2
	max_size = 10

	load_balancers  = [aws_elb.example.name]
	health_check_type ="ELB"

	tag {
		key    = "Name"
		value = "ARJUN-ASG-PROJECT"
		propagate_at_launch = "true"
	}
}
