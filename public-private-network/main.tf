provider "openstack" {
}



resource "openstack_networking_network_v2" "public_network" {
  name           = "public_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "public_subnet" {
  name            = "public_subnet"
  network_id      = "${openstack_networking_network_v2.public_network.id}"
  cidr            = "10.10.1.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_compute_secgroup_v2" "public_security_group" {
  name = "public_security_group"
  description = "an public security group"
  rule {
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
    cidr        = "0.0.0.0/0"
  }
   
  rule {
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_router_v2" "public_router" {
  name             = "public_router"
  external_gateway = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

resource "openstack_networking_router_interface_v2" "public_router_interface" {
  router_id = "${openstack_networking_router_v2.public_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.public_subnet.id}"
}

resource "openstack_networking_floatingip_v2" "public_floatip_manager" {
  pool = "internet"
}

resource "openstack_compute_instance_v2" "public_host" {
  name            = "public_host"
  count = 1

  #Centos7
  image_id        = "0f1785b3-33c3-451e-92ce-13a35d991d60"
  
  flavor_id       = "51043dfe-25ec-4fdb-9219-36e5700e076e"
  key_pair        = "ukcloudos"
  security_groups = ["${openstack_compute_secgroup_v2.public_security_group.name}"]

  network {
    name        = "${openstack_networking_network_v2.public_network.name}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.public_floatip_manager.address}"
  instance_id = "${openstack_compute_instance_v2.public_host.id}"
  fixed_ip = "${openstack_compute_instance_v2.public_host.network.1.fixed_ip_v4}"
}
