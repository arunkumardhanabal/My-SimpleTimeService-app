# Simple Time Service

This repository contains a simple Python Flask application that provides the current timestamp and the IP address of the visitor.

## Overview

When accessed, the application returns a JSON response with the following information:

* **timestamp:** The current date and time on the server.
* **ip:** The IP address of the client making the request.

## Running the Application in Docker

The Python code for this service is located in the "Code" directory of this repository.

This application has been containerized and is available on Docker Hub. You can easily run it using Docker.

**Prerequisites**

**Docker:** Ensure you have Docker installed on your system. You can find installation instructions for your operating system on the official Docker website.
Running the Pre-built Docker Image (Recommended).

You can directly run the pre-built Docker image from Docker Hub or start with building the image using the Dockerfile available in this repository.

Bash

```
docker run -p 5000:5000 arun1771/my-sts-app:v2
```

Once the container is running, you can access the service by opening your web browser or using a tool like curl to the following address:

```
http://localhost:5000/
```
You should see a JSON response similar to:

JSON

```
{
  "timestamp": "2025-04-04T23:06:00.123456",
  "ip": "172.17.0.1"
}
```

