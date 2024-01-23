locals {
  cluster_domain = "cluster.local"
  nicparent      = "network-${var.env}-docker"
  containers_server = [
    {
      name         = "container-${var.env}-k3s-s1"
      ipv4_address = "10.20.0.11"
    }
  ]
  containers_worker     = []
  fixed_registration_ip = "10.20.0.31"
  external_ip           = "10.20.0.32"
  containers_loadbalancer = [
    {
      name         = "container-${var.env}-k3s-slb"
      ipv4_address = local.fixed_registration_ip
      bind_port    = 6443
      servers = [for item in local.containers_server : {
        address : item.ipv4_address,
        port : 6443
      }]
    },
    {
      name         = "container-${var.env}-k3s-alb"
      ipv4_address = local.external_ip
      bind_port    = 443
      servers = [for item in local.containers_server : {
        address : item.ipv4_address,
        port : 443
      }]
    }
  ]
}

module "container_loadbalancers" {
  count  = length(local.containers_loadbalancer)
  source = "github.com/studio-telephus/terraform-docker-haproxy.git?ref=main"
  image  = data.docker_image.debian_bookworm.id
  name   = local.containers_loadbalancer[count.index].name
  networks = [
    {
      name         = local.nicparent
      ipv4_address = local.containers_loadbalancer[count.index].ipv4_address
    }
  ]
  bind_port           = local.containers_loadbalancer[count.index].bind_port
  servers             = local.containers_loadbalancer[count.index].servers
  stats_auth_password = module.bw_haproxy_stats.data.password
}

module "docker_swarm" {
  source            = "github.com/studio-telephus/terraform-docker-k3s-swarm.git?ref=main"
  swarm_private_key = module.bw_swarm_private_key.data.notes
  containers        = concat(local.containers_server, local.containers_worker)
  network_name      = local.nicparent
  restart           = "unless-stopped"
}

module "k3s_cluster" {
  source          = "github.com/studio-telephus/terraform-docker-k3s-embedded.git?ref=main"
  ssh_private_key = module.bw_swarm_private_key.data.notes
  cluster_domain  = local.cluster_domain
  network_name    = local.nicparent
  cidr_pods       = "10.20.10.0/22"
  cidr_services   = "10.20.15.0/22"
  k3s_install_env_vars = {
    "K3S_KUBECONFIG_MODE" = "644"
  }
  server_flags = [
    "--disable local-storage",
    "--tls-san ${local.fixed_registration_ip}"
  ]
  containers_server = local.containers_server
  containers_worker = local.containers_worker
  depends_on = [
    module.docker_swarm,
    module.container_loadbalancers[0]
  ]
}

resource "local_sensitive_file" "kube_config" {
  content    = module.k3s_cluster.k3s_kube_config
  filename   = var.kube_config_path
  depends_on = [module.k3s_cluster]
}
