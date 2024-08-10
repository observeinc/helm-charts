{{- define "observe.deployment.clusterEvents.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.otlphttp.observe" . | nindent 2 }}

receivers:
  # this is used to create a cluster resource by pulling namespaces and then dropping all but kube-system with filter processor
  k8sobjects/cluster:
    auth_type: serviceAccount
    objects:
      - name: namespaces
        mode: pull
        interval: {{ .Values.cluster.events.pullInterval }}

  # this pulls all objects listed below
  k8sobjects/objects:
    auth_type: serviceAccount
    objects:
      ## P1
      - {name: events, mode: pull, interval: 15m}
      - {name: events, mode: watch}
      - {name: pods, mode: pull, interval: 15m}
      - {name: pods, mode: watch}
      - {name: namespaces, mode: pull, interval: 15m}
      - {name: namespaces, mode: watch}
      - {name: nodes, mode: pull, interval: 15m}
      - {name: nodes, mode: watch}
      - {name: deployments, mode: pull, interval: 15m}
      - {name: deployments, mode: watch}
      - {name: replicasets, mode: pull, interval: 15m}
      - {name: replicasets, mode: watch}
      - {name: configmaps, mode: pull, interval: 15m}
      - {name: configmaps, mode: watch}
      - {name: endpoints, mode: pull, interval: 15m}
      - {name: endpoints, mode: watch}
      ## P2
      - {name: jobs, mode: pull, interval: 15m}
      - {name: jobs, mode: watch}
      - {name: cronjobs, mode: pull, interval: 15m}
      - {name: cronjobs, mode: watch}
      - {name: daemonsets, mode: pull, interval: 15m}
      - {name: daemonsets, mode: watch}
      - {name: statefulsets, mode: pull, interval: 15m}
      - {name: statefulsets, mode: watch}
      - {name: services, mode: pull, interval: 15m}
      - {name: services, mode: watch}
      - {name: ingresses, mode: pull, interval: 15m}
      - {name: ingresses, mode: watch}
      - {name: secrets, mode: pull, interval: 15m}
      - {name: secrets, mode: watch}
      - {name: persistentvolumeclaims, mode: pull, interval: 15m}
      - {name: persistentvolumeclaims, mode: watch}
      - {name: persistentvolumes, mode: pull, interval: 15m}
      - {name: persistentvolumes, mode: watch}
      - {name: storageclasses, mode: pull, interval: 15m}
      - {name: storageclasses, mode: watch}
      - {name: roles, mode: pull, interval: 15m}
      - {name: roles, mode: watch}
      - {name: rolebindings, mode: pull, interval: 15m}
      - {name: rolebindings, mode: watch}
      - {name: clusterroles, mode: pull, interval: 15m}
      - {name: clusterroles, mode: watch}
      - {name: clusterrolebindings, mode: pull, interval: 15m}
      - {name: clusterrolebindings, mode: watch}
      - {name: serviceaccounts, mode: pull, interval: 15m}
      - {name: serviceaccounts, mode: watch}

processors:
{{- include "config.processors.memory_limiter" . | nindent 2 }}

{{- include "config.processors.resource_detection.cloud" . | nindent 2 }}

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.k8sattributes" . | nindent 2 }}

{{- include "config.processors.attributes.observe_common" . | nindent 2 }}

  k8sattributes/podcontroller:
    extract:
      metadata:
      - k8s.deployment.name
      - k8s.statefulset.name
      - k8s.replicaset.name
      - k8s.daemonset.name
      - k8s.cronjob.name
      - k8s.job.name
    pod_association:
      - sources:
          - from: resource_attribute
            name: k8s.pod.name
          - from: resource_attribute
            name: k8s.namespace.name

  transform/podcontroller:
    error_mode: ignore
    log_statements:
      - context: log
        conditions:
          - body["kind"] == "Pod"
        statements:
          - set(attributes["observe_transform"]["facets"]["deploymentName"], resource.attributes["k8s.deployment.name"])
          - set(attributes["observe_transform"]["facets"]["replicasetName"], resource.attributes["k8s.replicaset.name"])
          - set(attributes["observe_transform"]["facets"]["statefulsetName"], resource.attributes["k8s.statefulset.name"])
          - set(attributes["observe_transform"]["facets"]["daemonsetName"], resource.attributes["k8s.daemonset.name"])
          - set(attributes["observe_transform"]["facets"]["cronjobName"], resource.attributes["k8s.cronjob.name"])
          - set(attributes["observe_transform"]["facets"]["jobName"], resource.attributes["k8s.job.name"])

  # transform for k8s objects
  transform/object:
    error_mode: ignore
    log_statements:
      # Comment logic
      - context: log
        statements:
          - set(attributes["observe_filter"], "objects_pull_watch")
          # unwrapping for the object_watch stream
          - set(attributes["observe_transform"]["control"]["isDelete"], true) where body["object"] != nil and body["type"] == "DELETED"
          - set(attributes["observe_transform"]["control"]["debug_objectSource"], "watch") where body["object"] != nil and body["type"] != nil
          - set(attributes["observe_transform"]["control"]["debug_objectSource"], "pull") where body["object"] == nil or body["type"] == nil
          - set(body, body["object"]) where body["object"] != nil and body["type"] != nil
          # native columns: valid_from, valid_to, kind
          - set(attributes["observe_transform"]["valid_from"], observed_time_unix_nano)
          - set(attributes["observe_transform"]["valid_to"], Int(observed_time_unix_nano) + 5400000000000)
          - set(attributes["observe_transform"]["kind"], body["kind"])
          # control
          - set(attributes["observe_transform"]["control"]["isDelete"], false) where attributes["observe_transform"]["control"]["isDelete"] == nil
          - set(attributes["observe_transform"]["control"]["version"], body["metadata"]["resourceVersion"])
          # identifiers
          - set(attributes["observe_transform"]["identifiers"]["clusterName"], attributes["k8s.cluster.name"])
          - set(attributes["observe_transform"]["identifiers"]["clusterUid"], attributes["k8s.cluster.uid"])
          - set(attributes["observe_transform"]["identifiers"]["kind"], body["kind"])
          - set(attributes["observe_transform"]["identifiers"]["name"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["namespace"], body["metadata"]["namespace"])
          - set(attributes["observe_transform"]["identifiers"]["uid"], body["metadata"]["uid"])
          # facets
          - set(attributes["observe_transform"]["facets"]["creationTimestamp"], body["metadata"]["creationTimestamp"])
          - set(attributes["observe_transform"]["facets"]["deletionTimestamp"], body["metadata"]["deletionTimestamp"])
          # - set(attributes["observe_transform"]["facets"]["ownerReferences"], body["metadata"]["ownerReferences"])
          - set(attributes["observe_transform"]["facets"]["labels"], body["metadata"]["labels"])
          - set(attributes["observe_transform"]["facets"]["annotations"], body["metadata"]["annotations"])
      # For Pod
      - context: log
        conditions:
          - body["kind"] == "Pod"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["podName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["facets"]["phase"], body["status"]["phase"])
          - set(attributes["observe_transform"]["facets"]["podIP"], body["status"]["podIP"])
          - set(attributes["observe_transform"]["facets"]["qosClass"], body["status"]["qosClass"])
          - set(attributes["observe_transform"]["facets"]["startTime"], body["status"]["startTime"])
          - set(attributes["observe_transform"]["facets"]["readinessGates"], body["object"]["spec"]["readinessGates"])
          - set(attributes["observe_transform"]["facets"]["nodeName"], body["spec"]["nodeName"])
          - set(resource.attributes["k8s.pod.name"], body["metadata"]["name"])
          - set(resource.attributes["k8s.namespace.name"], body["metadata"]["namespace"])
      # For Namespace
      - context: log
        conditions:
          - body["kind"] == "Namespace"
        statements:
          - set(attributes["observe_transform"]["facets"]["status"], body["status"]["phase"])
      # For Node
      - context: log
        conditions:
          - body["kind"] == "Node"
        statements:
          - set(attributes["observe_transform"]["facets"]["kernelVersion"], body["status"]["nodeInfo"]["kernelVersion"])
          - set(attributes["observe_transform"]["facets"]["kubeProxyVersion"], body["status"]["nodeInfo"]["kubeProxyVersion"])
          - set(attributes["observe_transform"]["facets"]["kubeletVersion"], body["status"]["nodeInfo"]["kubeletVersion"])
          - set(attributes["observe_transform"]["facets"]["osImage"], body["status"]["nodeInfo"]["osImage"])
          - set(attributes["observe_transform"]["facets"]["taints"], body["spec"]["taints"])
      # For Deployment
      - context: log
        conditions:
          - body["kind"] == "Deployment"
        statements:
          - set(attributes["observe_transform"]["facets"]["selector"], body["spec"]["selector"]["matchLabels"])
          - set(attributes["observe_transform"]["facets"]["revision"], body["metadata"]["annotations"]["deployment.kubernetes.io/revision"])
          - set(attributes["observe_transform"]["facets"]["desired"], body["spec"]["replicas"])
          - set(attributes["observe_transform"]["facets"]["updated"], body["status"]["updatedReplicas"])
          - set(attributes["observe_transform"]["facets"]["total"], body["status"]["replicas"])
          - set(attributes["observe_transform"]["facets"]["available"], body["status"]["availableReplicas"])
          - set(attributes["observe_transform"]["facets"]["unavailable"], body["status"]["unavailableReplicas"])
          - set(attributes["observe_transform"]["facets"]["ready"], body["status"]["readyReplicas"])
          - set(attributes["observe_transform"]["facets"]["ready"], 0) where attributes["observe_transform"]["facets"]["ready"] == nil
      # For ReplicaSet
      - context: log
        conditions:
          - body["kind"] == "ReplicaSet"
        statements:
          - set(cache["ownerReferences"], body["metadata"]["ownerReferences"])
          - flatten(cache, depth=3)
          - set(attributes["observe_transform"]["facets"]["deployment"], cache["ownerReferences.0"]["name"])
          - set(attributes["observe_transform"]["facets"]["revision"], body["metadata"]["annotations"]["deployment.kubernetes.io/revision"])
          - set(attributes["observe_transform"]["facets"]["desired"], body["spec"]["replicas"])
          - set(attributes["observe_transform"]["facets"]["current"], body["status"]["replicas"])
          - set(attributes["observe_transform"]["facets"]["ready"], body["status"]["readyReplicas"])
          - set(attributes["observe_transform"]["facets"]["ready"], 0) where attributes["observe_transform"]["facets"]["ready"] == nil
      # For ConfigMap
      - context: log
        conditions:
          - body["kind"] == "ConfigMap"
        statements:
          - set(attributes["observe_transform"]["facets"]["data"], body["data"])
      # For Event
      - context: log
        conditions:
          - body["kind"] == "Event"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["involvedObject"], body["involvedObject"])
          - set(attributes["observe_transform"]["facets"]["firstTimestamp"], body["firstTimestamp"])
          - set(attributes["observe_transform"]["facets"]["lastTimestamp"], body["lastTimestamp"])
          - set(attributes["observe_transform"]["facets"]["message"], body["message"])
          - set(attributes["observe_transform"]["facets"]["reason"], body["reason"])
          - set(attributes["observe_transform"]["facets"]["count"], body["count"])
          - set(attributes["observe_transform"]["facets"]["type"], body["type"])
          - set(attributes["observe_transform"]["facets"]["sourceComponent"], body["source"]["component"])

  # drop all namespace except kube-system
  filter/cluster:
    error_mode: ignore
    logs:
      log_record:
        - body["metadata"]["name"] != "kube-system" and body["object"]["metadata"]["name"] != "kube-system"

  # transform for creating cluster resource
  transform/cluster:
    error_mode: ignore
    log_statements:
      - context: log
        statements:
          - set(attributes["observe_filter"], "objects_pull_watch")
          # unwrap the object out of the watch stream
          - set(attributes["observe_transform"]["control"]["isDelete"], true) where body["object"] != nil and body["type"] == "DELETED"
          - set(attributes["observe_transform"]["control"]["debug_objectSource"], "watch") where body["object"] != nil and body["type"] != nil
          - set(attributes["observe_transform"]["control"]["debug_objectSource"], "pull") where body["object"] == nil or body["type"] == nil
          - set(body, body["object"]) where body["object"] != nil and body["type"] != nil
          # native columns: valid_from, valid_to, kind
          - set(attributes["observe_transform"]["valid_from"], observed_time_unix_nano)
          - set(attributes["observe_transform"]["valid_to"], Int(observed_time_unix_nano) + 5400000000000)
          - set(attributes["observe_transform"]["kind"], "Cluster")
          # control
          - set(attributes["observe_transform"]["control"]["isDelete"], false) where attributes["observe_transform"]["control"]["isDelete"] == nil
          - set(attributes["observe_transform"]["control"]["version"], body["metadata"]["resourceVersion"])
          # identifiers
          - set(attributes["observe_transform"]["identifiers"]["clusterName"], attributes["k8s.cluster.name"])
          - set(attributes["observe_transform"]["identifiers"]["clusterUid"], attributes["k8s.cluster.uid"])
          - set(attributes["observe_transform"]["identifiers"]["kind"], "Cluster")
          - set(attributes["observe_transform"]["identifiers"]["name"], attributes["k8s.cluster.name"])
          - delete_key(attributes["observe_transform"]["identifiers"], "uid")
          # facets
          - set(attributes["observe_transform"]["facets"]["creationTimestamp"], body["metadata"]["creationTimestamp"])
          - set(attributes["observe_transform"]["facets"]["labels"], body["metadata"]["labels"])
          - set(attributes["observe_transform"]["facets"]["annotations"], body["metadata"]["annotations"])
          # this is a fake object, there is no k8s yaml object for it
          - set(body, "")

service:
  pipelines:
      logs/objects:
        receivers: [k8sobjects/objects]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, transform/object]
        exporters: [otlphttp/observe]
      logs/cluster:
        receivers: [k8sobjects/cluster]
        processors: [memory_limiter, batch, resourcedetection/cloud, k8sattributes, attributes/observe_common, filter/cluster, transform/cluster]
        exporters: [otlphttp/observe] 
{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
