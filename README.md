# iac-docker-dev-k3s

DEV cluster

## Copy Kubernetes config file to Gitlab runner

    docker exec container-dev-glrunner-k1 /bin/bash -xe -c 'mkdir -p /home/gitlab-runner/.kube'
    cp .terraform/kube_config.yml /var/lib/docker/volumes/volume-dev-glrunner-k1-home/_data/.kube/config
    docker exec container-dev-glrunner-k1 /bin/bash -xe -c 'chown -R gitlab-runner: /home/gitlab-runner/.kube'
    
Then
    
    docker exec -it container-dev-glrunner-k1 /bin/bash
    su - gitlab-runner
    kubectl get pods --all-namespaces

(Optional) Expose port for public access (Spacelift etc.)

    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 49632 -j DNAT --to-destination 10.20.0.31:6443

List

    iptables -t nat -v -L -n --line-number

## Docker

    docker exec -it container-dev-k3s-slb /bin/bash
    docker exec -it container-dev-k3s-s1 /bin/bash
    docker logs --follow container-dev-k3s-s1
    
    docker container stop container-dev-k3s-s1
    docker container delete container-dev-k3s-s1

Helpers

    journalctl -fu docker.service


## Links

- https://picluster.ricsanfre.com/docs/minio/
