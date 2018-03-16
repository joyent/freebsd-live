# FreeBSD-live: FreeBSD Platform


## Requirements
OS: FreeBSD 12-CURRENT

## Quickstart
```
git clone https://github.com/joyent/freebsd-live.git
cd freebsd-live
./configure
make
```

WARNING: Normal users should use the image that quickstart generates under images.
To setup a build machine with the correct version of FreeBSD 12-CURRENT, you'll want these install instructions.

## Install
```
pkg install git
git clone https://github.com/joyent/freebsd-live.git
cd freebsd-live
./configure
make freebsd-world freebsd-kernel
make freebsd-install 
reboot
# [log back in]
cd freebsd-live
make freebsd-world-install
reboot
```
