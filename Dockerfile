FROM ubuntu:16.04

# Set up conda:
RUN apt-get -qq update && apt-get -qq -y install curl bzip2 \
    && curl -sSL https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && bash /tmp/miniconda.sh -bfp /usr/local \
    && rm -rf /tmp/miniconda.sh \
    && conda install -y python=3 \
    && conda update conda \
    && apt-get -qq -y autoremove \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /var/log/dpkg.log \
    && conda clean --all --yes
ENV PATH /opt/conda/bin:$PATH

# Copy the current directory contents into the container at /app
COPY deployment/ /install/

# Run apt-gets:
RUN apt-get update && apt-get install -y \ 
    apt-utils \
    gcc \
    g++ \
    gfortran \
    hdf5-tools \
    make \
    git \
    cmake \
    libopenmpi-dev \
    software-properties-common \
    vim \
    apt-transport-https \
    gnupg2 \
    ca-certificates \
    slurm-client

# Set up python environments... this takes awhile:
RUN conda config --set always_yes yes --set changeps1 no
RUN conda update -q conda
RUN conda env create -v -q -n py36 -f /install/environment_36.yml
ENV PATH="/usr/local/envs/py36/bin:${PATH}"

# Set the correct path for freeCAD and fix the link to limstdc++       
RUN rm /usr/local/envs/py36/lib/libstdc++.so.6 \
    && ln -s /usr/local/envs/py36/lib/libstdc++.so.6.0.24 /usr/local/envs/py36/lib/libstdc++.so.6

# Clean up
RUN conda clean -pt

# Move the dask config file into place
RUN mkdir /root/.dask && mv /install/dask_config.yaml /root/.dask/.

# Set the working directory to /app
WORKDIR /app

# Copy QMS into the container and set up
# TODO: Only copy code and not deployment/doc/examples
COPY . qmt/
RUN cd qmt && python setup.py develop

CMD /bin/bash