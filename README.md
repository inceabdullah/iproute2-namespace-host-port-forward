# NS Host Port Forward

Any port in ns to host, or host to in ns forward.

## Build

```bash
./docker-build.sh
```

### NS to Host Forwarding

>       +-------------+                                   +--------------+  
>       |             |                                   |     Host     |  
>       |    netns-1  | --------------------------------->|      or      |  
>       |             | listen :2222                  :22 |   Default ns |  
>       +------+------+         ns to host forward        +-------+------+  


```bash
docker run --privileged -v/var/run/netns:/var/run/netns --network=host --rm -itd nshostforward --host-port=22 --ns=netns-1 --ns-port=2222 --destination-to=ns
```

### Host to NS Forwarding

>       +-------------+                                   +--------------+  
>       |     Host    |                                   |              |  
>       |      or     | --------------------------------->|    netns-1   |  
>       |  Default ns | listen :2222                  :22 |              |  
>       +------+------+         host to ns forward        +-------+------+  


```bash
docker run -dit --privileged --network=host -v/var/run/netns:/var/run/netns nshostforward --host-port=2222 --ns=netns-1 --ns-port=22
```

### Container to Host

>       +-------------+                                   +--------------+  
>       |             |                                   |     Host     |  
>       |  container  | --------------------------------->|      or      |  
>       |             | listen :2222                  :22 |   Default ns |  
>       +------+------+     container to host forward     +-------+------+  


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


