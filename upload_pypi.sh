#!/bin/bash

if [[ "$TRAVIS_OS_NAME" == "linux" ]]; then
    pip install --user twine
    pip install --user --upgrade six
fi

if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    pip install twine
    pip install --upgrade pyOpenSSL
fi
echo "uploading"
twine upload -u ${PYPIUSER} -p ${PYPIPASS} --skip-existing ${TRAVIS_BUILD_DIR}/wheelhouse/decord*