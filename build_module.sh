#!/bin/bash

set -euo pipefail

INSTDIR=$1
FORCE_CLEAN=$2
CMAKE_BUILD_TYPE=$3
EDITABLE_PY_INSTALL=$4

if [[ "${FORCE_CLEAN}" == "TRUE" ]]; then
    if [ -d build ]; then
        rm -rf build
    fi
fi

if [[ "${EDITABLE_PY_INSTALL}" == "TRUE" ]]; then
    PIP_OPTIONS="--editable"
    #python setup.py build_ext --inplace
else
    PIP_OPTIONS=""
fi

mkdir -p build
cd build
cmake -DCMAKE_INSTALL_PREFIX="${INSTDIR}" -DCMAKE_PREFIX_PATH="${CONDA_PREFIX}" -DCMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE}" ..
make -j 4 install
cd ..

pip install --no-deps --prefix="${INSTDIR}" "${PIP_OPTIONS}" .

FULL_PY_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
MAJMIN_PY_VERSION=$(cut -d '.' -f 1,2 <<< "${FULL_PY_VERSION}")
SITECUSTOMIZE_PATH="$INSTDIR/lib/python${MAJMIN_PY_VERSION}/site-packages/sitecustomize.py"

if [[ "${EDITABLE_PY_INSTALL}" == "TRUE" && ! -f "${SITECUSTOMIZE_PATH}" ]]; then
    cat << EOF > "${SITECUSTOMIZE_PATH}"
import site

site.addsitedir('${INSTDIR}/lib/python${MAJMIN_PY_VERSION}/site-packages')
EOF
fi
