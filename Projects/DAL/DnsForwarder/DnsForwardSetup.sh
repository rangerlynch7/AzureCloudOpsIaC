#!/bin/sh
#
#  based on https://github.com/Azure/azure-quickstart-templates/blob/master/301-dns-forwarder/forwarderSetup.sh
#
#  $1 is the forwarder, $2 is the vnet IP range
#
# logs
# /var/lib/waagent/custom-script/download/1
# /var/log/azure/custom-script/handler.log
# /var/log/waagent.log


touch /tmp/forwarderSetup_start
echo "$@" > /tmp/forwarderSetup_params

DnsForwardTarget=$1
DnsForwardAcl=$2
DnsZone=$3
NAMEDCONF=/etc/named.conf

# DnsForwardAcl=10.0.0.0/8
# DnsForwardTarget=168.63.129.16
# DnsZone=cc.l.az.tygoelelat.local

echo DnsForwardTarget=$DnsForwardTarget
echo DnsForwardAcl=$DnsForwardAcl
echo DnsZone=$DnsZone

#  Install Bind9
#  https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-Dns-server-on-ubuntu-14-04
#  https://www.digitalocean.com/community/tutorials/how-to-install-the-bind-dns-server-on-centos-6
# sudo yum update -y
sudo yum install bind bind-libs bind-utils -y

# configure Bind9 for forwarding
echo $NAMEDCONF
sudo cat > $NAMEDCONF << EndOFNamedConfOptions
acl trusted {
 $DnsForwardAcl;
 localhost;
 localnets;
};

options {
  directory "/var/named";
  allow-query { trusted; };
  forward only;
  forwarders {
    $DnsForwardTarget;
  };
  dnssec-enable yes; # dns-sec ok for non azurednsprivate i.e. public ips
  max-ncache-ttl 1200; # 3 seconds; expire failed/negative answer ASAP.
  dnssec-validation no; # dns-sec fails on azurednsprivate
  auth-nxdomain no; # conform to RFC1035
  recursion yes; 
};
EndOFNamedConfOptions
sudo named-checkconf
echo "* $NAMEDCONF"
sudo cat $NAMEDCONF

echo "* Setup"
sudo systemctl enable named.service
sudo systemctl restart named
sudo firewall-cmd --permanent --add-port=53/tcp
sudo firewall-cmd --permanent --add-port=53/udp
sudo firewall-cmd --reload
# chgrp named -R /var/named
# chown -v root:named /etc/named.conf
# restorecon -rv /var/named
# restorecon /etc/named.conf
# ls -l /var/named
# ls -l /etc/named.conf

echo "* Testing"
DnsIP=localhost
nslookup yahoo.com $DnsIP
nslookup `hostname` $DnsIP
nslookup `hostname`.$DnsZone $DnsIP

# dig @localhost yahoo.com. A +dnssec +multiline
# dig @localhost `hostname`.$DnsZone. A +dnssec +multiline

touch /tmp/forwarderSetup_end