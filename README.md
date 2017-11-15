# Usage 
- git checkout
    - ```git clone https://github.com/MathiasStadler/docker-unbound.git```
- run unbound via docker
    - ```./run.sh```
- to force to build a new images
    - ```./run.sh -n```



# tl;dr
- without Exposed ports
- found automatic the ip for the docker container iptables rules
- set 
    - iptables -t nat -A OUTPUT -p udp --dport $DNS_PORT -j DNAT --to $DEST_IP:$DNS_PROXY_PORT;
    - iptables -t nat -A POSTROUTING -j MASQUERADE
- catch transparent all DNS request on PORT 53 host/ virtualbox(vagrant)/ docker
- delete forwarding rule during the container stopping 

# idea
- [based of](https://github.com/MatthewVance/unbound-docker.git)

- Please visit for details  this project

# ENV
- HW Lenovo M92P
- LSB Version: ```lsb_release  -i -d -r -c```
    - Distributor ID: Ubuntu
    - Description:    Ubuntu 16.04.3 LTS
    - Release:        16.04
    - Codename:       xenial
- Fast internet

# unbound-control (in a new shell same host)
- docker exec -it $(cat unbound_container.id) /opt/unbound/sbin/unbound-control -h
    

# Used own A or PTR record 
- Please edit the a-record.conf in the root directory of the project
    - The edit of the a-record.conf in the "current" directory is the default file
        - should have nothing record   

# Monitoring DNS Queries with tcpdump

   - ```tcpdump -vvv -s 0 -l -n port 53```
   - from here ```https://jontai.me/blog/2011/11/monitoring-dns-queries-with-tcpdump/```


# check DNS server
- dig @DNS Server IP
- e.g. ```dig @192.168.178.32```
- ![output](https://github.com/MathiasStadler/docker-unbound/blob/feature/add-unbound-control/doc/pictures/digAtLocalDnsServerIp.png?raw=true)



# check request from a-records.conf
- ```dig @192.168.178.32 docker-proxy.fritz.box```
- short answer
- ```dig +short @192.168.178.32 docker-proxy.fritz.box```



# unbound-control
- run ./bash_container.sh connect container
- ```./bash_container.sh```
- change in command directory
- ```cd /opt/unbound/sbin```
- run unbound-control
- ``` ./unbound-control```

- unbound status
- ```./unbound-control status```

- unbound local zone
- ```./unbound-control list_local_zones```

- set a dynamic ip address
- ```./unbound-control local_data "docker1-proxy.fritz.box A 192.168.178.44"```


# set transperent unbound mode of local desktop/server
- check dnsmasq is not active
- ``` ps -ef|grep dnsmasq```
- deactivate that to commend in the file
- ```cat /etc/NetworkManager/NetworkManager.conf```
- ths line like so
-```#dns=dnsmasq```  
- and restart the network-manager
- ```service network-manager restart```


- run set-iptables-transperent-unbound
- ```./set-iptables-transperent-unbound.sh```
- control set the rules aktive
- ```iptables -t nat -L```


# ipdatbles
- ```iptable -t nat -L```

# netstat for check is the server listen on port XX
```sudo netstat -anp|grep 53```

# install ps inside the container
- ```apt-get update &&  apt-get install procps```

# install dig inside the container
- ```apt-get install dnsutils```


# psgrep 
- ```ps -ef|grep /opt/unbound/sbin/unbound |grep -v grep |awk '{print $2}' ```



# Unsorted
- ```apt-get install procps```
- ```apt-get install dnsutils```
- ```apt-get update && apt-get install -y procps dnsutils```


- ```nmap -v -sn 192.168.178.0/24 |grep fritz.box```

#resolve custom record from a-records.conf
- ```dig +short  @192.168.178.32 docker-proxy.home.lan```



#Link
- https://utcc.utoronto.ca/~cks/space/blog/linux/UnboundDNSforVPN  split dns query
- https://www.unbound.net/documentation/howto_turnoff_dnssec.html  disable dnssec

- Using Unbound to block Ads
- https://www.bentasker.co.uk/documentation/linux/279-unbound-adding-custom-dns-records

- Testing validation
- https://wiki.archlinux.org/index.php/unbound#Root_hints



#docker domainname
--hostname mail.deploymentbox.com
--dns

#puffer
#from here
#https://wiki.archlinux.org/index.php/unbound#Forwarding_queries
local-zone: "localhost." static
local-data: "localhost. 10800 IN NS localhost."
local-data: "localhost. 10800 IN SOA localhost. nobody.invalid. 1 3600 1200 604800 10800"
local-data: "localhost. 10800 IN A 127.0.0.1"
local-zone: "127.in-addr.arpa." static
local-data: "127.in-addr.arpa. 10800 IN NS localhost."
local-data: "127.in-addr.arpa. 10800 IN SOA localhost. nobody.invalid. 2 3600 1200 604800 10800"
local-data: "1.0.0.127.in-addr.arpa. 10800 IN PTR localhost."


#from here
#https://wiki.archlinux.org/index.php/unbound#Forwarding_queries
local-zone: "192.168.178.in-addr.arpa." transparent

forward-zone:
name: "fritz.box."
forward-addr: 192.168.178.1

forward-zone:
name: "192.168.178.in-addr.arpa."
forward-addr: 192.168.178.1


# unbound add local-data
- https://abridge2devnull.com/posts/2016/03/unbound-dns-server-cache-control/
- eg ./unbound-control local_data "docker1-proxy.fritz.box A 192.168.178.44"


# dhcpdump 
- debug dhcp request 
- install ```sudo apt install dhcpdump```
- sudo dhcpdump -i eno1



# local-data  PTR 
https://www.unbound.net/documentation/unbound.conf.html


# Execute command from a container to another container?
- https://forums.docker.com/t/execute-command-from-a-container-to-another-container/19492


# TODO container muss run under technical user _unbound