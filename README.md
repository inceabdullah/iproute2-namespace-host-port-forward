# NS Host Port Forward

**A versatile tool for port forwarding. Supports forwarding between network namespaces and the host, between Docker containers, and from a Docker container to the host.**

## Table of Contents
- [Build](#build)
- [NS to Host Forwarding](#ns-to-host-forwarding)
- [Host to NS Forwarding](#host-to-ns-forwarding)
- [Container to Host](#container-to-host)
- [Docker to Docker Forwarding](#docker-to-docker-forwarding)
- [Troubleshooting](#troubleshooting)
- [Contribution](#contribution)
- [License](#license)

## Build
```bash
./docker-build.sh
```

## NS to Host Forwarding
Forward traffic from a network namespace to the host.

>       +---------+                                   +-------+  
>       |         |                                   |       |  
>       |  netns  | --------------------------------->|  Host |  
>       |         | listen :2222                  :22 |       |  
>       +---------+         ns to host forward        +-------+  

```bash
docker run --privileged -v/var/run/netns:/var/run/netns --network=host --rm -itd nshostforward --host-port=22 --ns=netns-1 --ns-port=2222 --destination-to=ns
```

## Host to NS Forwarding
Forward traffic from the host to a network namespace.

>       +-------+                                   +---------+  
>       |       |                                   |         |  
>       |  Host | --------------------------------->|  netns  |  
>       |       | listen :2222                  :22 |         |  
>       +-------+         host to ns forward        +---------+  

```bash
docker run -dit --privileged --network=host -v/var/run/netns:/var/run/netns nshostforward --host-port=2222 --ns=netns-1 --ns-port=22
```

## Container to Host
Forward traffic from a Docker container to the host.

>       +-----------+                                   +-------+  
>       |           |                                   |       |  
>       | Container | --------------------------------->|  Host |  
>       |           | listen :2222                  :22 |       |  
>       +-----------+     container to host forward     +-------+  

```bash
CONTAINER_ID=<CONTAINER_ID>
docker run --privileged \
    -v/var/run/netns:/var/run/netns \
    -v/proc:/proc_host \
    -v/var/run/docker.sock:/var/run/docker.sock \
    --network=host -dit nshostforward \
    --destination-to=container \
    --container-id=$CONTAINER_ID \
    --container-port=2222 \
    --forward-to=host \
    --host-port=22
```

## Docker to Docker Forwarding
Forward traffic between two Docker containers.

>       +-------------+                                   +--------------+  
>       |             |                                   |              |  
>       |  Container1 | --------------------------------->|  Container2  |  
>       |             | listen :2222                  :22 |              |  
>       +------+------+      docker to docker forward     +-------+------+  

```bash
SOURCE_CONTAINER_ID=<SOURCE_CONTAINER_ID>
DEST_CONTAINER_ID=<DEST_CONTAINER_ID>
docker run --privileged \
    -v/var/run/docker.sock:/var/run/docker.sock \
    -v/proc:/proc_host \
    --network=host -dit nshostforward \
    --destination-to=docker \
    --source-container-id=$SOURCE_CONTAINER_ID \
    --source-port=2222 \
    --dest-container-id=$DEST_CONTAINER_ID \
    --dest-port=22
```

## Troubleshooting


## Contribution
Contributions are welcome! Feel free to open a pull request.

## License
This project is licensed under the Apache License 2.0.

