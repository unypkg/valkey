#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154,SC1003,SC2005

current_dir="$(pwd)"
unypkg_script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
unypkg_root_dir="$(cd -- "$unypkg_script_dir"/.. &>/dev/null && pwd)"

cd "$unypkg_root_dir" || exit

#############################################################################################
### Start of script

mkdir -pv /etc/uny/valkey
cp -a etc/valkey.conf /etc/uny/valkey/

mkdir -pv /var/lib/valkey
mkdir -pv /var/log/valkey

cp -a utils/systemd-valkey_server.service /etc/systemd/system/uny-valkey-server.service
sed "s|--supervised systemd --daemonize no|/etc/uny/valkey/valkey.conf|" -i /etc/systemd/system/uny-valkey-server.service
sed -e '/\[Install\]/a\' -e 'Alias=valkey-server.service valkey.service' -i /etc/systemd/system/uny-valkey-server.service
systemctl daemon-reload

#############################################################################################
### End of script

cd "$current_dir" || exit
