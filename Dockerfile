# Use an Ubuntu base image for compatibility
FROM nvidia/cuda:11.8.0-devel-ubuntu20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

WORKDIR /workspace
COPY  ./VAP-internal_battery  /workspace/

# RUN apt-get update && \
#     apt-get install -y software-properties-common && \
#     add-apt-repository ppa:deadsnakes/ppa && \
#     apt-get update && \
#     apt-get install -y \
#     python3.10 \
#     python3.10-dev \
#     python3.10-distutils \
#     python3.10-venv \
#     curl \
#     git \
#     cmake \
#     sudo \
#     wget \
#     build-essential \
#     libgl1 \
#     libglib2.0-0 && \
#     ln -sf /usr/bin/python3.10 /usr/bin/python && \
#     curl -sS https://bootstrap.pypa.io/get-pip.py | python && \
#     ln -sf /usr/local/bin/pip /usr/bin/pip && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    python3.10 python3.10-dev python3.10-distutils python3.10-venv \
    curl git cmake sudo wget build-essential \
    libgl1 libglib2.0-0 \
    libx11-xcb1 libxrender1 libxi6 libxext6 libsm6 libxrandr2 libfontconfig1 \
    libxcb1 libxcb-xinerama0 libxcb-xfixes0 libxcb-shm0 libxcb-icccm4 \
    libxcb-image0 libxcb-keysyms1 libxcb-render-util0 libxkbcommon-x11-0 \
    libglu1-mesa libgl1-mesa-glx libgtk2.0-dev pkg-config \
    xvfb \
    && ln -sf /usr/bin/python3.10 /usr/bin/python && \
    curl -sS https://bootstrap.pypa.io/get-pip.py | python && \
    ln -sf /usr/local/bin/pip /usr/bin/pip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install basic Python build tools
RUN python -m pip install --upgrade pip setuptools wheel ninja

COPY cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz /tmp/
RUN tar -xvf /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive.tar.xz -C /tmp && \
    cp -P /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive/include/* /usr/local/cuda/include/ && \
    cp -P /tmp/cudnn-linux-x86_64-8.5.0.96_cuda11-archive/lib/* /usr/local/cuda/lib64/ && \
    ldconfig && \
    rm -rf /tmp/cudnn*
ENV CUDNN_DIR=/home/atharva/cudnn-linux-x86_64-8.5.0.96_cuda11-archive
ENV LD_LIBRARY_PATH=$CUDNN_DIR/lib:$LD_LIBRARY_PATH

RUN pip install --no-cache-dir torch==2.0.0+cu118 torchvision==0.15.1+cu118 torchaudio==2.0.1+cu118 --index-url https://download.pytorch.org/whl/cu118

# Install Python packages
RUN pip install playsound \
    pyserial \
    albumentations \
    pygame \
    && pip uninstall -y opencv-python \
    && pip install opencv-python==4.11.0.86

RUN pip install -U openmim
#RUN mim install mmcv==2.0.0 -f https://download.openmmlab.com/mmcv/dist/cu118/torch2.0/index.html

# Set environment variables for CUDA
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
ENV FORCE_CUDA=1
ENV TORCH_CUDA_ARCH_LIST="8.6"


# Clone and build MMCV
RUN git clone -b v2.0.0 https://github.com/open-mmlab/mmcv.git && \
    cd mmcv && \
    pip install -r requirements/build.txt && \
    pip install -v -e .

RUN pip install mmengine==0.7.1
RUN pip install mmdet==3.0.0

RUN pip install git+https://github.com/PaddlePaddle/PaddleOCR.git
RUN pip install tqdm
RUN pip install loguru
RUN pip install paddlepaddle-gpu

RUN pip install --no-cache-dir openxlab==0.1.2 requests==2.28.2 pandas==1.5.3 \
    numpy==1.24.4 matplotlib==3.7.2 tqdm==4.65.0 packaging>=22.0 pytz==2023.3 rich==13.4.2 \
    networkx==3.1 jupyterlab notebook ipykernel


# Set working directory
WORKDIR /workspace

# Expose port for JupyterLab
EXPOSE 8888

# Start JupyterLab
CMD ["jupyter", "lab", "--ip=0.0.0.0", "--allow-root", "--no-browser"]