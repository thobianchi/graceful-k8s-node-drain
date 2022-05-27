# Gracefully drain Kubernetes Node

Draining a node with kubectl without a disruption budget [will make disservices](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/) because will delete all pods on the specified node assuming is possible given that that deployment is lacking the pod distruption budget.

In the real world is possible to find a very important deployment without that setting.    

This script will cordon the node, find all pods running on the node, identify the owner ( Deployment ) and if that deployment has ready replicas > 1 simply delete pod otherwise will issue `kubectl rollout restart <deployment>`.  

This is a simple-minded approach, you should really configure a pod disruption budget. 

## Usage

```
./graceful-drain.sh --node NODENAME
```

