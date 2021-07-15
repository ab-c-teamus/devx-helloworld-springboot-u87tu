## Build

    flex build

## Running Locally w/ Docker

After a successful build, you can run it like so:

    docker run -p  8080:8080 devx-helloworld-springboot-u87tu:latest

After it starts, you can hit the health check endpoint:

    curl localhost:8080/actuator/health
    {"status":"UP"}

## Running w/ Kubernetes

    flex deploy

## Publish Build to Artifactory

    flex publish
