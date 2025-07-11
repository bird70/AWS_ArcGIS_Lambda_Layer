# Use the Amazon Linux 2 base image
FROM amazonlinux:2

# Install required system packages
RUN yum install -y \
    gcc \
    gcc-c++ \
    make \
    zlib-devel \
    bzip2 \
    bzip2-devel \
    readline-devel \
    sqlite \
    sqlite-devel \
    xz \
    xz-devel \
    libffi-devel \
    tar \
    zip \
    wget \
    gzip \
    perl \
    perl-IPC-Cmd \
    krb5-devel \
    blas64 \
    blas64-devel \
    openssl11 \
    openssl11-devel \
    && yum clean all

# Set environment variables for BLAS and OpenSSL
ENV LD_LIBRARY_PATH="/lambda-layer/python/lib/python3.11/site-packages:/usr/local/lib:/usr/lib64"
ENV BLAS_NUM_THREADS=1
ENV CPPFLAGS="-I/usr/include/openssl"
ENV LDFLAGS="-L/usr/lib64"

# Install Python 3.11 from source
RUN wget https://www.python.org/ftp/python/3.11.10/Python-3.11.10.tgz && \
    tar xzf Python-3.11.10.tgz && \
    cd Python-3.11.10 && \
    ./configure --enable-optimizations --enable-shared --disable-test-modules --with-openssl=/usr/ && \
    make && \
    make altinstall && \
    cd .. && rm -rf Python-3.11.10 Python-3.11.10.tgz

# Verify that the ssl module is available
RUN python3.11 -m ensurepip && \
    python3.11 -m pip install --upgrade pip && \
    python3.11 -c "import ssl; print(ssl.OPENSSL_VERSION)"

# Install the required Python packages into the default Python site-packages directory
COPY requirements.txt /tmp/
RUN python3.11 -m pip install --no-cache-dir --no-compile -r /tmp/requirements.txt
RUN python3.11 -m pip install --no-cache-dir --no-compile s3fs
RUN python3.11 -m pip install --no-cache-dir --no-compile numpy==1.24.3
RUN python3.11 -m pip install --no-cache-dir --no-compile pandas==2.0.2
RUN python3.11 -m pip install --no-cache-dir --no-compile netCDF4==1.6.4
RUN python3.11 -m pip install --no-cache-dir --no-compile geopandas==1.0.1
RUN python3.11 -m pip install --no-cache-dir --no-compile azure-storage-blob==12.8.0
RUN python3.11 -m pip install --no-cache-dir --no-compile arcgis==2.4.0 --no-deps
# RUN python3.11 -m pip install --no-cache-dir --no-compile shapely

# Create the Lambda layer directory structure
RUN mkdir -p /lambda-layer/python/lib/python3.11/site-packages && \
    cp -r $(python3.11 -c "import site; print(site.getsitepackages()[0])")/* /lambda-layer/python/lib/python3.11/site-packages

# Remove unnecessary libraries and files
RUN rm -rf /lambda-layer/python/lib/python3.11/site-packages/pip* && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/setuptools* && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/wheel* && \
    \
    find /lambda-layer/python/lib/python3.11/site-packages -name '*.so' -exec strip --strip-unneeded {} + && \
    find /lambda-layer/python/lib/python3.11/site-packages -name '*.a' -delete && \
    find /lambda-layer/python/lib/python3.11/site-packages -name 'tests' -type d -exec rm -rf {} + && \
    find /lambda-layer/python/lib/python3.11/site-packages -name '*.pyc' -delete && \
    find /lambda-layer/python/lib/python3.11/site-packages -name '__pycache__' -type d -exec rm -rf {} + && \
    find /lambda-layer/python/lib/python3.11/site-packages -name '*.dist-info' -type d -exec rm -rf {} + && \
    find /lambda-layer/python/lib/python3.11/site-packages -name '*.egg-info' -type d -exec rm -rf {} + && \
    find /lambda-layer/python/lib/python3.11/site-packages -name 'docs' -type d ! -path '/lambda-layer/python/lib/python3.11/site-packages/botocore/docs' -exec rm -rf {} + && \
    find /lambda-layer/python/lib/python3.11/site-packages -name 'examples' -type d -exec rm -rf {} + && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/arcgis/learn && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/arcgis/apps && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/arcgis/geoenrichment && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/arcgis/graph && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/arcgis/widgets && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/numpy/distutils* && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/numpy/f2py && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/numpy/tests && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/numpy/doc && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/pandas/tests && \
    rm -rf /lambda-layer/python/lib/python3.11/site-packages/pandas/io/tests

# Zip the layer
RUN cd /lambda-layer && zip -r9 /lambda-layer/lambda-layer_py311_amazonlinux_SMALLEST_arcgis_azureblob_netCDF_geopandas_s3fs.zip python

# Set the entrypoint to bash for debugging purposes
ENTRYPOINT ["/bin/bash"]
