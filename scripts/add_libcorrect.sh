#!/bin/bash

set -e

mkdir -p /opt/code
cd /opt/code
git clone https://github.com/fullaxx/libcorrect.git
rm -rf libcorrect/.git
tar cvf libcorrect.tar libcorrect
gzip libcorrect.tar
cd libcorrect

# Why do I have to do this manually??
cp -av include/correct /usr/local/include/

mkdir build
cd build
cmake ..
make shim
make install
cd /opt/code
rm -rf libcorrect
ldconfig

exit 0

# Filesystem Layout
/usr/local/
|-- include
|   |-- correct
|   |   |-- convolutional
|   |   |   |-- bit.h
|   |   |   |-- convolutional.h
|   |   |   |-- error_buffer.h
|   |   |   |-- history_buffer.h
|   |   |   |-- lookup.h
|   |   |   |-- metric.h
|   |   |   `-- sse
|   |   |       |-- convolutional.h
|   |   |       `-- lookup.h
|   |   |-- convolutional.h
|   |   |-- portable.h
|   |   |-- reed-solomon
|   |   |   |-- decode.h
|   |   |   |-- encode.h
|   |   |   |-- field.h
|   |   |   |-- polynomial.h
|   |   |   `-- reed-solomon.h
|   |   |-- reed-solomon.h
|   |   `-- util
|   |       |-- error-sim-fec.h
|   |       |-- error-sim-shim.h
|   |       |-- error-sim-sse.h
|   |       `-- error-sim.h
|   |-- correct-sse.h
|   |-- correct.h
|   `-- fec.h (make shim)
|-- lib
|   |-- libcorrect.a
|   |-- libcorrect.so
|   |-- libfec.a  (make shim)
|   `-- libfec.so (make shim)
