# vim: ft=conf

# debugging
# debug-level guru
# log-file /tmp/scdaemon.log

card-timeout 5
disable-ccid
# dynamically replaced to the system libpcsclite by `rcm/hooks/post-up`
pcsc-driver PCSC_DRIVER
# pcsc-shared
