#!/bin/bash

echo "* Bootstraping Deltacloud API environment for development..."
echo
# Detect common Linux distributions:
#
DISTRO=""

[ -f /etc/fedora-release ] && DISTRO="fedora"
[ -f /etc/redhat-release ] && DISTRO="fedora"
[ -f /etc/suse-release ] && DISTRO="suse"
[ -f /etc/debian_version ] && DISTRO="debian"

# OSX:
case $OSTYPE in darwin*) DISTRO="osx" ;; esac

# Windows
case $OSTYPE in windows*) DISTRO="win" ;; esac

# TBD:
if [ "$DISTRO" == "" ] || [ "$DISTRO" == "win" ]; then
  echo "You're running unsupported operating system, please report this to dev@deltacloud.apache.org"
  echo
  exit 1
fi

if [ "$DISTRO" == "osx" ]; then
  echo "TODO: This script currently does not support OSX :-("
  echo "For more informations about installing Deltacloud API on OSX see:"
  echo
  echo "https://cwiki.apache.org/confluence/display/DTACLOUD/Deltacloud+API+development+setup+on+OSX"
  echo
  exit 1
fi

# Install runtime OS dependencies, like C compiler for Ruby and native gems and
# XML libraries for nokogiri

echo "* Checking runtime dependencies..."

if [ "$DISTRO" == "fedora" ]; then
  INSTALL_PKGS=""
  for thisrpm in git gcc gcc-c++ make libxml2 libxml2-devel libxslt libxslt-devel openssl-devel readline-devel zlib-devel libyaml-devel bison flex; do
    # Check if rpms are installed
    if ! `rpm -q --quiet ${thisrpm}`; then
      INSTALL_PKGS="$INSTALL_PKGS ${thisrpm}"
    fi
  done
  if [ ! -z "$INSTALL_PKGS" ]; then
    echo "* Following packages need to be installed: $INSTALL_PKGS"
    su -c "yum install -y $INSTALL_PKGS"
  fi
fi

if [ "$DISTRO" == "suse" ]; then
  INSTALL_PKGS=""
  for thisrpm in git gcc gcc-c++ automake libxml libxml2-devel libxslt libxslt-devel openssl-devel readline-devel zlib-devel libyaml-devel bison flex; do
    # Check if rpms are installed
    if ! `rpm -q --quiet ${thisrpm}`; then
      INSTALL_PKGS="$INSTALL_PKGS ${thisrpm}"
    fi
  done
  if [ ! -z "$INSTALL_PKGS" ]; then
    echo "* Following packages need to be installed: $INSTALL_PKGS"
    su -c "yum install -y $INSTALL_PKGS"
  fi
fi

if [ "$DISTRO" == "debian" ]; then
  REQUIRED_PKGS="build-essential libxml2 libxml2-dev libxslt1.1 libxslt1-dev git-core libssl-dev zlib1g-dev"
  INSTALL_PKGS=""
  for PKG in $REQUIRED_PKGS; do
    dpkg -s "$PKG" >/dev/null 2>&1 && {
      /bin/true
    } || {
      INSTALL_PKGS="$INSTALL_PKGS $PKG"
    }
  done
  if [ ! -z "$INSTALL_PKGS" ]; then
    echo "* Following packages need to be installed: $INSTALL_PKGS"
    sudo apt-get install -y $INSTALL_PKGS
  fi
fi



# Install 'rbenv' - a simple Ruby version manager. It will install Ruby to your
# homedir without touching your core operating system.
#
# You can change the Ruby version using: $ export RUBY_VERSION="1.9.3-p286"
#
# The full list of supported rubies: https://github.com/sstephenson/ruby-build/tree/master/share/ruby-build
#
[ -z $RUBY_VERSION] && RUBY_VERSION="1.9.3-p286"

if [ ! -f "$HOME/.rbenv/version" ]; then
  echo "* Installing rbenv"
  git clone git://github.com/sstephenson/rbenv.git $HOME/.rbenv &> /dev/null
  echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bash_profile
  echo 'eval "$(rbenv init -)"' >> ~/.bash_profile
  git clone git://github.com/sstephenson/ruby-build.git $HOME/.rbenv/plugins/ruby-build &> /dev/null
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$($HOME/.rbenv/bin/rbenv init -)"
  echo "* Installing MRI Ruby 1.9"
  $HOME/.rbenv/bin/rbenv install $RUBY_VERSION
  $HOME/.rbenv/bin/rbenv rehash
  RBENV_VERSION=$RUBY_VERSION gem install bundler
fi

# Prepare and clone your working directory
#
# You can change the directory where Deltacloud will be cloned using:
# $ export WORKDIR="your_directory"
#
[ -z $WORKDIR ] && WORKDIR="$HOME/code/core"

if [ ! -d $WORKDIR ]; then
  echo "* Downloading Deltacloud API source code into $WORKDIR"
  mkdir -p $WORKDIR
  git clone https://git-wip-us.apache.org/repos/asf/deltacloud.git $WORKDIR
fi

echo "* Installing Deltacloud dependencies"
cd $WORKDIR/server
$HOME/.rbenv/bin/rbenv local $RUBY_VERSION
bundle install

echo "* Complete! Happy hacking!"
echo
