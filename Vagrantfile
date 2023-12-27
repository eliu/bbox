# -*- mode: ruby -*-
# vi: set ft=ruby :
$script = <<-SHELL
  #!/usr/bin/env bash
  set -e
  source /vagrant/bbox.sh
  setup::main
  # making test
  test::cmd cowsay || {
    test::cmd dnf && dnf install -q -y cowsay || yum install -q -y cowsay
  }
  vg::exec 'cowsay "Congrats! bbox successfully inited!"'
SHELL
# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|
  config.vm.box_check_update = false
  config.vm.provider "virtualbox" do |vb|  
    vb.memory = "1024"
    vb.cpus = 1
  end
  config.vm.provision "shell", keep_color: true, inline: $script

  config.vm.define "centos" do |s|
    s.vm.box = "bento/centos-7"
    s.vm.network "private_network", ip: "192.168.133.101"
  end

  config.vm.define "rocky8" do |s|
    s.vm.box = "bento/rockylinux-8"
    s.vm.network "private_network", ip: "192.168.133.102"
  end

  config.vm.define "rocky9" do |s|
    s.vm.box = "bento/rockylinux-9"
    s.vm.network "private_network", ip: "192.168.133.103"
  end
end
