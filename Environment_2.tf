/*Variables*/
//The OCID of the tenancy. https://docs.cloud.oracle.com/iaas/Content/General/Concepts/identifiers.htm#two
variable "tenancy_ocid" {
  type    = "string"
  default = "xxxxxx"
}
//The OCID of the user that is gonna deploy the cluster. https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm#five
variable "user_ocid" {
  type    = "string"
  default = "xxxxx"
}
//Path to the Private Key. https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm#two
variable "private_key_path" {
  type    = "string"
  default = "xxx.pem"
}
// Fingerprint for the uploaded key. https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm#four
variable "fingerprint" {
  type    = "string"
  default = "xxxxxxxx"
}
// The OCID for the compartment in which the OKE cluster is gonna be deployed. https://docs.cloud.oracle.com/iaas/Content/Identity/Tasks/managingcompartments.htm
variable "compartment_ocid" {
  type    = "string"
  default = "xxxx"
}
//Identifier for the region of the Compartment
variable "region" {
  type = "string"
  //Ex	default = "us-ashburn-1"
  default = "xxxx"
}
variable "cluster_name" {
  type    = "string"
  default = "oke_cluster_test"
}
// Pool of nodes for the cluster https://docs.cloud.oracle.com/iaas/Content/ContEng/Concepts/contengclustersnodes.htm
variable "node_pool_name" {
  type    = "string"
  default = "node_pool_test"
}
//Shape for the nodes of the Cluster
variable "node_pool_node_shape" {
  type    = "string"
  default = "VM.Standard1.1"
}
//Number of node_pool per subnet
variable "node_pool_quantity_per_subnet" {
  type    = "string"
  default = "1"
}
//Os image
variable "node_pool_node_image_name" {
  type    = "string"
  default = "Oracle-Linux-7.6"
}


/*Provider Information*/
provider "oci" {
  tenancy_ocid     = "${var.tenancy_ocid}"
  user_ocid        = "${var.user_ocid}"
  fingerprint      = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  /*private_key_password = "${var.private_key_password}"*/
  region = "${var.region}"
}
data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}
/* Network */
resource "oci_core_virtual_network" "vcn1" {
  cidr_block     = "10.1.0.0/16"
  compartment_id = "${var.compartment_ocid}"
  display_name   = "vcn1"
  dns_label      = "vcn1"
}
resource "oci_core_security_list" "securitylist1" {
  display_name   = "public"
  compartment_id = "${oci_core_virtual_network.vcn1.compartment_id}"
  vcn_id         = "${oci_core_virtual_network.vcn1.id}"

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      max = 22
      min = 22
    }
  }
}
#AD1
resource "oci_core_subnet" "subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")}"
  cidr_block          = "10.1.20.0/24"
  display_name        = "subnet1"
  dns_label           = "subnet1"
  security_list_ids   = ["${oci_core_security_list.securitylist1.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn1.id}"
  route_table_id      = "${oci_core_route_table.routetable1.id}"
  dhcp_options_id     = "${oci_core_virtual_network.vcn1.default_dhcp_options_id}"
}
#AD2
resource "oci_core_subnet" "subnet2" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1], "name")}"
  cidr_block          = "10.1.21.0/24"
  display_name        = "subnet2"
  dns_label           = "subnet2"
  security_list_ids   = ["${oci_core_security_list.securitylist1.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn1.id}"
  route_table_id      = "${oci_core_route_table.routetable1.id}"
  dhcp_options_id     = "${oci_core_virtual_network.vcn1.default_dhcp_options_id}"
}
#AD3
resource "oci_core_subnet" "subnet3" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2], "name")}"
  cidr_block          = "10.1.19.0/24"
  display_name        = "subnet3"
  dns_label           = "subnet3"
  security_list_ids   = ["${oci_core_security_list.securitylist1.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn1.id}"
  route_table_id      = "${oci_core_route_table.routetable1.id}"
  dhcp_options_id     = "${oci_core_virtual_network.vcn1.default_dhcp_options_id}"
}
/*terraform to create an Internet Gateway*/
resource "oci_core_internet_gateway" "internetgateway1" {
  compartment_id = "${var.compartment_ocid}"
  display_name   = "internetgateway1"
  vcn_id         = "${oci_core_virtual_network.vcn1.id}"
}
resource "oci_core_route_table" "routetable1" {
  compartment_id = "${var.compartment_ocid}"
  vcn_id         = "${oci_core_virtual_network.vcn1.id}"
  display_name   = "routetable1"

  route_rules {
    cidr_block        = "0.0.0.0/0"
    network_entity_id = "${oci_core_internet_gateway.internetgateway1.id}"
  }
}
#AD1
resource "oci_core_subnet" "node_pool_subnet1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0], "name")}"
  cidr_block          = "10.1.22.0/24"
  display_name        = "node_pool_subnet1"
  security_list_ids   = ["${oci_core_security_list.securitylist1.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn1.id}"
  route_table_id      = "${oci_core_route_table.routetable1.id}"
}
#AD2
resource "oci_core_subnet" "node_pool_subnet2" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1], "name")}"
  cidr_block          = "10.1.23.0/24"
  display_name        = "node_pool_subnet2"
  security_list_ids   = ["${oci_core_security_list.securitylist1.id}"]
  compartment_id      = "${var.compartment_ocid}"
  vcn_id              = "${oci_core_virtual_network.vcn1.id}"
  route_table_id      = "${oci_core_route_table.routetable1.id}"
}


/*Kubernetes*/
resource "oci_containerengine_cluster" "test_cluster" {
  #Required
  compartment_id     = "${var.compartment_ocid}"
  kubernetes_version = "v1.13.5"
  name               = "${var.cluster_name}"
  vcn_id             = "${oci_core_virtual_network.vcn1.id}"
}
resource "oci_containerengine_node_pool" "test_node_pool" {
  #Required
  cluster_id          = "${oci_containerengine_cluster.test_cluster.id}"
  compartment_id      = "${var.compartment_ocid}"
  kubernetes_version  = "v1.13.5"
  name                = "${var.node_pool_name}"
  node_image_name     = "${var.node_pool_node_image_name}"
  node_shape          = "${var.node_pool_node_shape}"
  quantity_per_subnet = "${var.node_pool_quantity_per_subnet}"
  subnet_ids          = ["${oci_core_subnet.node_pool_subnet1.id}", "${oci_core_subnet.node_pool_subnet2.id}"]
}
