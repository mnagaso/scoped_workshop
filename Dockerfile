# base image which includes intel mpi/conda/jupyterla
FROM ghcr.io/seisscoped/container-base:centos7_mpi

RUN yum install -y cmake3 boost-devel \
    && ln -s /bin/cmake3 /bin/cmake

# go to /home/scoped
WORKDIR /home/scoped

#CC=mpicc CXX=mpicxx FC=mpif90 \
# ./configure --enable-parallel --enable-unsupported --enable-shared --enable-static --enable-cxx --enable-fortran  --with-pic --prefix=/home/scoped/hdf5
#
# install HDF5 with parallel option (this uses gcc+intelmpi)
RUN wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.13/hdf5-1.13.3/src/hdf5-1.13.3.tar.gz
    #&& CC=mpicc CXX=mpicxx FC=mpif90 \
RUN source ${MPIVARS_SCRIPT} \
    && tar -xvf hdf5-1.13.3.tar.gz \
    && cd hdf5-1.13.3 \
    && CC=mpicc ./configure --enable-fortran --enable-parallel --prefix=/home/scoped/hdf5 --enable-shared --enable-static \
    && make -j12 && make install \
    && cd .. && rm -rf hdf5-*
#
# HDF5_DIR for pypaw
ENV HDF5_DIR=/home/scoped/hdf5
# add hdf5 bin to PATH
ENV PATH=$PATH:/home/scoped/hdf5/bin
# add hdf5 lib to LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/home/scoped/hdf5/lib
#
# install asdf-library
# workaround to use gfortran with intel mpi (not a good engineering practice)
RUN mv /opt/intel/compilers_and_libraries/linux/mpi/intel64/include/mpi.mod /opt/intel/compilers_and_libraries/linux/mpi/intel64/include/mpi.modbak \
    && ln -s /opt/intel/compilers_and_libraries/linux/mpi/intel64/include/gfortran/4.8.0/mpi.mod /opt/intel/compilers_and_libraries/linux/mpi/intel64/include

RUN git clone https://github.com/SeismicData/asdf-library.git \
    && cd asdf-library \
    && mkdir build && cd build \
    && cmake .. -DCMAKE_Fortran_COMPILER=h5pfc -DCMAKE_INSTALL_PREFIX=/home/scoped/asdf -DBUILD_DOCUMENTATION=False \
    && make && make install \
    && cd ../../ \
    && rm -rf asdf-library

# install ADIOS2
RUN git clone https://github.com/ornladios/ADIOS2.git && cd ADIOS2 \
    && mkdir build && cd build\
    && cmake .. -DCMAKE_INSTALL_PREFIX=/home/scoped/adios2 \
    && make -j4 && make install \
    && cd ../../ && rm -rf ADIOS2
ENV PATH=$PATH:/home/scoped/adios2/bin

# compile spefem3d_globe
RUN git clone --recursive --branch devel https://github.com/SPECFEM/specfem3d_globe.git \
    && cd specfem3d_globe \
    && ./configure --enable-vectorization \
        --with-adios2 ADIOS2_CONFIG=/home/scoped/adios2/bin/adios2-config \
        --with-asdf 'ASDF_LIBS=-L/home/scoped/asdf/lib64 -L/opt/intel/compilers_and_libraries/linux/mpi/intel64/lib/release/ -L/home/scoped/hdf5/lib' \
        MPIFC=mpif90 FC=gfortran CC=gcc \
        'FLAGS_CHECK=-O2 -mcmodel=medium -Wunused -Waliasing -Wampersand -Wcharacter-truncation -Wline-truncation -Wsurprising -Wno-tabs -Wunderflow' \
        CFLAGS="-std=c99" \
    && make all \
    && cd ../

# add specfem3d_globe/bin to PATH
ENV PATH=$PATH:/home/scoped/specfem3d_globe/bin