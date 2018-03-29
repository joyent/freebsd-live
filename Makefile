#
# Project Variables
#
DATE != date +%Y%m%dT%H%M%SZ
ROOT = ${PWD}
BUILD_DIR ?= ${ROOT}/build
PROJECT_DIR = ${ROOT}/projects
IMAGES_DIR ?= ${ROOT}/images
BIN_DIR = ${ROOT}/bin
CONF_DIR = ${ROOT}/conf
NUM_JOBS ?= `sysctl -n hw.ncpu`

#
# FreeBSD Build Variables
#
KERNEL ?= BHYVE-NODEBUG

#
# mfsBSD Build Variables
#
MFSBSD_MFSROOT_MAXSIZE=512m
MFSBSD_MFSROOT_FREE_INODES=20%
MFSBSD_MFSROOT_FREE_BLOCKS=20%
MFSBSD_IMAGE_PREFIX=Joyent-FreeBSD

all: freebsd-live

freebsd: freebsd-world freebsd-kernel

freebsd-world: ${ROOT}/.freebsd-world_done
${ROOT}/.freebsd-world_done:
	@echo "==================== Building FreeBSD World ===================="
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -j ${NUM_JOBS} buildworld KERNCONF=${KERNEL})
	touch ${ROOT}/.freebsd-world_done

freebsd-kernel: freebsd-world ${ROOT}/.freebsd-kernel_done
${ROOT}/.freebsd-kernel_done:
	@echo "==================== Building FreeBSD Kernel  ===================="
	(cd ${PROJECT_DIR}/freebsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -j ${NUM_JOBS} buildkernel KERNCONF=${KERNEL})
	touch ${ROOT}/.freebsd-kernel_done

mfsbsd:
	@echo "==================== Cleaning mfsBSD ===================="
	(cd ${PROJECT_DIR}/mfsbsd; mkdir -p tmp; make clean)
	echo "${DATE}" > ${PROJECT_DIR}/mfsbsd/customfiles/etc/buildstamp
	@echo "==================== Building mfsBSD USB image ===================="
	(cd ${PROJECT_DIR}/mfsbsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make -DDEBUG CUSTOM=1 SRC_DIR=${PROJECT_DIR}/freebsd KERNCONF=${KERNEL} PKG_STATIC=${BIN_DIR}/pkg-static MFSROOT_MAXSIZE=${MFSBSD_MFSROOT_MAXSIZE} MFSROOT_FREE_INODES=${MFSBSD_MFSROOT_FREE_INODES} MFSROOT_FREE_BLOCKS=${MFSBSD_MFSROOT_FREE_BLOCKS} IMAGE_PREFIX=${MFSBSD_IMAGE_PREFIX})
	@echo "==================== Building mfsBSD iso ===================="
	(cd ${PROJECT_DIR}/mfsbsd; env SRCCONF=${CONF_DIR}/src.conf MAKEOBJDIRPREFIX=${BUILD_DIR} make iso -DDEBUG CUSTOM=1 SRC_DIR=${PROJECT_DIR}/freebsd KERNCONF=${KERNEL} PKG_STATIC=${BIN_DIR}/pkg-static MFSROOT_MAXSIZE=${MFSBSD_MFSROOT_MAXSIZE} MFSROOT_FREE_INODES=${MFSBSD_MFSROOT_FREE_INODES} MFSROOT_FREE_BLOCKS=${MFSBSD_MFSROOT_FREE_BLOCKS} IMAGE_PREFIX=${MFSBSD_IMAGE_PREFIX})
	@echo "==================== Moving to images_dir  ===================="
	mv -v ${PROJECT_DIR}/mfsbsd/*.img ${IMAGES_DIR}/
	mv -v ${PROJECT_DIR}/mfsbsd/*.iso ${IMAGES_DIR}/

update:
	(cd ${PROJECT_DIR}/mfsbsd; git pull --rebase)
	(cd ${PROJECT_DIR}/freebsd; git pull --rebase)

freebsd-live: freebsd mfsbsd

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
	(cd build; chflags -f -R noschg *; rm -rf *) || true
	(rm -f ${ROOT}/.freebsd-kernel_done ${ROOT}/.freebsd-world_done)
clean-kernel:
	(rm -f ${ROOT}/.freebsd-kernel_done)

