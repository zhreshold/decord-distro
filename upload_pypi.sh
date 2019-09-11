#!/bin/bash

function twine_upload {
    if [ -n "$IS_OSX" ]; then
      echo "Installing twine for OS X"
      pip install twine
      pip install --upgrade pyOpenSSL
    else
      echo "Installing twine for linux"
      pip install --user twine
      pip install --user --upgrade six
    fi
    echo "Uploading"
    twine upload -u ${PYPIUSER} -p ${PYPIPASS} --skip-existing ${TRAVIS_BUILD_DIR}/wheelhouse/decord*
}