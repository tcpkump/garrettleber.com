---
title: "Deploying Talos Kubernetes with OpenTofu and FluxCD"
date: 2025-05-07T21:39:27-04:00
socialShare: false
draft: false
author: "Garrett Leber"
tags:
- "development"
- "kubernetes"
- "opentofu"
- "homelab"
- "proxmox"
image: /images/talos.png
description: "My experience deploying a Talos cluster in my homelab"
---

## Introduction

In this post, I'll go over my experience deploying a recent version of Kubernetes(K8s) in my homelab using Talos
Linux and FluxCD, among other tooling.

A common first question is: Why? Why bother with Kubernetes in the homelab? Don't I get enough of it at my job? Isn't
it overkill? Do I really benefit from it?

This project was primarily a learning exercise. While I appreciate the self-hosting capabilities and standardization
Kubernetes offers, my main goal was to engage with concepts and tools outside my daily work, hence the deliberate choice
of new technologies alongside some I already knew.

## Why these tools?

*   [Proxmox](https://www.proxmox.com/en/):
    * This has been my hypervisor running my homelab for 7+ years now, and I have yet to find a reason to move away from
    it.
    * By virtualizing the cluster nodes, I can easily tear things down and rebuild them while developing, as I did
    *many* times.
*   [Talos Linux](https://www.talos.dev/):
    * It brands itself as "designed for Kubernetes – secure, immutable, and minimal." I find it particularly useful that
    I can create some declarative configuration and bootstrap a Kubernetes cluster with just Terraform/OpenTofu. I'd
    also like to expand on the points they give. It really is more secure than most other distributions as a result of
    being immutable and minimal. It's the combination of those two things that improves security. By being immutable,
    you don't need to worry about malware replacing assumed-good binaries on the host (what would happen if someone
    compromised `ls` on your system, would you notice? Are you checking that you are running the right version of `ls`?
    Are you checking hashes?). And by minimal, they mean that it really only has what it needs to run kubernetes. They
    don't even run `systemd`, or provide a shell for that matter.
    * A question that I had for myself, since I've been using Nix/NixOS so heavily for my personal computers and
    development environments, is why not use Nix? It has most of these same benefits, and there's documentation out
    there for using it to run Kubernetes clusters too. Ultimately, I decided against it for two reasons: 1) I like
    trying out alternative tooling in my lab. 2) The "minimal" pitch of Talos makes it more appealing, given all else is
    pretty much equal (e.g. you don't have a specific use-case that Talos doesn't support).
*   [OpenTofu](https://opentofu.org/):
    * I've been using Terraform day in and day out for over 5 years now, and with OpenTofu around for almost 2 years,
    adding all sorts of features I've been looking for in Terraform, and having a much friendlier, actually open source
    license... I just think that ideologically I should choose it over Terraform whenever I have the choice.
    * A key benefit of using OpenTofu is that I can manage the provisioning of my virtual machines (VMs) and the
    configuration/bootstrapping of the K8s cluster in the same code. Further, I can version control that, allowing for
    easy testing of changes, creation of new/multiple environments, and rollbacks when a new release has major bugs.
*   [FluxCD](https://fluxcd.io/):
    * My primary motivation here was simply to gain hands-on experience with FluxCD as an alternative to ArgoCD.
    * FluxCD is a GitOps tool that allows you to define your kubernetes manifests in a Git repository, and have FluxCD
    running in your K8s cluster, reading that repository, and continuously deploying your manifests to the cluster. It
    polls on a defined timer, checks for differences between the desired state in the cluster vs what is in the repo,
    and attempts to remediate deviations.
    * A key difference between FluxCD and ArgoCD is that Flux does **not** come with a UI. It is a much more bare-bones
    tool, more in line with [Unix Philosophy](https://en.wikipedia.org/wiki/Unix_philosophy).
*   How they fit together:
    * So, Proxmox is our hypervisor, this is what will actually run our VMs (our cluster nodes). Talos Linux is the
    Operating System that is running in the VMs, it manages starting the kubernetes services with appropriate
    configuration, pki, etc. Basically it is our K8s cluster. OpenTofu is a way for us to package our definition of what
    VMs we want to create, and what Talos configuration we would like to pass into those VMs. You could think of it like
    a glue layer. It also bootstraps FluxCD after the Talos cluster comes up and is healthy. FluxCD is used to manage
    everything in the cluster from here on out. Any applications, controllers, you name it that you want to deploy in
    the K8s cluster, it should be defined in the FluxCD repo. And that's it! Let's dive into how these pieces were assembled.

## Prerequisites and Environment Setup

Some background on my Proxmox setup for this. I actually had a completely flat network going into this, which I've
finally decided is unacceptable. I now have some dedicated `dev` and `prod` VLANs configured on my router, and with some
bridges set up in Proxmox, we're off to the races. Segmented networking, woo! (it's off topic, you're not hearing more
about it, sorry!)

Required tooling and environment is very conveniently handled by my new favorite thing, [Nix
Flakes](https://nixos.wiki/wiki/Flakes)! Anybody who has talked to me recently has heard about it, but if you haven't...
Nix is magical, both in the sense that it is amazing technology but also because it can feel completely
incomprehensible. The short pitch is that I'm able to define all of a project's dependencies in a `flake.nix` file in
the project repo, generate a `flake.lock` which pins all those packages to specific versions for anybody else who uses
it, and now have a consistent environment for anyone who uses the project, given they have nix installed. Developers
have an environment with all these packages available, and maybe even environment vars set, that does not affect any
other packages installed on their system when doing other work. It's great, and using it for your whole system
configuration is *wonderful*. Okay, I'm done, sorry. Here's an example `flake.nix` from the `tf-live` repository which
has the OpenTofu code for this project:

```nix
{
  description = "OpenTofu/Terragrunt Infrastructure development environment";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable"; # This is our package repository
  # These next two input flakes are useful for generating derivations for various systems and architectures. This flake
  # works for both x86_64 Linux and Apple Silicon Macs (like M1/M2/M3), for example.
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };

  outputs =
    { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system}; # Get packages for our current system/architecture
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ # List of packages we want available in our environment
            pkgs.tenv
            pkgs.talosctl
            pkgs.pre-commit
            pkgs.terraform-docs
            pkgs.trivy
            pkgs.gitleaks
          ];

          # Define the versions we want to use
          shellHook = '' # Yep, we can just drop a shell script in here
            OPENTOFU_VERSION="1.9.0"

            echo "Checking for required tool versions..."

            # Check if OpenTofu is installed at the correct version
            if ! tenv tf list | grep -q "$OPENTOFU_VERSION"; then
              echo "OpenTofu $OPENTOFU_VERSION is not installed."
              echo "Run: tenv tofu install $OPENTOFU_VERSION"
              INSTALL_NEEDED=1
            fi

            # If installations are needed, exit with instructions
            if [ -n "$INSTALL_NEEDED" ]; then
              echo ""
              echo "After installing the required versions, activate them with:"
              echo "tenv tofu use $OPENTOFU_VERSION"
              echo ""
              echo "Or run this shell again to verify."
            else
              # Set the versions to use
              tenv tf use $OPENTOFU_VERSION
              echo "Environment ready with OpenTofu $OPENTOFU_VERSION"
            fi
          '';
        };
      }
    );
}
```

I'll probably write a whole post, or several about Nix, so I'll leave it at that here. There's still a lot for me to
learn about it, but what I've already picked up has been incredibly useful, and I've drank the Nix Kool-aid, so to speak.

## Phase 1: Infrastructure Provisioning with OpenTofu

Our goal here is to provision our Proxmox VMs which will be part of the k8s cluster.

I found a great [example repo](https://github.com/vehagn/homelab) and [blog post](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/) from Vegard Hagen (github user vehagn) after much struggle trying to piece it together myself.

A key point I want to mention here is that bpg's Proxmox
[provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) is *great*. I always had issues with
Telmate's when trying to use Terraform to manage Proxmox the last few years, but this provider has been a great
experience in comparison so far.

### VM Configuration

* In my
[proxmox-talos-k8s-cluster](https://github.com/tcpkump/tf-modules/blob/proxmox-talos-k8s-cluster-v1.1.0/modules/proxmox-talos-k8s-cluster/virtual-machines.tf)
OpenTofu module, we define cluster nodes (VMs) in an object that contains various configurable options that I find
useful to expose for differences in workloads and environments. Here's what an example `nodes` object looks like:

```hcl
nodes = {
  "ctrl-00" = {
    host_node      = "ryzen-proxmox"
    machine_type   = "controlplane"
    ip             = "10.200.5.1"
    network_bridge = "vmbr200" # dev
    vm_id          = 800
    cpu            = 2
    ram_dedicated  = 2048
    igpu           = false
  }
  "ctrl-01" = {
    host_node      = "ryzen-proxmox"
    machine_type   = "controlplane"
    ip             = "10.200.5.2"
    network_bridge = "vmbr200" # dev
    vm_id          = 801
    cpu            = 2
    ram_dedicated  = 2048
    igpu           = false
  }
  "ctrl-02" = {
    host_node      = "ryzen-proxmox"
    machine_type   = "controlplane"
    ip             = "10.200.5.3"
    network_bridge = "vmbr200" # dev
    vm_id          = 802
    cpu            = 2
    ram_dedicated  = 2048
  }
}
```

Lets break this down:

* `nodes` contains a map of objects. Each object key (e.g. `ctrl-00`) is a VM hostname. The values of said objects
are the options for that specific VM.
  * `host_node` is the Proxmox host they should run on (particularly of interest if you run a multi-node Proxmox
  cluster). 
  * `machine_type` determines whether Talos will configure it as a control plane node or worker node.
  * `ip` accepts a static IP for the node. Note that DHCP is not implemented in this module, no particular reason,
  just don't require it. I would recommend using static IPs for control nodes at least though, just makes life
  easier.
  * `network_bridge` sets the network the VM should reside in. In my example it is my `dev` network, which is
  isolated from `prod` and my home LANs.
  * `vm_id` requires a unique ID for the VM that is not already used in the Proxmox cluster.
  * `cpu`/`ram_dedicated` as you might expect, this sets the compute resources available to the VM. `ram_dedicated`
  should not be lower than ~1700MB on control nodes, as Talos may refuse to run if set lower on control plane nodes.

Now, how do these options look when using the `bpg` Proxmox provider to create a VM?

```hcl
resource "proxmox_virtual_environment_vm" "this" {
  for_each = var.nodes # create a VM for every defined node

  node_name = each.value.host_node # `node_name` is the Proxmox node in this context

  name        = each.key # VM hostname
  description = each.value.machine_type == "controlplane" ? "Talos Control Plane" : "Talos Worker"
  # tags are just nice to have set, could be useful in the future for any programmatic actions/inventory against the
  # Proxmox API.
  tags        = each.value.machine_type == "controlplane" ? ["k8s", "control-plane"] : ["k8s", "worker"]
  on_boot     = true # start VM anytime Proxmox starts up
  vm_id       = each.value.vm_id

  machine       = "q35" # more recent, supports VIOMMU if you require it
  scsi_hardware = "virtio-scsi-single"
  bios          = "seabios" # this is default, non-UEFI. Haven't explored changing it

  agent {
    enabled = true # qemu-guest-agent must be installed and running in the VM if you use this
  }

  cpu {
    cores = each.value.cpu
    type  = "host" # passes through host CPU type
  }

  memory {
    dedicated = each.value.ram_dedicated
  }

  network_device {
    bridge = each.value.network_bridge
  }

  disk {
    datastore_id = each.value.datastore_id # Where our VM image(s) are stored
    interface    = "scsi0"
    iothread     = true # SSD-related AFAIK
    cache        = "writethrough" # SSD-related AFAIK
    discard      = "on" # SSD-related AFAIK
    ssd          = true
    file_format  = "raw" # for the supplied image in file_id
    size         = 10 # in GB
    file_id      = proxmox_virtual_environment_download_file.this[each.value.host_node].id # Talos Image
  }

  boot_order = ["scsi0"]

  operating_system {
    type = "l26" # Linux Kernel 2.6 - 6.X.
  }

  # cloud-init
  initialization {
    datastore_id = each.value.datastore_id

    # Optional DNS Block.  Update Nodes with a list value to use.
    dynamic "dns" {
      for_each = try(each.value.dns, null) != null ? { "enabled" = each.value.dns } : {}
      content {
        servers = each.value.dns
      }
    }

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.cluster.subnet_mask}"
        gateway = var.cluster.gateway
      }
    }
  }

  # if you need to pass through an iGPU, it's supported
  dynamic "hostpci" {
    for_each = each.value.igpu ? [1] : []
    content {
      # Passthrough iGPU
      device  = "hostpci0"
      mapping = "iGPU"
      pcie    = true
      rombar  = true
      xvga    = false
    }
  }
}
```

There's a lot of important info here. I've tried to comment heavily to provide wisdom and context.

### Talos Image Generation

* I took advantage of the [Talos Image Factory](https://factory.talos.dev/) (and a lot of the hard work in the
original version of the OpenTofu module I built off of) to fetch image(s) for our cluster nodes.
```hcl
locals {
  version      = var.image.version
  schematic    = file("${path.root}/${var.image.schematic_path}")
  schematic_id = jsondecode(data.http.schematic_id.response_body)["id"]

  # There are locals defined here with logic to determine if this is an image update or initial deployment, unimportant
  # ...

  image_id        = "${local.schematic_id}_${local.version}"

  # Same here
  # ...
}

data "http" "schematic_id" {
  url          = "${var.image.factory_url}/schematics"
  method       = "POST"
  request_body = local.schematic
}

# data "http" "updated_schematic_id" { ...

resource "talos_image_factory_schematic" "this" {
  schematic = local.schematic
}

# resource "talos_image_factory_schematic" "updated" { ...

locals {
  # There are locals defined here with logic to determine if this is an image update or initial deployment, unimportant
  # ...
}

resource "proxmox_virtual_environment_download_file" "this" {
  # Iterate directly over the unique host node names
  for_each = local.unique_host_nodes

  node_name    = each.key # The Proxmox node where the download happens
  content_type = "iso"
  datastore_id = var.image.proxmox_datastore

  # Use the globally determined version/schematic for all hosts
  # With cluster name in prefix so that the image in use for each cluster is unique. Prevents clashes.
  file_name               = "${var.cluster.name}-${local.effective_schematic}-${local.effective_version}-${var.image.platform}-${var.image.arch}.img"
  url                     = "${var.image.factory_url}/image/${local.effective_schematic}/${local.effective_version}/${var.image.platform}-${var.image.arch}.raw.gz"
  decompression_algorithm = "gz"
  overwrite               = false
}
```

And here is an example `schematic.yaml` that one might pass in:

```yaml
customization:
  systemExtensions:
    officialExtensions:
      - siderolabs/qemu-guest-agent
```

In my case, this is required configuration, at minimum, as the Proxmox VM config we made earlier always expects
`qemu-guest-agent` to be available.

Post schematic -> Get ID -> Use ID+Version -> Download Image.

With all this in place, we now have the ability to create some VMs running Talos, but they have no configuration yet,
meaning they aren't aware of each other, etc.

## Phase 2: Bootstrapping Talos Kubernetes

So we need to pass Talos configuration to the VMs that contains info about the other nodes in the cluster, and allows it
to generate PKI to bootstrap the cluster, etc. In this step we create the actual base cluster running core system
applications.

Here's the relevant code in the OpenTofu module:

```hcl
locals {
  # Talos expects that we run "bootstrap" against only one control plane node, so we extract one
  first_control_plane_node_ip = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"][0]
  # Use the VIP as our endpoint if we have one, otherwise default to the first control plane node
  kubernetes_endpoint         = coalesce(var.cluster.vip, local.first_control_plane_node_ip)
}

# Generates machine secrets for the cluster (PKI)
resource "talos_machine_secrets" "this" {}

# Generate client configuration (think `talosctl`) for performing actions against the cluster
data "talos_client_configuration" "this" {
  cluster_name         = var.cluster.name
  client_configuration = talos_machine_secrets.this.client_configuration # Need some secrets to authenticate
  nodes                = [for k, v in var.nodes : v.ip] # Need to know about the nodes
  # Only control plane nodes should be in the endpoints list because they host the API server
  endpoints            = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
}

# Generates configuration for the cluster nodes
data "talos_machine_configuration" "this" {
  for_each     = var.nodes
  cluster_name = var.cluster.name
  # This is the Kubernetes API Server endpoint.
  # ref - https://www.talos.dev/latest/introduction/prodnotes/#decide-the-kubernetes-endpoint
  cluster_endpoint = "https://${local.kubernetes_endpoint}:6443"
  # Sets the version, you don't really need to know more for the purposes of this
  talos_version    = var.cluster.talos_machine_config_version != null ? var.cluster.talos_machine_config_version : (each.value.update == true ? var.image.update_version : var.image.version)
  # control plane or worker?
  machine_type     = each.value.machine_type
  # each node needs the secrets to authenticate with each other
  machine_secrets  = talos_machine_secrets.this.machine_secrets
  # Pass in additional Talos configuration, we'll cover shortly
  config_patches = [
    templatefile("${path.module}/machine-config/common.yaml.tftpl", {
      node_name          = each.value.host_node
      cluster_name       = var.cluster.proxmox_cluster
      kubernetes_version = var.cluster.kubernetes_version
      hostname           = each.key
      ip                 = each.value.ip
      gateway            = var.cluster.gateway
      subnet_mask        = var.cluster.subnet_mask
      vip                = var.cluster.vip
    }), each.value.machine_type == "controlplane" ?
    # only for control plane nodes
    templatefile("${path.module}/machine-config/control-plane.yaml.tftpl", {
      allow_scheduling_on_control_plane_nodes = var.cluster.allow_scheduling_on_control_plane_nodes
      extra_manifests                         = jsonencode(var.cluster.extra_manifests)
    }) : ""
  ]
}

# Apply the configuration we just generated to the machines
resource "talos_machine_configuration_apply" "this" {
  depends_on                  = [proxmox_virtual_environment_vm.this] # Needs the VMs running first
  for_each                    = var.nodes
  node                        = each.value.ip
  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.this[each.key].machine_configuration
  lifecycle {
    # re-run config apply if vm changes
    replace_triggered_by = [proxmox_virtual_environment_vm.this[each.key]]
  }
}

resource "talos_machine_bootstrap" "this" {
  depends_on = [talos_machine_configuration_apply.this]
  # Bootstrap with the first control plane node.
  # VIP not yet available at this stage, so can't use var.cluster.vip
  # ref - https://www.talos.dev/v1.9/talos-guides/network/vip/#caveats
  node                 = local.first_control_plane_node_ip
  client_configuration = talos_machine_secrets.this.client_configuration
}

# This is a very convenient resource that waits until the Talos cluster is reporting healthy to show complete. I use
# it firstly to ensure we get a healthy cluster in testing, but also as a dependency for bootstrapping FluxCD.
data "talos_cluster_health" "this" {
  depends_on = [
    talos_machine_configuration_apply.this,
    talos_machine_bootstrap.this
  ]
  skip_kubernetes_checks = false # Additional checks to ensure healthiness
  client_configuration   = data.talos_client_configuration.this.client_configuration
  control_plane_nodes    = [for k, v in var.nodes : v.ip if v.machine_type == "controlplane"]
  worker_nodes           = [for k, v in var.nodes : v.ip if v.machine_type == "worker"]
  endpoints              = data.talos_client_configuration.this.endpoints
  timeouts = {
    read = "10m" # Can take some time
  }
}
```

Once this is up, one can use the `client_configuration` output from the OpenTofu module to configure their `talosctl`
client and run commands against the cluster. Like so:

```bash
# In my example, I expose a portion of the `client_configuration` output under a new output `talos_config`
tofu output -raw 'talos_config' > ~/.talos/config
talosctl health -n 10.200.10.1 # needs to be one of the nodes in the cluster
```

Now, to touch on the additional Talos configuration mentioned earlier. Here's the `common.yaml.tftpl` template in the
OpenTofu module:

```
machine:
  nodeLabels:
    topology.kubernetes.io/region: ${cluster_name} # can be useful for cluster administration
    topology.kubernetes.io/zone: ${node_name} # same
  network:
    hostname: ${hostname}
    interfaces:
      - deviceSelector:
          physical: true # select the first NIC on the node
        addresses:
          - ${ip}/${subnet_mask}
        routes:
          - network: 0.0.0.0/0 # default gateway
            gateway: ${gateway}
        dhcp: false
%{ if vip != null } # a VIP lets us have a highly-available endpoint for our control plane, highly recommended
        vip:
          ip: ${vip}
%{ endif }
```

and our `control-plane.yaml.tfpl`:

```
cluster:
  # dev clusters may not require dedicated worker nodes, save some resources/time provisioning
  allowSchedulingOnControlPlanes: ${allow_scheduling_on_control_plane_nodes}
  # Bootstrap some extra manifests if desired (like Cilium, MetalLB, etc.)
  extraManifests: ${extra_manifests}
```

There isn't too much to this, as it's passing most of our vars straight through with clear naming.

So now we have a bare Talos cluster up, but with nothing running in it.

## Phase 3: Implementing GitOps with FluxCD

We want to automatically bootstrap our Talos cluster with our GitOps tool, in an effort to automate as much of this
process as possible. In this case, I'm experimenting with FluxCD, which has a Terraform (OpenTofu) provider.

Here's the relevant code in the OpenTofu module:
  
```hcl
# I use a private gitea instance for hosting my git repos, change this as needed
data "gitea_repo" "this" {
  username = var.flux_bootstrap_repo.username
  name     = var.flux_bootstrap_repo.name
}

# Flux can use SSH for communicating with a git repo, generate a unique key
resource "tls_private_key" "ed25519" {
  algorithm = "ED25519"
}

# Add the access key to gitea with write permissions
resource "gitea_repository_key" "this" {
  title      = "${var.cluster.name}-flux"
  repository = data.gitea_repo.this.id
  key        = trimspace(tls_private_key.ed25519.public_key_openssh)
  read_only  = false
}

# Strap the boot
resource "flux_bootstrap_git" "this" {
  depends_on = [
    gitea_repository_key.this,
    data.talos_cluster_health.this
  ]

  embedded_manifests = true
  path               = "clusters/${var.cluster.name}"
}
```

I think this is super straightforward, and I found it very easy to implement. Kudos to Flux/Gitea developers for their
work on these providers.

One thing I found very interesting with Flux that I don't recall being the same with ArgoCD the last time I worked
with it... it actually writes *back into* the GitOps repository it is pointed to with the manifests it has deployed
for the version of FluxCD it is running. And further, when you tear down the cluster, if it has the opportunity (isn't
killed forcefully), it will actually remove those from the git repo as well.

To be honest, I'm not sure how much I like granting Flux the permission to write to my Git repository, it feels like
more risk with minimal benefit, but I'm not fully versed on the "why" for this decision, and maybe ArgoCD is the same
way and I just haven't encountered it.

Inside of the [fluxcd-demo](https://github.com/tcpkump/fluxcd-demo) repository, I keep manifests using Helm, Kustomize, and bare Kubernetes manifests to define
both system applications and workloads, which Flux will immediately start trying to align the cluster to. From here,
one would handle pretty much everything from the FluxCD repo, outside of upgrading the version of Talos running on
cluster nodes, or needing to add a manifest before Flux gets bootstrapped (in `extra_manifests`).

## Phase 4: Deploying workloads via Flux

With Flux, I've tried to follow their [suggested repository structure](https://fluxcd.io/flux/guides/repository-structure/).

```
.
├── apps                           # Application definitions (what runs ON the cluster)
│   ├── base                       # Common application manifests (Kustomize bases)
│   │   └── vector                 # Example App: Vector
│   │       ├── kustomization.yaml # Kustomize definition for Vector base
│   │       └── vector.yaml        # Core Vector manifests (Deployment, ConfigMap, etc.)
│   └── dev                        # Environment-specific overlays (e.g., 'dev')
│       └── kustomization.yaml     # Kustomize overlay for 'dev' apps
│
├── clusters                       # Cluster definitions (defines WHICH clusters Flux manages)
│   ├── minikube                   # Example: Config for a 'minikube' cluster (used for local testing)
│   │   ├── flux-system            # Flux components/bootstrap for *this* cluster
│   │   ├── apps.yaml              # Flux Kustomization: Points to desired apps (e.g., apps/dev)
│   │   └── infrastructure.yaml    # Flux Kustomization: Points to desired infra (e.g., infrastructure/controllers)
│   └── talos-dev                  # Example: Config for a 'talos-dev' cluster
│       ├── flux-system            # Flux components/bootstrap for 'talos-dev'
│       ├── apps.yaml              # Flux Kustomization for 'talos-dev' apps
│       └── infrastructure.yaml    # Flux Kustomization for 'talos-dev' infra
│
└── infrastructure                 # Cluster-wide infrastructure components (NEEDED BY the cluster)
    ├── configs                    # Shared configurations (e.g., ClusterIssuers)
    │   └── cluster-issuers.yaml   # Example: cert-manager issuers
    └── controllers                # Core controllers/operators (often HelmReleases)
        ├── cert-manager.yaml      # Example: Install cert-manager via Flux
        └── ingress-nginx.yaml     # Example: Install ingress-nginx via Flux

# Key Structure:
# - `apps`: Your applications.
# - `infrastructure`: Cluster support services (ingress, certs, monitoring).
# - `clusters`: Ties specific clusters to app/infra states & holds Flux bootstrap.
```

Lets take a look at the Vector configuration as an example.

`clusters/talos-dev/apps.yaml`

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps                # Name of this Kustomization resource
  namespace: flux-system    # Must be in flux-system namespace
spec:
  interval: 2m0s            # How often Flux checks for changes
  dependsOn:
    - name: infra-configs   # Ensures infrastructure is ready first
  sourceRef:
    kind: GitRepository     # References the Flux GitRepository
    name: flux-system
  path: ./apps/dev          # Points to dev environment overlay
  prune: true               # Removes resources that are no longer in Git
  wait: true                # Waits for resources to be ready
  timeout: 5m0s             # Maximum time to wait
```

This [Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/) resource is from FluxCD and allows us
to track a git repository for a defined Kustomize overlay or plain Kubernetes manifest. Here we are using it in our
cluster definitions to watch our `apps/` directory in the same repository.

If we look at the `kustomization.yaml` file in that path:

`apps/dev/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../base/vector/
```

We see that we declare a `vector` application should be present in `dev` environments. Next we'll look at Vector to see
what is going on there. Don't get too wrapped up in what we are deploying in `vector.yaml` but instead think about how
Flux watches the repository and deploys these manifests using kustomize.

`apps/base/vector/vector.yaml`

```yaml
# This is an intentionally broken deployment meant for me to experiment with PodMonitors
---
apiVersion: v1
kind: Namespace
metadata:
  name: vector
---
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: vector
spec:
  interval: 24h
  url: https://helm.vector.dev
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: vector
spec:
  interval: 30m
  chart:
    spec:
      chart: vector
      version: "0.42.x"
      sourceRef:
        kind: HelmRepository
        name: vector
      interval: 12h
  values:
    role: "Stateless-Aggregator"
    podMonitor:
      enabled: true
      additionalLabels:
        release: kube-prom-stack
    customConfig:
      data_dir: /vector-data-dir
      api:
        enabled: false
        address: 127.0.0.1:8686
        playground: false
      sources:
        vector_metrics:
          type: internal_metrics
          scrape_interval_secs: 10
        vector_agents:
          address: 0.0.0.0:6000
          type: http_server
          encoding: json
          path: /
          method: POST
      transforms:
        vector_metrics_limit_cardinality:
          type: tag_cardinality_limit
          inputs:
            - vector_metrics
          mode: exact
        filter_vector_metrics:
          type: filter
          inputs:
            - vector_metrics
          condition: |
            match(.name, r'^vector_kafka_queue_messages') ||
            match(.name, r'^vector_kafka_produced_messages_total')
      sinks:
        prom-exporter:
          type: prometheus_exporter
          inputs:
            - vector_metrics_limit_cardinality
          address: 0.0.0.0:9598
        broken_kafka:
          type: kafka
          inputs:
            - vector_agents
          tls:
            enabled: true
          encoding:
            codec: raw_message
          bootstrap_servers: "wrong"
          topic: "wrong"
          sasl:
            enabled: true
            mechanism: SCRAM-SHA-512
            # you would NOT place plaintext secrets here, in a real deployment, I recommend using something like the
            # External Secrets Operator: https://external-secrets.io/latest/
            # and then environment variables if the helm chart doesn't support direct secret refs
            username: "fake"
            password: "fake"
```

`apps/base/vector/kustomization.yaml`

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: vector
resources:
  - vector.yaml
```

We have to have this `kustomization.yaml` file because we are including it from another `kustomization.yaml` file. It
simply declares what files in the directory are Kubernetes manifests, alongside, such as application configuration files
which might also be in YAML format.

With this whole setup, anytime we push changes to manifests to our `main` branch, we should see FluxCD trying to align
the cluster state with them within ~2 minutes.

And that's that! We've defined an entire Kubernetes cluster in code in a way that a single `tofu apply` command will
stand it up end-to-end and actually start running workloads. Pretty neat!

## Challenges and Lessons Learned

My biggest challenge during this was actually correcting the Proxmox VM configuration. For a while I had an error along
the lines of "bootstrap method not supported" from Talos when it got to the bootstrap step. I couldn't find anything
online about this so I had to really dive in and figure out what was going on. Unfortunately, I'm really bad at taking
notes, and wasn't thinking about making a blog post like this while I was doing it, so I'm working from memory. What I
think the issue was, was that the way I was passing my Talos configuration to the VMs at the time was not surviving
reboots for whatever reason. I noticed this because after the VMs would reboot from applying the Talos config, they
would fail to report their IP addresses in Proxmox and said that the QEMU guest agent wasn't running (I still find this
odd because it is in the image, not config...). It took me hours and hours of experimentation until one time it worked
and I moved on. I'm sorry that I don't have better information on the root cause and exactly what fixed it to anyone who
lands here because of that.

I learned that, at least at this time, I still prefer ArgoCD over FluxCD. I generally like minimal tools that do their
job well, but something about Argo and their whole ecosystem makes the administrative experience so much easier that I
expect to pivot my module over to Argo in the near future. It also must be stated that Argo has a dominant share of the
market over FluxCD, which leads to a much better experience when looking for information online, as well as better
experience for job opportunities.

## Conclusions and Next Steps

Even with the hurdles, this was a really great experience, and I'm fully sold on Talos Linux. I expect to be running it
in my homelab for many years, as it has already given me a degree of confidence that other solutions haven't. When I
used to run k3s and managed it with Ansible, it all just felt so *brittle*, and that there would inevitably be some
drift anytime I went to run my playbooks against it after ~6 months or more. Not to mention that I had to worry about
upgrading system packages because it was running on a standard distro.

OpenTofu is neat. I didn't get to exploring any features that differentiate it from Terraform in this case, but look
forward to doing that soon. I could really improve the testing side of these modules, so I might check that out next.

I already mentioned it in the last section but I'll say it here too. I'm not sold on FluxCD. It wasn't *bad*, but ArgoCD
is just so *good* and I have so much more experience with it that I will probably go back to it. I can already see
myself using some Argo Workflows, and it would just be nice to be in the same ecosystem for tools like that.

## Further Reading and Source Code

Repositories:

* [tf-live](https://github.com/tcpkump/tf-live)
* [tf-modules](https://github.com/tcpkump/tf-modules)
    * My `proxmox-talos-k8s-cluster` couldn't have happened without [this blog post](https://blog.stonegarden.dev/articles/2024/08/talos-proxmox-tofu/) and [his repository](https://github.com/vehagn/homelab)
* [fluxcd-demo](https://github.com/tcpkump/fluxcd-demo)
