# -*- mode: ruby -*-
# vi: set ft=ruby :
$script = <<-SHELL
  #!/usr/bin/env bash
  set -e
  # export VG_LOG_LEVEL=verbose
  # export VG_SHOW_STATS=false
  source /vagrant/bbox.sh
  setup::main
  welcome_msg="Congrats! bbox successfully inited!"
  pkgmgr::install cowsay \
    && vg::exec "cowsay ${welcome_msg}" \
    || echo "${welcome_msg}"
SHELL

Vagrant.configure("2") do |config|
  config.ssh.insert_key = false
  config.vm.box_check_update = false
  config.vm.provider "virtualbox" do |vb|  
    vb.memory = "4096"
    vb.cpus = 4
  end
  config.vm.provision "shell", keep_color: true, inline: $script

  config.vm.define "rocky8", autostart: false do |s|
    s.vm.box = "bento/rockylinux-8"
    s.vm.network "private_network", ip: "192.168.13.10"
  end

  config.vm.define "rocky9", primary: true do |s|
    s.vm.box = "bento/rockylinux-9"
    s.vm.network "private_network", ip: "192.168.13.11"
  end

  config.vm.define "rocky10", autostart: false do |s|
    s.vm.box = "bento/rockylinux-10"
    s.vm.network "private_network", ip: "192.168.13.12"
  end

  config.vm.define "alma8", autostart: false do |s|
    s.vm.box = "bento/almalinux-8"
    s.vm.network "private_network", ip: "192.168.13.20"
  end

  config.vm.define "alma9", autostart: false do |s|
    s.vm.box = "bento/almalinux-9"
    s.vm.network "private_network", ip: "192.168.13.21"
  end

  config.vm.define "alma10", autostart: false do |s|
    s.vm.box = "bento/almalinux-10"
    s.vm.network "private_network", ip: "192.168.13.22"
  end  

  config.vm.define "centos7", autostart: false do |s|
    s.vm.box = "bento/centos-7"
    s.vm.network "private_network", ip: "192.168.13.30"
  end
end
