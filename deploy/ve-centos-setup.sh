#!/bin/bash

# Update repos
yum update -y && yum install -y epel-release && yum clean all

# Install wget and git
set -eux &&\
  yum -y install git &&\
  yum -y install wget &&\
  yum -y clean all

# Download & Install Open JDK 1.8
yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel

# Install gcc and build tools
yum update -y && yum install -y \
  cmake \
  curl-devel \
  cronie \
  czmq \
  expat-devel \
  flex \
  gcc \
  gcc-c++ \
  gcc-gfortran \
  gdb \
  gettext-devel \
  glibc-devel \
  lynx \
  libattr-devel \
  libcurl \
  libcurl-devel \
  libedit-devel libffi-devel \
  libgcc \
  libstdc++-static \
  libtool \
  m4 \
  make \
  automake \
  autoconf \
  && yum clean all

# Install Boost
yum -y install \
  lapack-devel \
  blas-devel \
  boost \
  boost-devel \
  swig \
  && yum clean all

# Install QuantLib
wget https://github.com/lballabio/QuantLib/archive/QuantLib-v1.9.2.tar.gz \
  && tar xf QuantLib-v1.9.2.tar.gz \
  && cd QuantLib-QuantLib-v1.9.2 \
  && ./autogen.sh \
  && ./configure \
  && make -j"$(nproc --all)" \
  && make install \
  && ldconfig \
  && cd .. && rm -rf QuantLib-QuantLib-v1.9.2 && rm -f QuantLib-v1.9.2.tar.gz

# Export Paths
export JAVA_HOME=/usr/lib/jvm/java
export CLASSPATH=.:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:$JAVA_HOME/bin

# Install QuantLib-SWIG for Java bindings
git clone https://github.com/lballabio/QuantLib-SWIG.git \
  && cd QuantLib-SWIG && git checkout v1.9.x  \
  && sh ./autogen.sh \
    && ./configure --disable-perl --disable-ruby --disable-mzscheme --disable-guile --disable-csharp --disable-ocaml --disable-r --disable-python --with-jdk-include=$JAVA_HOME/include --with-jdk-system-include=$JAVA_HOME/include/linux CXXFLAGS=-O3 \
    && make clean && make -C Java && make install -C Java \
    && cd ..

# Install Go
mkdir ~/downloads \
  && cd ~/downloads \
  && wget https://storage.googleapis.com/golang/go1.8.linux-amd64.tar.gz \
  && tar -C /usr/local -xzf go1.8.linux-amd64.tar.gz

# Install Stress tool
wget ftp://fr2.rpmfind.net/linux/dag/redhat/el7/en/x86_64/dag/RPMS/stress-1.0.2-1.el7.rf.x86_64.rpm \
  && yum -y localinstall stress-1.0.2-1.el7.rf.x86_64.rpm
