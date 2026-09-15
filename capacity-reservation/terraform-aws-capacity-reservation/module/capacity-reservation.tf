resource "aws_ec2_capacity_reservation" "capacity_reservation" {
  count             = 2
  instance_type     = "t3.micro"
  ebs_optimized     = true
  instance_platform = "Linux/UNIX"
  availability_zone = "us-east-2a"
  instance_count    = 1
  instance_match_criteria = count.index ==0 ? "open" : "targeted"
  tenancy           = "default"
  end_date_type     = "unlimited"    ### The Capacity Reservation remains active in your account until you manually cancel it.
}
