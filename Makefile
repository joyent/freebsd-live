#
# Project Variables
#
ROOT = ${PWD}
BUILD_DIR ?= ${ROOT}/build
PROJECT_DIR = ${ROOT}/projects
IMAGES_DIR = ${ROOT}/images
BIN_DIR = ${ROOT}/bin
CONF_DIR = ${ROOT}/conf
CDROM_DIR = ${ROOT}/cdrom
NUM_JOBS ?= `sysctl -n hw.ncpu`

#
# FreeBSD Build Variables
#
KERNEL ?= BHYVE-NODEBUG

#
# mfsBSD Build Variables
#
MFSBSD_BASE=${ROOT}/cdrom/usr/freebsd-dist
#MFSBSD_MFSROOT_MAXSIZE=300m
MFSBSD_MFSROOT_MAXSIZE=256m
MFSBSD_MFSROOT_FREE_INODES=20%
MFSBSD_MFSROOT_FREE_BLOCKS=20%
MFSBSD_IMAGE_PREFIX='Joyent-FreeBSD'

all: freebsd-live

freebsd: ${ROOT}/.freebsd_done
${ROOT}/.freebsd_done:
	@echo "==================== Building FreeBSD World ===================="
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -DNO_CLEAN -j ${NUM_JOBS} buildworld KERNCONF=${KERNEL})
	@echo "==================== Building FreeBSD Kernel  ===================="
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -DNO_CLEAN -j ${NUM_JOBS} buildkernel KERNCONF=${KERNEL})
	touch ${ROOT}/.freebsd_done

freebsd-release: freebsd ${ROOT}/.freebsd-release_done
${ROOT}/.freebsd-release_done:
	(cd ${PROJECT_DIR}/freebsd/release; env MAKEOBJDIRPREFIX=${BUILD_DIR} make dvdrom KERNCONF=${KERNEL} KERNEL=${KERNEL})
	mv ${BUILD_DIR}${PROJECT_DIR}/freebsd/amd64.amd64/release/dvd1.iso ${IMAGES_DIR}/
	touch ${ROOT}/.freebsd-release_done

umount_dvdrom:
	@echo "==================== UnMounting FreeBSD Image  ===================="
	umount /dev/md10 || exit 0
	mdconfig -d -u 10 || exit 0

mount_dvdrom: umount_dvdrom
	@echo "==================== Mounting FreeBSD Image  ===================="
	mdconfig -a -t vnode -u 10 -f ${IMAGES_DIR}/dvd1.iso
	mount_cd9660 /dev/md10 ${CDROM_DIR}

mfsbsd: mount_dvdrom
	@echo "==================== Cleaning mfsBSD ===================="
	(cd ${PROJECT_DIR}/mfsbsd; mkdir -p tmp; make clean)
	date +%Y%m%dT%H%M%SZ > ${PROJECT_DIR}/mfsbsd/customfiles/etc/buildstamp
	@echo "==================== Building mfsBSD USB image ===================="
	(cd ${PROJECT_DIR}/mfsbsd; make BASE=${MFSBSD_BASE} KERNCONF=${KERNEL} PKG_STATIC=${BIN_DIR}/pkg-static MFSROOT_MAXSIZE=${MFSBSD_MFSROOT_MAXSIZE} MFSROOT_FREE_INODES=${MFSBSD_MFSROOT_FREE_INODES} MFSROOT_FREE_BLOCKS=${MFSBSD_MFSROOT_FREE_BLOCKS} IMAGE_PREFIX=${MFSBSD_IMAGE_PREFIX})
	@echo "==================== Building mfsBSD iso ===================="
	(cd ${PROJECT_DIR}/mfsbsd; make iso BASE=${MFSBSD_BASE} KERNCONF=${KERNEL} PKG_STATIC=${BIN_DIR}/pkg-static MFSROOT_MAXSIZE=${MFSBSD_MFSROOT_MAXSIZE} MFSROOT_FREE_INODES=${MFSBSD_MFSROOT_FREE_INODES} MFSROOT_FREE_BLOCKS=${MFSBSD_MFSROOT_FREE_BLOCKS} IMAGE_PREFIX=${MFSBSD_IMAGE_PREFIX})
	mv ${PROJECT_DIR}/mfsbsd/${MFSBSD_IMAGE_PREFIX}-`uname -r`-`sysctl -n hw.machine_arch`.img images/${MFSBSD_IMAGE_PREFIX}-`uname -r`-`sysctl -n hw.machine_arch`-`cat ${PROJECT_DIR}/mfsbsd/customfiles/etc/buildstamp`.img
	mv ${PROJECT_DIR}/mfsbsd/${MFSBSD_IMAGE_PREFIX}-`uname -r`-`sysctl -n hw.machine_arch`.iso images/${MFSBSD_IMAGE_PREFIX}-`uname -r`-`sysctl -n hw.machine_arch`-`cat ${PROJECT_DIR}/mfsbsd/customfiles/etc/buildstamp`.iso

update:
	(cd ${PROJECT_DIR}/mfsbsd; git pull --rebase)
	(cd ${PROJECT_DIR}/freebsd; git pull --rebase)

freebsd-live: freebsd freebsd-release mfsbsd

#
# For Manual Installation of a Build Machine
#
freebsd-install:
	@echo "==================== Installing FreeBSD Kernel  ===================="
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -DNO_CLEAN -j ${NUM_JOBS} installkernel KERNCONF=${KERNEL})

freebsd-world-install:
	@echo "==================== Installing FreeBSD World  ===================="
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} mergemaster -p -m ${PROJECT_DIR}/freebsd)
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -DNO_CLEAN -j ${NUM_JOBS} installworld KERNCONF=${KERNEL})
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} mergemaster -iUF -m ${PROJECT_DIR}/freebsd)


clean:
	rm ${ROOT}/.freebsd_done ${ROOT}/.freebsd-release_done
