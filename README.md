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

- ```ThinkCentre-M92P:~/Projects/ofGitHub$ dig @192.168.178.32

; <<>> DiG 9.10.3-P4-Ubuntu <<>> @192.168.178.32
; (1 server found)
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 51658
;; flags: qr rd ra ad; QUERY: 1, ANSWER: 13, AUTHORITY: 0, ADDITIONAL: 1

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;.				IN	NS

;; ANSWER SECTION:
.			473396	IN	NS	e.root-servers.net.
.			473396	IN	NS	h.root-servers.net.
.			473396	IN	NS	k.root-servers.net.
.			473396	IN	NS	m.root-servers.net.
.			473396	IN	NS	c.root-servers.net.
.			473396	IN	NS	i.root-servers.net.
.			473396	IN	NS	j.root-servers.net.
.			473396	IN	NS	l.root-servers.net.
.			473396	IN	NS	a.root-servers.net.
.			473396	IN	NS	d.root-servers.net.
.			473396	IN	NS	b.root-servers.net.
.			473396	IN	NS	g.root-servers.net.
.			473396	IN	NS	f.root-servers.net.

;; Query time: 0 msec
;; SERVER: 192.168.178.32#53(192.168.178.32)
;; WHEN: Tue Aug 22 17:30:14 CEST 2017
;; MSG SIZE  rcvd: 239
```




# Unsorted
- ```apt-get install procps```
- ```apt-get install dnsutils```
- ```apt-get update && apt-get install -y procps dnsutils```

