# docker-unbound
- copy of https://github.com/MatthewVance/unbound-docker.git 

# Please visit for details  this project

# ENV
- HW Lenovo M92P
- LSB Version: ```lsb_release  -i -d -r -c```
    - Distributor ID: Ubuntu
    - Description:    Ubuntu 16.04.3 LTS
    - Release:        16.04
    - Codename:       xenial

- Fast internet

# Usage 
- git checkout
    - ```git clone https://github.com/MathiasStadler/docker-unbound.git```
- run unbound via docker
    - ```./run.sh```
- to force to build a new images
    - ```./run.sh -n```

# Used own A or PTR record 
    - Please edit the a-record.conf in the root directory of the project
    - The edit of the a-record.conf in the "current" directory is the default file
        - should have nothing record   

# Monitoring DNS Queries with tcpdump

   - ```tcpdump -vvv -s 0 -l -n port 53```
   - from here ```https://jontai.me/blog/2011/11/monitoring-dns-queries-with-tcpdump/```


# check DNS server
- dig @<DNS Server IP>
- e.g. ```dig @192.168.178.32```
- ![output](https://github.com/MathiasStadler/docker-unbound/blob/feature/add-unbound-control/doc/pictures/digAtLocalDnsServerIp.png?raw=true)



# Unsorted
- ```apt-get install procps```
- ```apt-get install dnsutils```
- ```apt-get update && apt-get install -y procps dnsutils```

