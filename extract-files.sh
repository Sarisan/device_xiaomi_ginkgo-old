#!/bin/bash
#
# Copyright (C) 2018-2019 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#

set -e

DEVICE=ginkgo
VENDOR=xiaomi

# Load extract_utils and do some sanity checks
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

HAVOC_ROOT="${MY_DIR}"/../../..

HELPER="${HAVOC_ROOT}/vendor/havoc/build/tools/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Unable to find helper script at ${HELPER}"
    exit 1
fi
source "${HELPER}"

# Default to sanitizing the vendor folder before extraction
CLEAN_VENDOR=true

SECTION=
KANG=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        -n | --no-cleanup )
                CLEAN_VENDOR=false
                ;;
        -k | --kang )
                KANG="--kang"
                ;;
        -s | --section )
                SECTION="${2}"; shift
                CLEAN_VENDOR=false
                ;;
        * )
                SRC="${1}"
                ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
    vendor/bin/mlipayd@1.1 | vendor/lib64/libmlipay.so | vendor/lib64/libmlipay@1.1.so)
        patchelf --remove-needed "vendor.xiaomi.hardware.mtdservice@1.0.so" "${2}"
        ;;
    vendor/etc/camera/camera_config.xml)
        # Remove vtcamera for ginkgo
        gawk -i inplace '{ p = 1 } /<CameraModuleConfig>/{ t = $0; while (getline > 0) { t = t ORS $0; if (/ginkgo_vtcamera/) p = 0; if (/<\/CameraModuleConfig>/) break } $0 = t } p' "${2}"
        ;;
    esac
}

# Initialize the helper
setup_vendor "${DEVICE}" "${VENDOR}" "${HAVOC_ROOT}" true "${CLEAN_VENDOR}"

extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        "${KANG}" --section "${SECTION}"

BLOB_ROOT="${HAVOC_ROOT}/vendor/${VENDOR}/${DEVICE}/proprietary"

find $BLOB_ROOT -type f | xargs sed -i "s/android.hidl.base@1.0.so/libhidlbase.so\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00/g"

sed -i "s/ginkgo_s5kgm1_sunny_i/ginkgo_s5kgm1_ofilm_ii/g" "${BLOB_ROOT}/vendor/etc/camera/ginkgo_s5kgm1_sunny_i_chromatix.xml"
sed -i "s/ginkgo_s5kgm1_ofilm_ii_common/ginkgo_s5kgm1_sunny_i_common/g" "${BLOB_ROOT}/vendor/etc/camera/ginkgo_s5kgm1_sunny_i_chromatix.xml"
sed -i "s/ginkgo_s5kgm1_ofilm_ii_postproc/ginkgo_s5kgm1_sunny_i_postproc/g" "${BLOB_ROOT}/vendor/etc/camera/ginkgo_s5kgm1_sunny_i_chromatix.xml"

"${MY_DIR}/setup-makefiles.sh"
