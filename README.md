# AWS Lambda Layer for ArcGIS
ArcGIS Library in an AWS Lambda Layer

## What this is for

For workflows in AWS which manipulate data or services in ArcGIS Online (or ArcGIS Enterprise), Python in Lambda can be used. To do so requires a Lambda function that can import the ArcGIS API for Python - which is usually quite big, with all the dependencies.

All required imports are part of the layer package (zip file) created here, in a small enough file (< 90 MB) to be used as a Lambda layer.

### Example ETL 1

One example ETL workflow would be to convert a NetCDF file of vector (table) data into a Geopackage that can be used to overwrite an ArcGIS Hosted Feature Layer.

### Example ETL 2

Another example could be a workflow where S3 receives a tif-format raster that needs to be uploaded to ArcGIS Online as a Hosted Image Layer (requires Azure Blob Storage)

## What this folder contains

This folder contains Dockerfile(s), requirements and a resulting zip file that contain all the required Python libraries, including the following:

arcgis (2.4)
azure storage blob
NetCDF4
pandas
numpy
geopandas
sqlite3
s3fs

CAVEAT: some large directories are removed from the build, including the 'arcgis deep learning' modules.

This is built using Amazon Linux 2 (as no suitable process to use Amazon Linux 2023 was found).

# Using the repo

If you just want to create a Lambda layer to use with the arcgis API for Python and ArcGIS Online, the zip file in this folder can be uploaded to AWS directly, and a Linux/Python3.11 compatible Lambda Layer be created. That layer can be associated with various Lambda functions, so it doesn't have to be created multiple times.

To build modified output, use the Dockerfile after making your changes to build a new container, then run the container interactively and change into the directory where the built Zip file is stored "cd /lambda-layer" to download the file. This works conveniently in Visual Studio Code with the Docker extension.
