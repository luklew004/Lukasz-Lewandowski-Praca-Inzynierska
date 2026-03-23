provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "ssh_access" {
  name        = "allow-ssh"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-access"
  }
}

resource "aws_security_group" "icmp_traffic" {
  name        = "allow-icmp"
  description = "Allow SSH"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ICMP-traffic"
  }
}

resource "aws_subnet" "subnets" {
  count                   = 3
  vpc_id                  = data.aws_vpc.default.id
  cidr_block              = "172.31.${count.index + 1}.0/24"
  availability_zone       = "eu-north-1b"
  map_public_ip_on_launch = true
}

resource "aws_instance" "servers" {
  count         = 2
  ami           = "ami-0fa91bc90632c73c9"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.lukaszinz-ssh.id

  subnet_id              = aws_subnet.subnets[0].id
  vpc_security_group_ids = [aws_security_group.ssh_access.id, aws_security_group.icmp_traffic.id]

  tags = {
    Name = "server-${count.index}"
  }

  depends_on = [aws_security_group.ssh_access, aws_security_group.icmp_traffic]
}

resource "aws_key_pair" "lukaszinz-ssh" {
  key_name   = "lukaszinz_klucz"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "aws_network_interface" "extra_eni" {
  count           = 2
  subnet_id       = aws_subnet.subnets[count.index == 0 ? 1 : 2].id
  private_ips     = ["172.31.${count.index == 0 ? 2 : 3}.50"]
  security_groups = [aws_security_group.ssh_access.id, aws_security_group.icmp_traffic.id]
  source_dest_check = false

  tags = {
    Name = "extra-eni-${count.index}"
  }
 
  depends_on = [aws_security_group.ssh_access, aws_security_group.icmp_traffic]
}

resource "aws_instance" "pcs" {
  count         = 2
  ami           = "ami-0fa91bc90632c73c9"
  instance_type = "t3.micro"
  key_name      = aws_key_pair.lukaszinz-ssh.id

  subnet_id = aws_subnet.subnets[count.index + 1].id
  vpc_security_group_ids = [aws_security_group.ssh_access.id, aws_security_group.icmp_traffic.id]

  tags = {
    Name = "pc-${count.index}"
  }

  depends_on = [aws_security_group.ssh_access, aws_security_group.icmp_traffic]
}

resource "aws_network_interface_attachment" "attachment" {
  count                = 2
  instance_id          = aws_instance.servers[count.index].id
  network_interface_id = aws_network_interface.extra_eni[count.index].id
  device_index         = 1

  depends_on = [aws_instance.servers, aws_network_interface.extra_eni]
}

resource "local_file" "ansible_hosts" {
  filename = "/home/ukasz-lewandowski/praca_inzynierska/ansible/hosts"

  content = templatefile(
    "/home/ukasz-lewandowski/praca_inzynierska/ansible/hosts.tpl",
    {
      server1_public = aws_instance.servers[0].public_ip
      server2_public = aws_instance.servers[1].public_ip
      pc1_private     = aws_instance.pcs[0].private_ip
      pc2_private     = aws_instance.pcs[1].private_ip
    }
  )

  depends_on = [aws_instance.servers, aws_instance.pcs]
}
