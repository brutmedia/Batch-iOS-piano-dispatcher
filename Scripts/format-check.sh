#!/bin/bash

if [ `uname -s` == Linux ]; then
    SWIFTFORMAT=`which swiftformat`
else
    SWIFTFORMAT=`xcrun -find swiftformat`
fi

if [ ! -x "${SWIFTFORMAT}" ]; then
    echo "swiftformat is missing. On a mac, please install it using homebrew: brew install swiftformat. Skipping swift formatting."
fi

set -e

# Format Swift code
if [ -x "${SWIFTFORMAT}" ]; then
echo coucou
    ${SWIFTFORMAT} --lint Sources/BatchPianoDispatcher Tests/BatchPianoDispatcherTests
fi
