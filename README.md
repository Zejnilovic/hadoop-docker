# hadoop-docker
Hadoop 2.7.5 in Docker with OpenJDK 8. Avaivable on [docker hub](https://hub.docker.com/r/zejnils/hadoop-docker)

An image based on [sequenceiq's](https://hub.docker.com/r/sequenceiq/hadoop-docker/) Created to be Debian based and smaller (609 MB)

## Run Examples
```bash
docker run -p 8088:8088 -p 8042:8042  zejnils/hadoop-docker
```

```bash
docker run -it zejnils/hadoop-docker /etc/bootstrap.sh bash
```
