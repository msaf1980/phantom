#!/bin/bash

NAME=phantom

die() {
    if [[ $1 -eq 0 ]]; then
        rm -rf "${TMPDIR}"
    else
        [ "${TMPDIR}" = "" ] || echo "Temporary data stored at '${TMPDIR}'"
    fi
    echo "$2"
    exit $1
}

pwd

GIT_VERSION="$(git describe --always --tags | sed -e 's/^v//')" || die 1 "Can't get latest version from git"

set -f; IFS='-' ; arr=($GIT_VERSION)
VERSION=${arr[0]}; [ -z "${arr[2]}" ] && RELEASE=${arr[1]} || RELEASE=${arr[1]}.${arr[2]}
set +f; unset IFS

[ "${VERSION}" = "" ] && {
	echo "Revision: ${RELEASE}";
	echo "Version: ${VERSION}";
	echo
	echo "Known tags:"
	git tag
	echo;
	die 1 "Can't parse version from git";
}

[ "${RELEASE}" = "" ] && RELEASE="0"

make -R || die 1 "Build error"

TMPDIR=$(mktemp -d)
[ "${TMPDIR}" = "" ] && die 1 "Can't create temp dir"
echo version ${VERSION} release ${RELEASE}
mkdir -p "${TMPDIR}/usr/bin" || die 1 "Can't create bin dir"
mkdir -p "${TMPDIR}/usr/share/doc/${NAME}" || die 1 "Can't create share dir"
cp -r ./bin/${NAME} "${TMPDIR}/usr/bin/" || die 1 "Can't install package binary"
cp -r ./lib/${NAME} "${TMPDIR}/usr/lib/" || die 1 "Can't install package lib"
cp -r ./examples "${TMPDIR}/usr/share/doc/${NAME}" || die 1 "Can't install package shared files"
# RPM Specific
#

fpm -s dir -t rpm -n ${NAME} -v ${VERSION} -C ${TMPDIR} \
    --iteration ${RELEASE} \
    -p ${NAME}-VERSION-ITERATION.ARCH.rpm \
    --description "phantom: Yandex Tank I/O engine" \
    --license BSD-2 \
    --url "https://github.com/yandex-load/phantom" \
    "${@}" \
    usr/bin usr/lib usr/share || die 1 "Can't create package!"

die 0 "Success"
