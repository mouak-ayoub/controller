# To allow wireshark, say in windows, to connect to the server, we need to grant specific capabilities to the tcpdump binary.
# /usr/sbin/tcpdump is the result of the command "$(which tcpdump)"
sudo setcap cap_net_raw,cap_net_admin=eip "$(which tcpdump)"