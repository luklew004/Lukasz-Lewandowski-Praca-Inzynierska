[ec2servers]
server1 ansible_host=${server1_public} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 gre_peer=10.10.10.1 local_networks="172.31.1.0/24,172.31.2.0/24"
server2 ansible_host=${server2_public} ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519 gre_peer=10.10.10.2 local_networks="172.31.1.0/24,172.31.3.0/24"

[ec2pc]
pc1 ansible_host=${pc1_private} gateway=172.31.2.50 ansible_ssh_common_args='-o ProxyJump=ubuntu@${server1_public}' ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519
pc2 ansible_host=${pc2_private} gateway=172.31.3.50 ansible_ssh_common_args='-o ProxyJump=ubuntu@${server2_public}' ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/id_ed25519