#!/usr/bin/env bash
# shellcheck disable=SC2034,SC1091,SC2154

set -vx

######################################################################################################################
### Setup Build System and GitHub

##apt install -y autopoint

wget -qO- uny.nu/pkg | bash -s buildsys

### Installing build dependencies
unyp install openssl systemd

#pip3_bin=(/uny/pkg/python/*/bin/pip3)
#"${pip3_bin[0]}" install --upgrade pip
#"${pip3_bin[0]}" install docutils pygments

### Getting Variables from files
UNY_AUTO_PAT="$(cat UNY_AUTO_PAT)"
export UNY_AUTO_PAT
GH_TOKEN="$(cat GH_TOKEN)"
export GH_TOKEN

source /uny/git/unypkg/fn
uny_auto_github_conf

######################################################################################################################
### Timestamp & Download

uny_build_date

mkdir -pv /uny/sources
cd /uny/sources || exit

pkgname="valkey"
pkggit="https://github.com/valkey-io/valkey.git refs/tags/*"
gitdepth="--depth=1"

### Get version info from git remote
# shellcheck disable=SC2086
latest_head="$(git ls-remote --refs --tags --sort="v:refname" $pkggit | grep -E "/[0-9.]+$" | tail --lines=1)"
latest_ver="$(echo "$latest_head" | grep -o "/[0-9.].*" | sed "s|/||")"
latest_commit_id="$(echo "$latest_head" | cut --fields=1)"

version_details

# Release package no matter what:
echo "newer" >release-"$pkgname"

git_clone_source_repo

#cd "$pkg_git_repo_dir" || exit
#./autogen.sh
#cd /uny/sources || exit

archiving_source

######################################################################################################################
### Build

# unyc - run commands in uny's chroot environment
# shellcheck disable=SC2154
unyc <<"UNYEOF"
set -vx
source /uny/git/unypkg/fn

pkgname="valkey"

version_verbose_log_clean_unpack_cd
get_env_var_values
get_include_paths

####################################################
### Start of individual build script

unset LD_RUN_PATH

export CFLAGS=""
export CXXFLAGS="${CFLAGS}"

make PREFIX=/uny/pkg/"$pkgname"/"$pkgver" USE_SYSTEMD=yes MALLOC=jemalloc BUILD_TLS=yes -j"$(nproc)"
make -j"$(nproc)" test
make PREFIX=/uny/pkg/"$pkgname"/"$pkgver" -j"$(nproc)" install

cp -a utils /uny/pkg/"$pkgname"/"$pkgver"
sed "s|/usr/local|/uny/pkg/"$pkgname"/"$pkgver"|g" -i /uny/pkg/"$pkgname"/"$pkgver"/utils/systemd-valkey_server.service
sed -e '/^\[Service\]/a\' -e 'RuntimeDirectory=valkey' -i /uny/pkg/"$pkgname"/"$pkgver"/utils/systemd-valkey_server.service
sed "s|/usr/local|/uny/pkg/"$pkgname"/"$pkgver"|g" -i /uny/pkg/"$pkgname"/"$pkgver"/utils/systemd-valkey_multiple_servers@.service

mkdir /uny/pkg/"$pkgname"/"$pkgver"/etc
cp -a valkey.conf /uny/pkg/"$pkgname"/"$pkgver"/etc/
sed "s|# supervised auto|supervised auto|" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf
sed "s|dir ./|dir /var/lib/valkey|" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf
sed "s|/run/|/run/valkey/|g" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf
sed "s|^pidfile.*|pidfile /run/valkey/valkey.pid|" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf
sed "s|# unixsocket .*|unixsocket /run/valkey/valkey.sock|" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf
sed "s|# unixsocketperm .*|unixsocketperm 770|" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf
sed "s|# unixsocketgroup .*|unixsocketgroup unyweb|" -i /uny/pkg/"$pkgname"/"$pkgver"/etc/valkey.conf

####################################################
### End of individual build script

add_to_paths_files
dependencies_file_and_unset_vars
cleanup_verbose_off_timing_end
UNYEOF

######################################################################################################################
### Packaging

package_unypkg
