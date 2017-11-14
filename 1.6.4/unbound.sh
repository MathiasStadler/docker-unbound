#!/bin/bash

reserved=12582912
availableMemory=$((1024 * $( (fgrep MemAvailable /proc/meminfo || fgrep MemTotal /proc/meminfo) | sed 's/[^0-9]//g')))
if [ $availableMemory -le $((reserved * 2)) ]; then
	echo "Not enough memory" >&2
	exit 1
fi
availableMemory=$((availableMemory - reserved))
msg_cache_size=$((availableMemory / 3))
rr_cache_size=$((availableMemory / 3))
nproc=$(nproc)
if [ "$nproc" -gt 1 ]; then
	threads=$((nproc - 1))
else
	threads=1
fi

sed \
	-e "s/@MSG_CACHE_SIZE@/${msg_cache_size}/" \
	-e "s/@RR_CACHE_SIZE@/${rr_cache_size}/" \
	-e "s/@THREADS@/${threads}/" \
	>/opt/unbound/etc/unbound/unbound.conf <<EOT
## Authoritative, validating, recursive caching DNS
## unbound.conf -- https://calomel.org
#
server:

username: "_unbound"
log-queries: no
logfile: /opt/unbound/etc/unbound/unbound.log
chroot: "/opt/unbound/etc/unbound"
directory: "/opt/unbound/etc/unbound"
auto-trust-anchor-file: "var/root.key"

  # log verbosity
    verbosity: 2

  # specify the interfaces to answer queries from by ip-address.  The default
  # is to listen to localhost (127.0.0.1 and ::1).  specify 0.0.0.0 and ::0 to
  # bind to all available interfaces.  specify every interface[@port] on a new
  # 'interface:' labeled line.  The listen interfaces are not changed on
  # reload, only on restart.
 #   interface: 127.0.0.1
interface: 0.0.0.0@53


  # port to answer queries from
    port: 53

  # Enable IPv4, "yes" or "no".
    do-ip4: yes

  # Enable IPv6, "yes" or "no".
    do-ip6: no

  # Enable UDP, "yes" or "no".
    do-udp: yes

  # Enable TCP, "yes" or "no". If TCP is not needed, Unbound is actually
  # quicker to resolve as the functions related to TCP checks are not done.i
  # NOTE: you may need tcp enabled to get the DNSSEC results from *.edu domains
  # due to their size.
    do-tcp: yes

  # control which client ips are allowed to make (recursive) queries to this
  # server. Specify classless netblocks with /size and action.  By default
  # everything is refused, except for localhost.  Choose deny (drop message),
  # refuse (polite error reply), allow (recursive ok), allow_snoop (recursive
  # and nonrecursive ok)
    access-control: 10.0.0.0/16 allow
    access-control: 127.0.0.0/8 allow
    access-control: 192.168.0.0/16 allow
    access-control: 192.168.178.0/24 allow

  # Read  the  root  hints from this file. Default is nothing, using built in
  # hints for the IN class. The file has the format of  zone files,  with  root
  # nameserver  names  and  addresses  only. The default may become outdated,
  # when servers change,  therefore  it is good practice to use a root-hints
  # file.  get one from ftp://FTP.INTERNIC.NET/domain/named.cache
    root-hints: "root.hints"
                 
  # enable to not answer id.server and hostname.bind queries.
    hide-identity: yes

  # enable to not answer version.server and version.bind queries.
    hide-version: yes

  # Will trust glue only if it is within the servers authority.
  # Harden against out of zone rrsets, to avoid spoofing attempts. 
  # Hardening queries multiple name servers for the same data to make
  # spoofing significantly harder and does not mandate dnssec.
    harden-glue: yes

  # Require DNSSEC data for trust-anchored zones, if such data is absent, the
  # zone becomes  bogus.  Harden against receiving dnssec-stripped data. If you
  # turn it off, failing to validate dnskey data for a trustanchor will trigger
  # insecure mode for that zone (like without a trustanchor).  Default on,
  # which insists on dnssec data for trust-anchored zones.
    harden-dnssec-stripped: yes

  # Use 0x20-encoded random bits in the query to foil spoof attempts.
  # http://tools.ietf.org/html/draft-vixie-dnsext-dns0x20-00
  # While upper and lower case letters are allowed in domain names, no significance
  # is attached to the case. That is, two names with the same spelling but
  # different case are to be treated as if identical. This means calomel.org is the
  # same as CaLoMeL.Org which is the same as CALOMEL.ORG.
    use-caps-for-id: yes

  # the time to live (TTL) value lower bound, in seconds. Default 0.
  # If more than an hour could easily give trouble due to stale data.
    cache-min-ttl: 3600

  # the time to live (TTL) value cap for RRsets and messages in the
  # cache. Items are not cached for longer. In seconds.
    cache-max-ttl: 86400

  # perform prefetching of close to expired message cache entries.  If a client
  # requests the dns lookup and the TTL of the cached hostname is going to
  # expire in less than 10% of its TTL, unbound will (1st) return the ip of the
  # host to the client and (2nd) pre-fetch the dns request from the remote dns
  # server. This method has been shown to increase the amount of cached hits by
  # local clients by 10% on average.
    prefetch: yes

  # number of threads to create. 1 disables threading. This should equal the number
  # of CPU cores in the machine. Our example machine has 4 CPU cores.
   # num-threads: 4
num-threads: @THREADS@

  ## Unbound Optimization and Speed Tweaks ###

  # the number of slabs to use for cache and must be a power of 2 times the
  # number of num-threads set above. more slabs reduce lock contention, but
  # fragment memory usage.
    msg-cache-slabs: 8
    rrset-cache-slabs: 8
    infra-cache-slabs: 8
    key-cache-slabs: 8

  # Increase the memory size of the cache. Use roughly twice as much rrset cache
  # memory as you use msg cache memory. Due to malloc overhead, the total memory
  # usage is likely to rise to double (or 2.5x) the total cache memory. The test
  # box has 4gig of ram so 256meg for rrset allows a lot of room for cacheed objects.
  #  rrset-cache-size: 256m
  #  msg-cache-size: 128m
  msg-cache-size: @MSG_CACHE_SIZE@
  rrset-cache-size: @RR_CACHE_SIZE@

  # buffer size for UDP port 53 incoming (SO_RCVBUF socket option). This sets
  # the kernel buffer larger so that no messages are lost in spikes in the traffic.
  #  so-rcvbuf: 1m
so-rcvbuf: 425984
  ## Unbound Optimization and Speed Tweaks ###


  # Enforce privacy of these addresses. Strips them away from answers.  It may
  # cause DNSSEC validation to additionally mark it as bogus.  Protects against
  # 'DNS Rebinding' (uses browser as network proxy).  Only 'private-domain' and
  # 'local-data' names are allowed to have these private addresses. No default.
    private-address: 192.168.0.0/16
    private-address: 172.16.0.0/12
    private-address: 10.0.0.0/8

  # Allow the domain (and its subdomains) to contain private addresses.
  # local-data statements are allowed to contain private addresses too.
    private-domain: "home.lan"

  # If nonzero, unwanted replies are not only reported in statistics, but also
  # a running total is kept per thread. If it reaches the threshold, a warning
  # is printed and a defensive action is taken, the cache is cleared to flush
  # potential poison out of it.  A suggested value is 10000000, the default is
  # 0 (turned off). We think 10K is a good value.
    unwanted-reply-threshold: 10000

  # IMPORTANT FOR TESTING: If you are testing and setup NSD or BIND  on
  # localhost you will want to allow the resolver to send queries to localhost.
  # Make sure to set do-not-query-localhost: yes . If yes, the above default
  # do-not-query-address entries are present.  if no, localhost can be queried
  # (for testing and debugging). 
    do-not-query-localhost: no

  # File with trusted keys, kept up to date using RFC5011 probes, initial file
  # like trust-anchor-file, then it stores metadata.  Use several entries, one
  # per domain name, to track multiple zones. If you use forward-zone below to
  # query the Google DNS servers you MUST comment out this option or all DNS
  # queries will fail.
  # auto-trust-anchor-file: "/var/unbound/etc/root.key"

  # Should additional section of secure message also be kept clean of unsecure
  # data. Useful to shield the users of this validator from potential bogus
  # data in the additional section. All unsigned data in the additional section
  # is removed from secure messages.
    val-clean-additional: yes

  # Blocking Ad Server domains. Google's AdSense, DoubleClick and Yahoo
  # account for a 70 percent share of all advertising traffic. Block them.
  # local-zone: "doubleclick.net" redirect
  # local-data: "doubleclick.net A 127.0.0.1"
  # local-zone: "googlesyndication.com" redirect
  # local-data: "googlesyndication.com A 127.0.0.1"
  # local-zone: "googleadservices.com" redirect
  # local-data: "googleadservices.com A 127.0.0.1"
  # local-zone: "google-analytics.com" redirect
  # local-data: "google-analytics.com A 127.0.0.1"
  # local-zone: "ads.youtube.com" redirect
  # local-data: "ads.youtube.com A 127.0.0.1"
  # local-zone: "adserver.yahoo.com" redirect
  # local-data: "adserver.yahoo.com A 127.0.0.1"
  # local-zone: "ask.com" redirect
  # local-data: "ask.com A 127.0.0.1"


  # Unbound will not load if you specify the same local-zone and local-data
  # servers in the main configuration as well as in this "include:" file. We
  # suggest commenting out any of the local-zone and local-data lines above if
  # you suspect they could be included in the unbound_ad_servers servers file.
  #include: "/etc/unbound/unbound_ad_servers"

  # locally served zones can be configured for the machines on the LAN.

    local-zone: "home.lan." static

    local-data: "firewall.home.lan.  IN A 10.0.0.1"
    local-data: "laptop.home.lan.    IN A 10.0.0.2"
    local-data: "xboxone.home.lan.   IN A 10.0.0.3"
    local-data: "ps4.home.lan.       IN A 10.0.0.4"
    local-data: "dhcp5.home.lan.     IN A 10.0.0.5"
    local-data: "dhcp6.home.lan.     IN A 10.0.0.6"
    local-data: "dhcp7.home.lan.     IN A 10.0.0.7"

    local-data-ptr: "10.0.0.1  firewall.home.lan"
    local-data-ptr: "10.0.0.2  laptop.home.lan"
    local-data-ptr: "10.0.0.3  xboxone.home.lan"
    local-data-ptr: "10.0.0.4  ps4.home.lan"
    local-data-ptr: "10.0.0.5  dhcp5.home.lan"
    local-data-ptr: "10.0.0.6  dhcp6.home.lan"
    local-data-ptr: "10.0.0.7  dhcp7.home.lan"

  # Unbound can query your NSD or BIND server for private domain queries too.
  # On our NSD page we have NSD configured to serve the private domain,
  # "home.lan". Here we can tell Unbound to connect to the NSD server when it
  # needs to resolve a *.home.lan hostname or IP.
  #
  # private-domain: "fritz.box"
  # local-zone: "178.168.192.in-addr.arpa." nodefault
  # stub-zone:
  #      name: "fritz.box"
  #      stub-addr: 192.168.178.1@53

  # If you have an internal or private DNS names the external DNS servers can
  # not resolve, then you can assign domain name strings to be redirected to a
  # seperate dns server. For example, our comapny has the domain
  # organization.com and the domain name internal.organization.com can not be
  # resolved by Google's public DNS, but can be resolved by our private DNS
  # server located at 1.1.1.1. The following tells Unbound that any
  # organization.com domain, i.e. *.organization.com be dns resolved by 1.1.1.1
  # instead of the public dns servers.
  #
  # forward-zone:
  #    name: "fritz.box"
  #    forward-addr: 192.168.178.1        # Internal or private DNS

  # Use the following forward-zone to forward all queries to Google DNS,
  # OpenDNS.com or your local ISP's dns servers for example. To test resolution
  # speeds use "drill calomel.org @8.8.8.8" and look for the "Query time:" in
  # milliseconds.
  #

 include: /opt/unbound/etc/unbound/a-records.conf

   forward-zone:
      name: "."
      forward-addr: 8.8.4.4        # Google
      forward-addr: 8.8.8.8        # Google
      forward-addr: 37.235.1.174   # FreeDNS
      forward-addr: 37.235.1.177   # FreeDNS
      forward-addr: 50.116.23.211  # OpenNIC
      forward-addr: 64.6.64.6      # Verisign
      forward-addr: 64.6.65.6      # Verisign
      forward-addr: 74.82.42.42    # Hurricane Electric
      forward-addr: 84.200.69.80   # DNS Watch
      forward-addr: 84.200.70.40   # DNS Watch
      forward-addr: 91.239.100.100 # censurfridns.dk
      forward-addr: 109.69.8.51    # puntCAT
      forward-addr: 208.67.222.220 # OpenDNS
      forward-addr: 208.67.222.222 # OpenDNS
      forward-addr: 216.146.35.35  # Dyn Public
      forward-addr: 216.146.36.36  # Dyn Public



remote-control:
        control-enable: yes
        #control-interface: 0.0.0.0
        control-interface: 127.0.0.1
        #TODO check is IP6 working
        #control-interface: ::1
        control-port: 8953
        server-key-file: "/opt/unbound/etc/unbound/unbound_server.key"
        server-cert-file: "/opt/unbound/etc/unbound/unbound_server.pem"
        control-key-file: "/opt/unbound/etc/unbound/unbound_control.key"
        control-cert-file: "/opt/unbound/etc/unbound/unbound_control.pem"
#
#
## Authoritative, validating, recursive caching DNS
## unbound.conf -- https://calomel.org
EOT

#TODO AUTO ADD locaclnaet to access-control

mkdir -p /opt/unbound/etc/unbound/dev &&
	cp -a /dev/random /dev/urandom /opt/unbound/etc/unbound/dev/

mkdir -p -m 700 /opt/unbound/etc/unbound/var &&
	chown _unbound:_unbound /opt/unbound/etc/unbound/var &&
	/opt/unbound/sbin/unbound-anchor -a /opt/unbound/etc/unbound/var/root.key

#old exec /opt/unbound/sbin/unbound -d -c /opt/unbound/etc/unbound/unbound.conf


if /opt/unbound/sbin/unbound-checkconf /opt/unbound/etc/unbound/unbound.conf | grep -q  "unbound-checkconf: no errors in" ; then
/opt/unbound/sbin/unbound-checkconf /opt/unbound/etc/unbound/unbound.conf
/opt/unbound/sbin/unbound -d -c /opt/unbound/etc/unbound/unbound.conf &
echo "start tail -f "
tail -f /opt/unbound/etc/unbound/unbound.log
else
echo "Error in unbound config"
/opt/unbound/sbin/unbound-checkconf /opt/unbound/etc/unbound/unbound.conf
fi
