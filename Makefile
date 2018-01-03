#
# Project Variables
#
ROOT = ${PWD}
BUILD_DIR ?= ${ROOT}/build
PROJECT_DIR = ${ROOT}/projects
IMAGES_DIR = ${ROOT}/images
BIN_DIR = ${ROOT}/bin
NUM_JOBS ?= `sysctl -n hw.ncpu`

#
# FreeBSD Build Variables
#
KERNEL ?= BHYVE-NODEBUG

#
# mfsBSD Build Variables
#
MFSBSD_BASE=/cdrom/usr/freebsd-dist
MFSBSD_MFSROOT_MAXSIZE=256m
MFSBSD_MFSROOT_FREE_INODES=20%
MFSBSD_MFSROOT_FREE_BLOCKS=20%
MFSBSD_IMAGE_PREFIX='Joyent-FreeBSD'

freebsd:
	echo "==================== Building FreeBSD World ===================="
	(cd ${PROJECT_DIR}/freebsd; MAKEOBJDIRPREFIX=${BUILD_DIR} make -DNO_CLEAN -j ${NUM_JOBS} buildworld KERNCONF=${KERNEL})
	echo "==================== Building FreeBSD Kernel  ===================="
	(cd ${PROJECT_DIR}/freebsd; MAKEOBJDIRPREFIX=${BUILD_DIR} make -DNO_CLEAN -j ${NUM_JOBS} buildkernel KERNCONF=${KERNEL})
	cp ${BUILD_DIR}/root/src/freebsd-live/projects/freebsd/amd64.amd64/release/dvd1.iso ${IMAGES_DIR}

mount_dvdrom:
	echo "==================== Mounting FreeBSD Image  ===================="
	mdconfig -a -t vnode -u 10 -f ${IMAGES_DIR}/dvd1.iso
	mkdir /cdrom; mount_cd9660 /dev/md10 /cdrom

mfsbsd:
	echo "==================== Building mfsBSD USB image ===================="
	(cd ${PROJECT_DIR}/mfsbsd; make BASE=${MFSBSD_BASE} KERNCONF=${KERNEL} PKG_STATIC=${BIN_DIR}/pkg-static MFSROOT_MAXSIZE=${MFSBSD_MFSROOT_MAXSIZE} MFSROOT_FREE_INODES=${MFSBSD_MFSROOT_FREE_INODES} MFSROOT_FREE_BLOCKS=${MFSBSD_MFSROOT_FREE_BLOCKS} IMAGE_PREFIX=${MFSBSD_IMAGE_PREFIX})
	echo "==================== Building mfsBSD iso ===================="
	(cd ${PROJECT_DIR}/mfsbsd; make iso BASE=${MFSBSD_BASE} KERNCONF=${KERNEL} PKG_STATIC=${BIN_DIR}/pkg-static MFSROOT_MAXSIZE=${MFSBSD_MFSROOT_MAXSIZE} MFSROOT_FREE_INODES=${MFSBSD_MFSROOT_FREE_INODES} MFSROOT_FREE_BLOCKS=${MFSBSD_MFSROOT_FREE_BLOCKS} IMAGE_PREFIX=${MFSBSD_IMAGE_PREFIX})
