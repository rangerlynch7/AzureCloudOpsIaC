ssh sshuser@10.2.0.24
CLUSTERNAME=cclkt5
DOMAINNAME=cc.l.az.tygoelelat.local

ks () {
	# CLUSTERNAME=`hostname | awk -F- '{print $2}'`
	ssh sshuser@$1-$CLUSTERNAME.$DOMAINNAME
}
ks hn0
echo "ruok" | nc localhost 2181; echo
cat /etc/resolv.conf
nslookup hn0-$CLUSTERNAME.$DOMAINNAME 10.2.0.15
nslookup hn0-$CLUSTERNAME.$DOMAINNAME 
ping hn0-$CLUSTERNAME.$DOMAINNAME 

# s hn0
nslookup ccldnsfwd1.cc.l.az.tygoelelat.local 10.2.0.15

sudo killall -HUP mDNSResponder;sudo killall mDNSResponderHelper;sudo dscacheutil -flushcache
scutil --dns
nameserver 10.2.0.15