# see also:
# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile
# https://github.com/jupyter/docker-stacks/blob/master/scipy-notebook/Dockerfile
#
FROM ubuntu:17.10

USER root
RUN sed -i -e "s/\/\/archive\.ubuntu/\/\/au.archive.ubuntu/" /etc/apt/sources.list

# install debian packages
RUN apt-get clean && rm -rf /var/lib/apt/lists/* && apt-get update && apt-get install -y --no-install-recommends  \
    graphviz              \
    locales               \
    less                  \
    psmisc                \
    bzip2                 \
    build-essential       \
    libssl-dev            \
    libffi-dev            \
    python-dev            \
    git                   \
    postgresql            \
    python-pip            \
    python-setuptools     \
    python-wheel          \
    python3-pip           \
    python3-setuptools    \
    python3-wheel         \
    python-tk             \
    wget                  \
    ca-certificates       \
    vim                   \
    ssh                   \
    file                  \
    zip                   \
    unzip                 \
    rsync                 \
  && rm -rf /var/lib/apt/lists/*


# fix locals
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8


# Quantum-Espresso Pseudo Potentials
WORKDIR /opt/pseudos
RUN base_url=http://archive.materialscloud.org/file/2018.0001/v1;  \
    for name in SSSP_efficiency_pseudos SSSP_accuracy_pseudos; do  \
       wget ${base_url}/${name}.aiida;                             \
    done;                                                                      \
    chown -R root:root /opt/pseudos/;                                          \
    chmod -R +r /opt/pseudos/

## install PyPI packages for Python 3
RUN pip3 install --upgrade         \
    'tornado==4.5.3'               \
    'jupyterhub==0.8.1'            \
    'notebook==5.5.0'              \
    'appmode==0.3.0'

# install PyPI packages for Python 2.
# This already enables jupyter notebook and server extensions
RUN pip2 install --process-dependency-links git+https://github.com/materialscloud-org/aiidalab-metapkg@v18.06.0rc4

# the fileupload extension also needs to be "installed"
RUN jupyter nbextension install --sys-prefix --py fileupload

## Get latest bugfixes from aiida-core
#WORKDIR /opt/aiida-core
#RUN git clone https://github.com/aiidateam/aiida_core.git && \
#    cd aiida_core && \
#     git checkout release_v0.11.2 && \
#     pip install --no-deps . && \
#    cd ..

# activate ipython kernels
RUN python2 -m ipykernel install
RUN python3 -m ipykernel install

# install MolPad
WORKDIR /opt
RUN git clone https://github.com/oschuett/molview-ipywidget.git  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python2.7/dist-packages/molview_ipywidget  && \
    ln -s /opt/molview-ipywidget/molview_ipywidget /usr/local/lib/python3.6/dist-packages/molview_ipywidget  && \
    jupyter nbextension     install --sys-prefix --py --symlink molview_ipywidget  && \
    jupyter nbextension     enable  --sys-prefix --py           molview_ipywidget

# create symlink for legacy workflows
RUN cd /usr/local/lib/python2.7/dist-packages/aiida/workflows; rm -rf user; ln -s /project/workflows user

# populate reentry cache for root user https://pypi.python.org/pypi/reentry/
RUN reentry scan

## disable MPI warnings that confuse ASE
## https://www.mail-archive.com/users@lists.open-mpi.org/msg30611.html
#RUN echo "btl_base_warn_component_unused = 0" >> /etc/openmpi/openmpi-mca-params.conf

#===============================================================================
RUN mkdir /project                                                 && \
    useradd --home /project --uid 1234 --shell /bin/bash scientist && \
    chown -R scientist:scientist /project

EXPOSE 8888

#===============================================================================
USER scientist
COPY postgres.sh /opt/
COPY setup-singleuser.sh /opt/
COPY start-singleuser.sh /opt/
#COPY matcloud-jupyterhub-singleuser /opt/

RUN /opt/setup-singleuser.sh

WORKDIR /project
CMD ["/opt/start-singleuser.sh"]
#EOF
