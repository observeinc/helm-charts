# Example  deployment scenarios

## Node Affinity and Taints and Tolerations
https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes-using-node-affinity/
https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/

Node affinity is a property of Pods that attracts them to a set of nodes (either as a preference or a hard requirement). Taints are the opposite -- they allow a node to repel a set of pods.

Tolerations are applied to pods. Tolerations allow the scheduler to schedule pods with matching taints. Tolerations allow scheduling but don't guarantee scheduling: the scheduler also evaluates other parameters as part of its function.

Taints and tolerations work together to ensure that pods are not scheduled onto inappropriate nodes. One or more taints are applied to a node; this marks that the node should not accept any pods that do not tolerate the taints.


### Label a node for affinity
To demonstrate affinity we can create a simple deployment for an nginx pod

To show labels on nodes run this command:

```kubectl get nodes --show-labels```

Label two of your nodes substituting your node names:

```
kubectl label nodes YOUR_NODE_1 node-type=useme

kubectl label nodes YOUR_NODE_2 node-type=nouseme
```

Check pods for any pods in default namespace (or whichever namespace you like):

```kubectl get pods -n default```

Deploy simple nginx pod with affinity to node-type label of useme and then check pod deployed where you expect (you can uncomment os label affinity to see how that works as well)

```
kubectl apply -f node-affinity-daemonset.yaml -n default
```

Check pods and nodes they are deployed to:
```
kubectl get pods -o wide -n defaultx
```

Clean up:
```
# Remove label from node
kubectl label node YOUR_NODE_1 node-type-
kubectl label node YOUR_NODE_2 node-type-
# Delete node-affinity-daemonset
kubectl delete -f node-affinity-daemonset.yaml -n default
```


# Deploy k8s monitoring with affinity using labels (try with useme and nouseme)

Label two of your nodes substituting your node names:

```
kubectl label nodes YOUR_NODE_1 node-type=useme

kubectl label nodes YOUR_NODE_2 node-type=nouseme
```

```
helm install affinity-example -n k8smonitoring -f ./affinity-values.yaml ../../../charts/agent

helm upgrade affinity-example -n k8smonitoring -f ./affinity-values.yaml ../../../charts/agent
```

Cleanup
```
# Remove label from node
kubectl label node YOUR_NODE_1 node-type-
kubectl label node YOUR_NODE_2 node-type-
# Delete helm deployment
helm delete affinity-example -n k8smonitoring
```

# Get nodes and taints

Taint node

```
kubectl taint nodes $YOUR_NODE_1 deployObserve=notAllowed:NoSchedule

# Check taint
kubectl get nodes -o custom-columns=NAME:.metadata.name,TAINTS:.spec.taints

```

# Deploy k8s monitoring with taint and toleration
```
helm install taint-example -n k8smonitoring -f ./taint-values.yaml ../../../charts/agent

helm upgrade taint-example -n k8smonitoring -f ./taint-values.yaml ../../../charts/agent
```

# Cleanup:
```
# Remove taint
kubectl taint nodes $YOUR_NODE_1 deployObserve-
# Delete helm deployment
helm delete taint-example -n k8smonitoring
```
