echo "delete all iptables rules"
echo "resart docker service"
echo "start unbound"
./clean-iptables.sh  && \
service docker restart && \
./run.sh