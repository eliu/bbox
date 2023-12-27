# B-Box (Base-Box) - 基础 Linux 开发环境

本项目通过 Vagrant 快速启动一个适用于国内网络环境的干净的 Linux 开发环境。以下 Vagrant Box 镜像已通过验证：

- bento/centos-7
- bento/rockylinux-8
- bento/rockylinux-9

相比于 [eliu/devbox: 快速开发环境 (github.com)](https://github.com/eliu/devbox)，bbox 没有过多的配置选项，没有额外的软件需要安装

## 先决条件

- [Oracle VM VirtualBox](https://www.virtualbox.org/)
- [Vagrant](https://www.vagrantup.com/)

## 开始使用

### 克隆项目

```shell
$ git clone https://github.com/eliu/bbox.git
```

### 配置参数

由于本项目设计初衷是尽可能简单，所以配置越少越好，目前仍可以配置两个选项，可通过 `export` 命令来覆盖，这些选项如下：

| 选项            | 含义                               | 默认值 |
| --------------- | ---------------------------------- | ------ |
| VG_LOG_LEVEL    | 日志打印级别，info, verbose, debug | info   |
| VG_SHOW_WRAP_UP | 在初始化完成后是否输出汇总信息     | true   |

如需覆盖，可以在 Vagrantfile 的 $script 区段进行设置，如下：

```shell
set -e
export VG_LOG_LEVEL=verbose # <--- here
source /vagrant/bbox.sh
setup::main
```

### 快速启动

项目默认启动三个 VirtualBox 虚拟机，使用的 Vagrant Box 镜像分别为 `bento/centos-7`、`bento/rockylinux-8`、`bento/rockylinux-9`。进入项目主目录 `cd bbox` 然后执行启动命令：

```shell
$ vagrant up
```

在终端会看到类似下面的日志信息，该信息表示在环境初始化完成之后，执行一次安装 `cowsay` 以验证开发环境是否可以正常安装软件。

```
==> centos: Running provisioner: shell...
    centos: Running: inline script
    centos: [INFO] Gathering facts for networks...
    centos: [INFO] All set! Wrap it up...
    centos: PROPERTY     VALUE
    centos: machine os   CentOS Linux release 7.9.2009 (Core)
    centos: machine ip   192.168.133.101
    centos: dns list     114.114.114.114,8.8.8.8
    centos: epel         epel-release.noarch.7-14
    centos: timezone     Asia/Shanghai
    centos:  _____________________________________
    centos: < Congrats! bbox successfully inited! >
    centos:  -------------------------------------
    centos:         \   ^__^
    centos:          \  (oo)\_______
    centos:             (__)\       )\/\
    centos:                 ||----w |
    centos:                 ||     ||
==> rocky8: Running provisioner: shell...
    rocky8: Running: inline script
    rocky8: [INFO] Gathering facts for networks...
    rocky8: [INFO] All set! Wrap it up...
    rocky8: PROPERTY     VALUE
    rocky8: machine os   Rocky Linux release 8.8 (Green Obsidian)
    rocky8: machine ip   192.168.133.102
    rocky8: dns list     114.114.114.114,8.8.8.8
    rocky8: epel         epel-release.noarch.8-19.el8
    rocky8: timezone     Asia/Shanghai
    rocky8:  _____________________________________
    rocky8: < Congrats! bbox successfully inited! >
    rocky8:  -------------------------------------
    rocky8:         \   ^__^
    rocky8:          \  (oo)\_______
    rocky8:             (__)\       )\/\
    rocky8:                 ||----w |
    rocky8:                 ||     ||
==> rocky9: Running provisioner: shell...
    rocky9: Running: inline script
    rocky9: [INFO] Gathering facts for networks...
    rocky9: [INFO] All set! Wrap it up...
    rocky9: PROPERTY     VALUE
    rocky9: machine os   Rocky Linux release 9.2 (Blue Onyx)
    rocky9: machine ip   192.168.133.103
    rocky9: dns list     114.114.114.114,8.8.8.8
    rocky9: epel         epel-release.noarch.9-7.el9
    rocky9: timezone     Asia/Shanghai
    rocky9:  _____________________________________
    rocky9: < Congrats! bbox successfully inited! >
    rocky9:  -------------------------------------
    rocky9:         \   ^__^
    rocky9:          \  (oo)\_______
    rocky9:             (__)\       )\/\
    rocky9:                 ||----w |
    rocky9:                 ||     ||
```

### 销毁环境

```shell
$ vagrant destroy -f
```

## License

[Apache-2.0](LICENSE)

