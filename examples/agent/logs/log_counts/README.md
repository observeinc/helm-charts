# How to validate log line counts
In some cases we need to validate that the logs on k8s node are being shipped to Observe.

The process for doing this is to count the lines in a log file on the k8s node for a given time range and then validate that the same number of lines have been received in Observe.

## Creating a pod to access host file system
The following example assumes you want to deploy a pod to every node (assuming if you have taints you know how to deal with them).  If you want to only deploy a pod to a single node you could use node selector or affinity instead (assumed you can figure that out if you want it).

To get a list of pods and the node they are deployed on or a list of pods on a node
```
kubectl get pods -o=custom-columns=NAME:.metadata.name,NODE:.spec.nodeName -n default

kubectl get pods --field-selector spec.nodeName=ip-172-20-149-61.us-west-2.compute.internal
```

Deploy pod as Daemonset

```
kubectl apply -n default -f - <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: debug-logger
  labels:
    app: debug-logger
spec:
  selector:
    matchLabels:
      app: debug-logger
  template:
    metadata:
      labels:
        app: debug-logger
    spec:
      containers:
      - name: debug-container
        image: ubuntu:latest
        command: ["/bin/sleep"]
        args: ["infinity"]
        securityContext:
          privileged: true  # This might be necessary for some debug operations but use with caution
        volumeMounts:
        - name: host-root
          mountPath: /host
      volumes:
      - name: host-root
        hostPath:
          path: /
EOF
```

## Login to pod and switch to pod logs
```
kubectl exec -it debug-logger-ADBCDEF /bin/bash

cd /host/var/log/pods

# Show pod log directories
ls

# Switch to a particular pod
cd NAMESPACE_POD_NAME_UID/LOG_DIR/
```

### Example directory
```
/host/var/log/pods/eng_collector-v2-854bdcd65b-n8vhq_209156da-67c8-45cf-ac0f-2839daa067ca/collector-v2
```

## Counting lines in a log file
Prints start and end timestamps and count of lines between

```
start_timestamp=$(head -n 1 0.log | awk '{print $1}'); \
end_timestamp=$(tail -n 1 0.log | awk '{print $1}'); \
echo $start_timestamp; \
echo $end_timestamp; \
awk -v start=$start_timestamp -v end=$end_timestamp '
   $0 >= start && $0 <= end { count++; }
   END { print count }
 ' 0.log

```

### Example output
```
2024-11-07T16:52:38.599268179Z
2024-11-07T17:25:38.857583783Z
1034
```

## Checking in Observe
Example OPAL assuming input of "kubernetes logs"

```
make_col k8snodename:string(resource_attributes['k8s.node.name'])
make_col logfilepath:string(attributes['log.file.path'])
make_col k8spodname:string(resource_attributes['k8s.pod.name'])
make_col k8snamespacename:string(resource_attributes['k8s.namespace.name'])
make_col k8scontainername:string(resource_attributes['k8s.container.name'])

filter k8snamespacename = "eng"
filter logfilepath = "/var/log/pods/eng_collector-v2-854bdcd65b-n8vhq_209156da-67c8-45cf-ac0f-2839daa067ca/collector-v2/0.log"
filter timestamp >= parse_isotime("2024-11-07T16:52:38.599268179Z") and timestamp < parse_isotime("2024-11-07T17:25:38.857583783Z")

statsby count(logfilepath), group_by(k8snamespacename,k8spodname,k8scontainername,logfilepath)
```
