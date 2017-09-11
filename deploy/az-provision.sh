#!/bin/bash

$ az login
$ az group create --name <resource-group> --location <location>
$ az vm create -g <resource-group> --location <location> -n ve-ql-template --image CentOS  --admin-username veritas --ssh-key-value ~/.ssh/az.pub

$ scp -i ~/.ssh/az deploy/ve-centos-setup.sh veritas@<ve-ql-template-PIP>:~/.
$ ssh -i ~/.ssh/az veritas@<ve-ql-template-PIP>

#-------------------------------------------------------------------
# In Template VM
#-------------------------------------------------------------------
[veritas@ve-ql-template ~]$ mkdir ~/go
[veritas@ve-ql-template ~]$ sudo su
[root@ve-ql-template ~]# mv /home/veritas/ve-centos-setup.sh .
[root@ve-ql-template ~]# ./ve-centos-setup.sh

# Add following to /etc/profile
export JAVA_HOME=/usr/lib/jvm/java
export CLASSPATH=.:$JAVA_HOME/jre/lib:$JAVA_HOME/lib:$JAVA_HOME/lib/tools.jar
export LD_LIBRARY_PATH=/usr/local/lib:/usr/local/lib64
export PATH=$PATH:/usr/local/sbin:/usr/local/bin:$JAVA_HOME/bin:/usr/local/go/bin
export GOPATH=/home/veritas/go

[root@ve-ql-template ~]# mkdir -p /var/log/veritas && chown -R veritas /var/log/veritas && chgrp -R veritas /var/log/veritas

# Run on startup by adding following line to /etc/rc.d/rc.local
runuser -l veritas -c 'go run /home/veritas/compute/valengine.go > /var/log/veritas/valengine.log 2>&1 &'

[root@ve-ql-template ~]# chmod +x /etc/rc.d/rc.local
[root@ve-ql-template ~]# exit

[veritas@ve-ql-template ~]$ mkdir ~/compute && mkdir ~/compute-engine-az-vmss

[veritas@ve-ql-template ~]$ go get github.com/koding/kite
[veritas@ve-ql-template ~]$ git clone https://github.com/amolthacker/azure-poc-compute-engine-vmss.git compute-engine-vmss/
[veritas@ve-ql-template ~]$ cp ~/compute-engine-vmss/*.go ~/compute/.
[veritas@ve-ql-template ~]$ sudo cp ~/compute-engine-vmss/bin/* /usr/local/bin/.
[veritas@ve-ql-template ~]$ sudo cp ~/compute-engine-vmss/lib/* /usr/local/lib/.

# Test setup
[veritas@ve-ql-template ~]$ ql-compute NPV 10

# Deprovision agent
[veritas@ve-ql-template ~]$ sudo su
[root@ve-ql-template ~]# waagent -deprovision
[root@ve-ql-template ~]# exit

#-------------------------------------------------------------------

# Deallocate and Generalize
$ az vm deallocate -g <resource-group> -n ve-ql-template
$ az vm generalize -g <resource-group> -n ve-ql-template

# Create Image
$ az image create -g <resource-group> -n ve-ql-img --source ve-ql-template

# Deploy
$ az group deployment create -g <resoure-group> --template-file azuredeploy.json --parameters @azuredeploy.parameters.json

# Create Ctrl VM from Image
$ az vm create -g <resource-group> -n ve-ql-ctrl --image ve-ql-template --size Standard_D2_V2 --admin-username veritas \
--ssh-key-value ~/.ssh/az.pub

# Assign DNS prefix 'vectrl' to the VM's PIP