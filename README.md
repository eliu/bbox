# bbox (Base Box) - 基于 Vagrant 的 Linux 基础开发环境

本项目通过 Vagrant 快速启动一个适用于国内网络环境的干净的 Linux 开发环境。以下 Vagrant Box 镜像已通过验证：

| 操作系统             | Vagrant Box 镜像        | 虚拟机名称   | IP            | 默认镜像 | 启动命令                                |
| ---------------- | --------------------- | ------- | ------------- | ---- | ----------------------------------- |
| Rocky Linux 8.x  | `bento/rockylinux-8`  | rocky8  | 192.168.13.10 |      | `vagrant up rocky8`                 |
| Rocky Linux 9.x  | `bento/rockylinux-9`  | rocky9  | 192.168.13.11 | ✔︎   | `vagrant up` 或者 `vagrant up rocky9` |
| Rocky Linux 10.x | `bento/rockylinux-10` | rocky10 | 192.168.13.12 |      | `vagrant up rocky10`                |
| AlmaLinux 8.x    | `bento/almalinux-8`   | alma8   | 192.168.13.20 |      | `vagrant up alma8`                  |
| AlmaLinux 9.x    | `bento/almalinux-9`   | alma9   | 192.168.13.21 |      | `vagrant up alma9`                  |
| AlmaLinux 10.x   | `bento/almalinux-10`  | alma10  | 192.168.13.22 |      | `vagrant up alma10`                 |
| CentOS 7.x       | `bento/centos-7`      | centos7 | 192.168.13.30 |      | `vagrant up centos7`                |

相比于 [eliu/devbox: 快速开发环境 (github.com)](https://github.com/eliu/devbox)，bbox 没有过多的配置选项，没有额外的软件需要安装。

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

| 选项            | 含义                          | 默认值  |
| ------------- | --------------------------- | ---- |
| VG_LOG_LEVEL  | 日志打印级别，info, verbose, debug | info |
| VG_SHOW_STATS | 在初始化完成后是否输出汇总信息             | true |

如需覆盖，可以在 Vagrantfile 的 $script 区段进行设置，如下：

```shell
set -e
export VG_LOG_LEVEL=verbose # <--- here
source /vagrant/bbox.sh
setup::main
# ...
```

### 快速启动

项目默认启动一个 VirtualBox 虚拟机，使用的 Vagrant Box 镜像 `bento/rockylinux-9`，启动命令如下：

```shell
$ vagrant up
```

对于其他的 Box 镜像，如果用户想要使用它们，可以再次运行 `vagrant up` 命令，并在后面指定“虚拟机名称”，一次可以指定多个。举例说明，以下命令将依次启动 `alma9` 和 `centos` 两个虚拟机：

```shell
$ vagrant up alma9 centos
```

Vagrant 虚拟机在启动过程中，终端会看到类似下面的日志信息，该信息表示在环境初始化完成之后，执行一次安装 `cowsay` 以验证开发环境是否可以正常安装软件。

```
==> rocky9: Running provisioner: shell...
    rocky9: Running: inline script
    rocky9: [INFO] Gathering facts for networks...
    rocky9: [INFO] All set! Wrap it up...
    rocky9: PROPERTY     VALUE
    rocky9: machine os   Rocky Linux release 9.2 (Blue Onyx)
    rocky9: machine ip   192.168.13.10
    rocky9: dns list     114.114.114.114,8.8.8.8
    rocky9: epel         epel-release.noarch.9-7.el9
    rocky9: timezone     Asia/Shanghai
    rocky9: [INFO] Installing cowsay...
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
