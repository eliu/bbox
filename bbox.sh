#
# libvgup.sh
# supporting vagtant box: bento/centos-7, bento/rockylinux-8^
# including modules: style, log, test, network, setup
#
readonly PROG=$(basename $0)
readonly STYLE_GREEN="\e[32m"
readonly STYLE_YELLOW="\e[33m"
readonly STYLE_RED="\e[91m"
readonly STYLE_CYAN="\e[36m"
readonly STYLE_RESET="\e[39m"
readonly LOG_LEVEL=${VG_LOG_LEVEL:-info}
readonly SETUP_ENV_FILE="/etc/profile.d/$PROG.sh"
readonly SETUP_SHOW_WRAP_UP=${VG_SHOW_WRAP_UP:-true}

style::green() {
  echo -e "$STYLE_GREEN$@$STYLE_RESET"
}
style::yellow() {
  echo -e "$STYLE_YELLOW$@$STYLE_RESET"
}
style::red() {
  echo -e "$STYLE_RED$@$STYLE_RESET"
}
style::cyan() {
  echo -e "$STYLE_CYAN$@$STYLE_RESET"
}

# ----------------------------------------------------------------
# Logging message at info level
# ----------------------------------------------------------------
log::info() { echo $(style::green  "[INFO]") $@
}
# ----------------------------------------------------------------
# Logging message at warning level
# ----------------------------------------------------------------
log::warn() { echo $(style::yellow "[WARN] $@")
}
# ----------------------------------------------------------------
# Logging message at fatal level
# ----------------------------------------------------------------
log::fatal() { echo $(style::red "[FATA] $@"); exit 1
}
# ----------------------------------------------------------------
# Logging a verbose message
# ----------------------------------------------------------------
log::verbose() { 
  log::is_verbose_enabled && echo $(style::cyan "VERBOSE: $@") || true
}
# ----------------------------------------------------------------
# Check if we're in verbose mode or lower level logging
# ----------------------------------------------------------------
log::is_verbose_enabled() {
  [[ $LOG_LEVEL =~ debug|verbose ]]
}
# ----------------------------------------------------------------
# Check if we're in debug mode
# ----------------------------------------------------------------
log::is_debug_enabled() {
  [[ $LOG_LEVEL =~ debug ]]
}

readonly QUIET_FLAG_Q=$(log::is_verbose_enabled || printf -- "-q")
readonly QUIET_FLAG_S=$(log::is_verbose_enabled || printf -- "-s")
readonly QUIET_STDOUT=$(log::is_verbose_enabled && echo "/dev/stdout" || echo "/dev/null")

# ----------------------------------------------------------------
# Check if specified commands exists
# #@: commands separated with spaces
# ----------------------------------------------------------------
test::cmd() {
  while [ $# -gt 0 ]; do
    command -v $1 >/dev/null 2>&1 && shift || return
  done
  return 0
}

# ----------------------------------------------------------------
# Execute command as vagrant
# ----------------------------------------------------------------
vg::exec() {
  [[ "root" = $(whoami) ]] && su - vagrant -c "$@" || $@
}

# ----------------------------------------------------------------
# Execute command as root. User vagrant can become root via sudo
# ----------------------------------------------------------------
vg::sudo_exec() {
  local context="$MODULE_ROOT/vagrant.sh"
  [[ "root" = $(whoami) ]] && $@ || sudo bash -c ". $context && $@"
}

# ----------------------------------------------------------------
# Change owner to vagrant
# ----------------------------------------------------------------
vg::chown() {
  vg::sudo_exec "chown -R vagrant:vagrant $1"
}

# ----------------------------------------------------------------
# Fix the following error that will cause all running containers stopped unexpectly.
# ERRO[0000] Refreshing container <containerID>: 
# error acquiring lock 0 for container <containerID>: file exists
# ---
# Issue: https://github.com/containers/podman/issues/16784#issuecomment-1711364992
# ----------------------------------------------------------------
vg::enable_linger() {
  vg::sudo_exec "loginctl enable-linger vagrant"
}

# ----------------------------------------------------------------
# Append content to vagrant's context
# ----------------------------------------------------------------
vg::env() {
  vg::exec "echo \"$@\" >> \$HOME/.bashrc"
}

declare -a namespaces=("114.114.114.114" "8.8.8.8")
declare -A network_facts
# ----------------------------------------------------------------
# Get uuids of all active connections
# Scope: private
# ----------------------------------------------------------------
network::get_active_uuids() {
  nmcli -get-values UUID conn show --active
}

# ----------------------------------------------------------------
# Get ipv4 method, the possible value might be auto or manual
# $1 -> network uuid
# Scope: private
# ----------------------------------------------------------------
network::get_ipv4_method_of() {
  nmcli -terse conn show uuid $1 \
    | grep ipv4.method \
    | awk -F '[:/]' '{print $2}'
}

# ----------------------------------------------------------------
# Gather network uuid with auto ipv4 method
# Scope: private
# ----------------------------------------------------------------
network::gather_uuid_with_auto_method() {
  log::info "Gathering facts for networks..."
  for uuid in $(network::get_active_uuids); do
    [[ "auto" = $(network::get_ipv4_method_of $uuid) ]] && {
      network_facts[uuid]=$uuid
      return
    }
  done
  log::fatal "Failed to locate correct network interface."
}

# ----------------------------------------------------------------
# Gather dns list of specified network
# $1 -> network uuid
# Scope: private
# ----------------------------------------------------------------
network::gather_dns_of() {
  network_facts[dns]=$(nmcli -terse conn show $1 | grep "ipv4.dns:" | cut -d: -f2)
}

# ----------------------------------------------------------------
# Gather static ip address
# Scope: private
# ----------------------------------------------------------------
network::gather_static_ip() {
  network_facts[ip]=$(ip -br -f inet addr | grep 192 | awk -F'[ /]+' '{print $3}')
}

# ----------------------------------------------------------------
# Check if any of the facts is absent
# Scope: private
# ----------------------------------------------------------------
network::facts_absent() {
  [[ -z ${network_facts[uuid]} ]] || \
  [[ -z ${network_facts[dns]}  ]] || \
  [[ -z ${network_facts[ip]}   ]]
}

# ----------------------------------------------------------------
# Gather all facts for network info, including
# 1. uuid      -> exported to network_facts[uuid]
# 2. static ip -> exported to network_facts[ip]
# 3. dns list  -> exported to network_facts[dns]
# ----------------------------------------------------------------
network::gather_facts() {
  if network::facts_absent; then
    [[ -n ${network_facts[uuid]} ]] || network::gather_uuid_with_auto_method
    [[ -n ${network_facts[dns]}  ]] || network::gather_dns_of ${network_facts[uuid]}
    [[ -n ${network_facts[ip]}   ]] || network::gather_static_ip

    if log::is_verbose_enabled; then
      log::verbose "network_facts:"
      for key in ${!network_facts[@]}; do
        log::verbose "$key -> ${network_facts[$key]}"
      done | column -t
    fi
  fi
}

# ----------------------------------------------------------------
# Resolve DNS issue in China
# Scope: private
# ----------------------------------------------------------------
network::resolve_dns() {
  network::gather_facts
  
  [[ -n ${network_facts[dns]} && -n ${network_facts[uuid]} ]] || {
    log::info "Resolving dns..."
    for nameserver in ${namespaces[@]}; do
      log::verbose "Adding nameserver $nameserver..."
      nmcli con mod ${network_facts[uuid]} +ipv4.dns $nameserver
    done

    log::verbose "Restarting network manager..."
    nmcli con reload
    systemctl restart NetworkManager
    sleep 2
  }
}

# ----------------------------------------------------------------
# Fetch epel version info
# Scope: private
# ----------------------------------------------------------------
version::epel() {
  $PKGMGR $QUIET_FLAG_Q list installed "epel*" | grep epel | awk '{print $1"."$2}'
}

# ----------------------------------------------------------------
# Resolve dns lookup issue
# Scope: private
# ----------------------------------------------------------------
setup::dns() {
  network::resolve_dns
}

# ----------------------------------------------------------------
# Set up environment variables
# PARAMETERS
# $1 -> synopsis
# $2 -> export statement
# ----------------------------------------------------------------
setup::add_context() {
  if [[ -n $2 ]]; then
    grep "$2" $SETUP_ENV_FILE > /dev/null 2>&1 || {
      log::verbose "Setting up environment for $1..."
      echo "$2" >> $SETUP_ENV_FILE
      source /etc/profile > /dev/null
    }
  else
    log::fatal "Context details not provided."
  fi
}

# ----------------------------------------------------------------
# Remove environment context
# PARAMETERS
# $1 -> keyword
# ----------------------------------------------------------------
setup::del_context() {
  log::verbose "Deleting environment for keyword $1..."
  sed -i -e "/$1/d" $SETUP_ENV_FILE
  source /etc/profile > /dev/null
}

# ----------------------------------------------------------------
# Gather all os info into variables starting with OS_
# Scope: private
# ----------------------------------------------------------------
setup::gather_facts() {
  source <(cat /etc/os-release | sed -e '/^[[:space:]]*$/d' -re 's/^(.*)/OS_\1/g')
  OS_VERSION_MAJOR=$(echo $OS_VERSION_ID | cut -d'.' -f1)
  test::cmd dnf && PKGMGR=dnf || PKGMGR=yum
}

# ----------------------------------------------------------------
# Make cache for repo (right after accelerating repo...)
# Scope: private
# ----------------------------------------------------------------
setup::make_cache() {
  log::info "Making cache. This may take a few seconds..."
  $PKGMGR $QUIET_FLAG_Q makecache >$QUIET_STDOUT 2>&1
}

# ----------------------------------------------------------------
# Change repo mirror to aliyun
# ----------------------------------------------------------------
setup::repo() {
  setup::gather_facts
  case $OS_ID in
  rocky)
    grep aliyun /etc/yum.repos.d/*ocky*.repo > /dev/null 2>&1 || {
      log::info "Accelerating base repo..."
      # https://developer.aliyun.com/mirror/rockylinux
      sed -i.bak \
        -e 's|^mirrorlist=|#mirrorlist=|g' \
        -e 's|^#baseurl=http://dl.rockylinux.org/$contentdir|baseurl=https://mirrors.aliyun.com/rockylinux|g' \
        /etc/yum.repos.d/*ocky*.repo
      setup::make_cache
    }
    ;;
  centos)
    [[ $OS_VERSION_MAJOR = "7" ]] || log::fatal "Only centos 7.x distros are supported."
    grep aliyun /etc/yum.repos.d/CentOS-Base.repo >/dev/null 2>&1 || {
      rm -fr /etc/yum.repos.d/*.repo
      curl -sSL https://mirrors.aliyun.com/repo/Centos-7.repo -o /etc/yum.repos.d/CentOS-Base.repo
      sed -i.bak \
        -e '/mirrors.cloud.aliyuncs.com/d' \
        -e '/mirrors.aliyuncs.com/d' \
        /etc/yum.repos.d/CentOS-Base.repo
      setup::make_cache
    }
    ;;
  *)
    log::fatal "OS $OS_ID not supported."
    ;;
  esac
}

# ----------------------------------------------------------------
# Install and accelerate epel repo
# Scope: private
# ----------------------------------------------------------------
setup::epel() {
  setup::gather_facts
  
  $PKGMGR list installed "epel*" > /dev/null 2>&1 || {
    log::info "Installing epel-release..."
    $PKGMGR install $QUIET_FLAG_Q -y \
      https://mirrors.aliyun.com/epel/epel-release-latest-${OS_VERSION_MAJOR}.noarch.rpm \
      >$QUIET_STDOUT 2>&1
    
    log::info "Accelerating epel repo..."
    # https://developer.aliyun.com/mirror/epel/?spm=a2c6h.25603864.0.0.43455993b5QGRS
    rm -f /etc/yum.repos.d/epel-cisco-openh264.repo
    sed -i.bak \
      -e 's|^#baseurl=https\?://download.example/pub|baseurl=https://mirrors.aliyun.com|' \
      -e 's|^metalink|#metalink|' \
      /etc/yum.repos.d/epel*
    setup::make_cache
  }
}

# ----------------------------------------------------------------
# Wrap up post-setup infomation
# Scope: private
# ----------------------------------------------------------------
setup::wrap_up() {
  network::gather_facts
  log::info "All set! Wrap it up..."
  cat << EOF | column -t -s "|"
PROPERTY   |VALUE
machine os |$(style::green $(cat /etc/system-release))
machine ip |$(style::green ${network_facts[ip]})
dns list   |$(style::green ${network_facts[dns]})
epel       |$(style::green $(version::epel))
timezone   |$(style::green $TZ)
EOF
}

# ----------------------------------------------------------------
# The main function call goes here
# Scope: public
# ----------------------------------------------------------------
setup::main() {
  setup::add_context "TZ" "export TZ=Asia/Shanghai"
  setup::dns
  setup::repo
  setup::epel
  [[ $SETUP_SHOW_WRAP_UP = "true" ]] && setup::wrap_up || true
}
