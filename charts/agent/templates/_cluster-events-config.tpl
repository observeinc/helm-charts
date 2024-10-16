{{- define "observe.deployment.clusterEvents.config" -}}

extensions:
{{- include "config.extensions.health_check" . | nindent 2 }}

exporters:
{{- include "config.exporters.debug" . | nindent 2 }}
{{ if .Values.observe.entityToken.use }}
{{- include "config.exporters.otlphttp.observe.entity" . | nindent 2 }}
{{ end }}
{{- include "config.exporters.otlphttp.observe.base" . | nindent 2 }}

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

{{- include "config.processors.batch" . | nindent 2 }}

{{- include "config.processors.attributes.observe_common" . | nindent 2 }}

{{- include "config.processors.attributes.observek8sattributes" . | nindent 2 }}

  # transform for k8s objects
  transform/object:
    error_mode: ignore
    log_statements:
      - context: log
        statements:
          - set(attributes["observe_filter"], "objects_pull_watch")
          # unwrapping for the object_watch stream
          - set(attributes["observe_transform"]["control"]["isDelete"], true) where body["object"] != nil and body["type"] == "DELETED"
          - set(attributes["observe_transform"]["control"]["debug_source"], "watch") where body["object"] != nil and body["type"] != nil
          - set(attributes["observe_transform"]["control"]["debug_source"], "pull") where body["object"] == nil or body["type"] == nil
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
          - set(resource.attributes["clusterName"], attributes["k8s.cluster.name"])
          - set(resource.attributes["clusterUid"], attributes["k8s.cluster.uid"])
          - set(attributes["observe_transform"]["identifiers"]["kind"], body["kind"])
          - set(attributes["observe_transform"]["identifiers"]["name"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["namespaceName"], body["metadata"]["namespace"])
          - set(attributes["observe_transform"]["identifiers"]["uid"], body["metadata"]["uid"])
          # facets
          - set(attributes["observe_transform"]["facets"]["creationTimestamp"], body["metadata"]["creationTimestamp"])
          - set(attributes["observe_transform"]["facets"]["deletionTimestamp"], body["metadata"]["deletionTimestamp"])
          - set(attributes["observe_transform"]["facets"]["ownerRefKind"], body["metadata"]["ownerReferences"][0]["kind"])
          - set(attributes["observe_transform"]["facets"]["ownerRefName"], body["metadata"]["ownerReferences"][0]["name"])
          - set(attributes["observe_transform"]["facets"]["labels"], body["metadata"]["labels"])
          - set(attributes["observe_transform"]["facets"]["annotations"], body["metadata"]["annotations"])
          # controllers with correlation tags
          - set(attributes["observe_transform"]["facets"]["replicaSetName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "ReplicaSet"
          - set(attributes["observe_transform"]["facets"]["daemonSetName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "DaemonSet"
          - set(attributes["observe_transform"]["facets"]["jobName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "Job"
          - set(attributes["observe_transform"]["facets"]["cronJobName"], attributes["observe_transform"]["facets"]["jobName"]) where IsMatch(attributes["observe_transform"]["facets"]["jobName"], ".*-\\d{8}$")
          - replace_pattern(attributes["observe_transform"]["facets"]["cronJobName"], "-\\d{8}$$", "")
          - set(attributes["observe_transform"]["facets"]["statefulSetName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "StatefulSet"
          - set(attributes["observe_transform"]["facets"]["deploymentName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "ReplicaSet"
          - replace_pattern(attributes["observe_transform"]["facets"]["deploymentName"], "^(.*)-[0-9a-f]+$$", "$$1")
          - set(attributes["observe_transform"]["facets"]["deploymentName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "Deployment"
      # Pod
      - context: log
        conditions:
          - body["kind"] == "Pod"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["podName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["podUid"], body["metadata"]["uid"])
          # status
          - set(attributes["observe_transform"]["facets"]["phase"], body["status"]["phase"])
          - set(attributes["observe_transform"]["facets"]["podIP"], body["status"]["podIP"])
          - set(attributes["observe_transform"]["facets"]["qosClass"], body["status"]["qosClass"])
          - set(attributes["observe_transform"]["facets"]["startTime"], body["status"]["startTime"])
          # spec
          - set(attributes["observe_transform"]["facets"]["readinessGates"], body["object"]["spec"]["readinessGates"])
          - set(attributes["observe_transform"]["facets"]["nodeName"], body["spec"]["nodeName"])
      # Namespace
      - context: log
        conditions:
          - body["kind"] == "Namespace"
        statements:
          - set(attributes["observe_transform"]["facets"]["status"], body["status"]["phase"])
          - set(attributes["observe_transform"]["identifiers"]["namespaceName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["namespaceUid"], body["metadata"]["uid"])
      # Node
      - context: log
        conditions:
          - body["kind"] == "Node"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["nodeName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["nodeUid"], body["metadata"]["uid"])
        # status
          - set(attributes["observe_transform"]["facets"]["kernelVersion"], body["status"]["nodeInfo"]["kernelVersion"])
          - set(attributes["observe_transform"]["facets"]["kubeProxyVersion"], body["status"]["nodeInfo"]["kubeProxyVersion"])
          - set(attributes["observe_transform"]["facets"]["kubeletVersion"], body["status"]["nodeInfo"]["kubeletVersion"])
          - set(attributes["observe_transform"]["facets"]["osImage"], body["status"]["nodeInfo"]["osImage"])
        # spec
          - set(attributes["observe_transform"]["facets"]["taints"], body["spec"]["taints"])
      # Deployment
      - context: log
        conditions:
          - body["kind"] == "Deployment"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["deploymentName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["deploymentUid"], body["metadata"]["uid"])
          # status
          - set(attributes["observe_transform"]["facets"]["updatedReplicas"], body["status"]["updatedReplicas"])
          - set(attributes["observe_transform"]["facets"]["availableReplicas"], body["status"]["availableReplicas"])
          - set(attributes["observe_transform"]["facets"]["readyReplicas"], body["status"]["readyReplicas"])
          - set(attributes["observe_transform"]["facets"]["readyReplicas"], 0) where attributes["observe_transform"]["facets"]["readyReplicas"] == nil
          - set(attributes["observe_transform"]["facets"]["unavailableReplicas"], body["status"]["unavailableReplicas"])
          # spec
          - set(attributes["observe_transform"]["facets"]["selector"], body["spec"]["selector"]["matchLabels"])
          - set(attributes["observe_transform"]["facets"]["desiredReplicas"], body["spec"]["replicas"])
          # custom
          - set(attributes["observe_transform"]["facets"]["status"], "Healthy") where attributes["observe_transform"]["facets"]["readyReplicas"] == attributes["observe_transform"]["facets"]["desiredReplicas"]
          - set(attributes["observe_transform"]["facets"]["status"], "Unhealthy") where attributes["observe_transform"]["facets"]["readyReplicas"] != attributes["observe_transform"]["facets"]["desiredReplicas"]
      # ReplicaSet
      - context: log
        conditions:
          - body["kind"] == "ReplicaSet"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["replicaSetName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["replicaSetUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["desiredReplicas"], body["spec"]["replicas"])
          # status
          - set(attributes["observe_transform"]["facets"]["currentReplicas"], body["status"]["replicas"])
          - set(attributes["observe_transform"]["facets"]["availableReplicas"], body["status"]["availableReplicas"])
          - set(attributes["observe_transform"]["facets"]["readyReplicas"], body["status"]["readyReplicas"])
          - set(attributes["observe_transform"]["facets"]["readyReplicas"], 0) where attributes["observe_transform"]["facets"]["readyReplicas"] == nil
          - set(attributes["observe_transform"]["facets"]["status"], "Healthy") where attributes["observe_transform"]["facets"]["readyReplicas"] == attributes["observe_transform"]["facets"]["desiredReplicas"]
          - set(attributes["observe_transform"]["facets"]["status"], "Unhealthy") where attributes["observe_transform"]["facets"]["readyReplicas"] != attributes["observe_transform"]["facets"]["desiredReplicas"]
      # Event
      - context: log
        conditions:
          - body["kind"] == "Event"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["involvedObjectKind"], body["involvedObject"]["kind"])
          - set(attributes["observe_transform"]["identifiers"]["involvedObjectName"], body["involvedObject"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["involvedObjectUid"], body["involvedObject"]["uid"])
          - set(attributes["observe_transform"]["facets"]["firstTimestamp"], body["firstTimestamp"])
          - set(attributes["observe_transform"]["facets"]["lastTimestamp"], body["lastTimestamp"])
          - set(attributes["observe_transform"]["facets"]["message"], body["message"])
          - set(attributes["observe_transform"]["facets"]["reason"], body["reason"])
          - set(attributes["observe_transform"]["facets"]["count"], body["count"])
          - set(attributes["observe_transform"]["facets"]["type"], body["type"])
          - set(attributes["observe_transform"]["facets"]["sourceComponent"], body["source"]["component"])
      # Job
      - context: log
        conditions:
          - body["kind"] == "Job"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["jobName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["jobUid"], body["metadata"]["uid"])
          - set(attributes["observe_transform"]["facets"]["cronJobName"], body["metadata"]["ownerReferences"][0]["name"]) where body["metadata"]["ownerReferences"][0]["kind"] == "CronJob"
          - set(attributes["observe_transform"]["facets"]["cronJobUid"], body["metadata"]["ownerReferences"][0]["uid"]) where body["metadata"]["ownerReferences"][0]["kind"] == "CronJob"
          # spec
          - set(attributes["observe_transform"]["facets"]["completions"], body["spec"]["completions"])
          - set(attributes["observe_transform"]["facets"]["parallelism"], body["spec"]["parallelism"])
          - set(attributes["observe_transform"]["facets"]["activeDeadlineSeconds"], body["spec"]["activeDeadlineSeconds"])
          - set(attributes["observe_transform"]["facets"]["backoffLimit"], body["spec"]["backoffLimit"])
          # status
          - set(attributes["observe_transform"]["facets"]["startTime"], body["status"]["startTime"])
          - set(attributes["observe_transform"]["facets"]["activePods"], body["status"]["active"])
          - set(attributes["observe_transform"]["facets"]["failedPods"], body["status"]["falied"])
          - set(attributes["observe_transform"]["facets"]["succeededPods"], body["status"]["succeeded"])
          - set(attributes["observe_transform"]["facets"]["readyPods"], body["status"]["ready"])
      # CronJob
      - context: log
        conditions:
          - body["kind"] == "CronJob"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["cronJobName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["cronJobUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["schedule"], body["spec"]["schedule"])
          - set(attributes["observe_transform"]["facets"]["suspend"], "Active") where body["spec"]["suspend"] == false
          - set(attributes["observe_transform"]["facets"]["suspend"], "Suspend") where body["spec"]["suspend"] == true
      # DaemonSet
      - context: log
        conditions:
          - body["kind"] == "DaemonSet"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["daemonSetName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["daemonSetUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["updateStrategy"], body["spec"]["updateStrategy"]["type"])
          - set(attributes["observe_transform"]["facets"]["maxUnavailable"], body["spec"]["updateStrategy"]["rollingUpdate"]["maxUnavailable"])
          - set(attributes["observe_transform"]["facets"]["maxSurge"], body["spec"]["updateStrategy"]["rollingUpdate"]["maxSurge"])
          # status
          - set(attributes["observe_transform"]["facets"]["numberReady"], body["status"]["numberReady"])
          - set(attributes["observe_transform"]["facets"]["desiredNumberScheduled"], body["status"]["desiredNumberScheduled"])
          - set(attributes["observe_transform"]["facets"]["currentNumberScheduled"], body["status"]["currentNumberScheduled"])
          - set(attributes["observe_transform"]["facets"]["updatedNumberScheduled"], body["status"]["updatedNumberScheduled"])
          - set(attributes["observe_transform"]["facets"]["numberAvailable"], body["status"]["numberAvailable"])
          - set(attributes["observe_transform"]["facets"]["numberUnavailable"], body["status"]["numberUnavailable"])
          - set(attributes["observe_transform"]["facets"]["numberMisscheduled"], body["status"]["numberMisscheduled"])
          - set(attributes["observe_transform"]["facets"]["status"], "Healthy") where attributes["observe_transform"]["facets"]["numberReady"] == attributes["observe_transform"]["facets"]["desiredNumberScheduled"]
          - set(attributes["observe_transform"]["facets"]["status"], "Unhealthy") where attributes["observe_transform"]["facets"]["numberReady"] != attributes["observe_transform"]["facets"]["desiredNumberScheduled"]
      # StatefulSet
      - context: log
        conditions:
          - body["kind"] == "StatefulSet"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["statefulSetName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["statefulSetUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["serviceName"], body["spec"]["serviceName"])
          - set(attributes["observe_transform"]["facets"]["podManagementPolicy"], body["spec"]["podManagementPolicy"])
          - set(attributes["observe_transform"]["facets"]["desiredReplicas"], body["spec"]["replicas"])
          - set(attributes["observe_transform"]["facets"]["updateStrategy"], body["spec"]["updateStrategy"]["type"])
          - set(attributes["observe_transform"]["facets"]["partition"], body["spec"]["updateStrategy"]["rollingUpdate"]["partition"])
          # status
          - set(attributes["observe_transform"]["facets"]["currentReplicas"], body["status"]["currentReplicas"])
          - set(attributes["observe_transform"]["facets"]["readyReplicas"], body["status"]["readyReplicas"])
          - set(attributes["observe_transform"]["facets"]["status"], "Healthy") where attributes["observe_transform"]["facets"]["readyReplicas"] == attributes["observe_transform"]["facets"]["desiredReplicas"]
          - set(attributes["observe_transform"]["facets"]["status"], "Unhealthy") where attributes["observe_transform"]["facets"]["readyReplicas"] != attributes["observe_transform"]["facets"]["desiredReplicas"]
      - context: log
        conditions:
          - body["kind"] == "ConfigMap"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["configMapName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["configMapUid"], body["metadata"]["uid"])
          - set(attributes["observe_transform"]["facets"]["immutable"], body["immutable"])
      - context: log
        conditions:
          - body["kind"] == "Secret"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["secretName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["secretUid"], body["metadata"]["uid"])
          - set(attributes["observe_transform"]["facets"]["immutable"], body["immutable"])
          - set(attributes["observe_transform"]["facets"]["data"], body["data"])
          - set(attributes["observe_transform"]["facets"]["type"], body["type"])
      - context: log
        conditions:
          - body["kind"] == "PersistentVolume"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["persistentVolumeName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["persistentVolumeUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["capacity"], body["spec"]["capacity"]["storage"])
          - set(attributes["observe_transform"]["facets"]["reclaimPolicy"], body["spec"]["persistentVolumeReclaimPolicy"])
          - set(attributes["observe_transform"]["facets"]["class"], body["spec"]["storageClassName"])
          - set(attributes["observe_transform"]["facets"]["accessModes"], body["spec"]["accessModes"])
          - set(attributes["observe_transform"]["facets"]["volumeMode"], body["spec"]["volumeMode"])
          # status
          - set(attributes["observe_transform"]["facets"]["phase"], body["status"]["phase"])
      - context: log
        conditions:
          - body["kind"] == "PersistentVolumeClaim"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["persistentVolumeClaimName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["persistentVolumeClaimUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["capacityRequests"], body["spec"]["resources"]["requests"]["storage"])
          - set(attributes["observe_transform"]["facets"]["capacityLimits"], body["spec"]["resources"]["limits"]["storage"])
          - set(attributes["observe_transform"]["facets"]["class"], body["spec"]["storageClassName"])
          - set(attributes["observe_transform"]["facets"]["volumeName"], body["spec"]["volumeName"])
          - set(attributes["observe_transform"]["facets"]["desiredAccessModes"], body["spec"]["accessModes"])
          - set(attributes["observe_transform"]["facets"]["volumeMode"], body["spec"]["volumeMode"])
          # status
          - set(attributes["observe_transform"]["facets"]["capacity"], body["status"]["capacity"]["storage"])
          - set(attributes["observe_transform"]["facets"]["phase"], body["status"]["phase"])
          - set(attributes["observe_transform"]["facets"]["currentAccessModes"], body["spec"]["accessModes"])
      - context: log
        conditions:
          - body["kind"] == "Service"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["serviceName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["serviceUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["serviceType"], body["spec"]["type"])
          - set(attributes["observe_transform"]["facets"]["clusterIP"], body["spec"]["clusterIP"])
          - set(attributes["observe_transform"]["facets"]["externalIPs"], body["spec"]["externalIPs"])
          - set(attributes["observe_transform"]["facets"]["sessionAffinity"], body["spec"]["sessionAffinity"])
          - set(attributes["observe_transform"]["facets"]["externalName"], body["spec"]["externalName"])
          - set(attributes["observe_transform"]["facets"]["externalTrafficPolicy"], body["spec"]["externalTrafficPolicy"])
          # ideally it should just be Concat([body["spec"]["ipFamilies"], ","), but
          # that doesn't work for some reason. Since we know ipFamilies can only
          # be either IPv4 or IPv6 (or both), these two conditional set() achieve the same since only one can trigger.
          - set(attributes["observe_transform"]["facets"]["ipFamilies"], "IPv4,IPv6") where Len(body["spec"]["ipFamilies"]) == 2
          - set(attributes["observe_transform"]["facets"]["ipFamilies"], body["spec"]["ipFamilies"][0]) where Len(body["spec"]["ipFamilies"]) == 1
      - context: log
        conditions:
          - body["kind"] == "Ingress"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["ingressName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["ingressUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["class"], body["spec"]["ingressClassName"])
      - context: log
        conditions:
          - body["kind"] == "RoleBinding"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["roleBindingName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["roleBindingUid"], body["metadata"]["uid"])
          - set(attributes["observe_transform"]["facets"]["subjects"], body["subjects"])
          - set(attributes["observe_transform"]["facets"]["role"], body["roleRef"]["name"])
      - context: log
        conditions:
          - body["kind"] == "Role"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["roleName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["roleUid"], body["metadata"]["uid"])
          - set(attributes["observe_transform"]["facets"]["rules"], body["rules"])
          - set(attributes["observe_transform"]["facets"]["role"], body["roleRef"]["name"])
      - context: log
        conditions:
          - body["kind"] == "ClusterRoleBinding"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["clusterRoleBindingName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["clusterRoleBindingUid"], body["metadata"]["uid"])
          - set(attributes["observe_transform"]["facets"]["subjects"], body["subjects"])
          # spec
          - set(attributes["observe_transform"]["facets"]["role"], body["roleRef"]["name"])
      - context: log
        conditions:
          - body["kind"] == "ServiceAccount"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["serviceAccountName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["identifiers"]["serviceAccountUid"], body["metadata"]["uid"])
          # spec
          - set(attributes["observe_transform"]["facets"]["automountToken"], body["automountServiceAccountToken"])

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
          - set(attributes["observe_transform"]["control"]["debug_source"], "watch") where body["object"] != nil and body["type"] != nil
          - set(attributes["observe_transform"]["control"]["debug_source"], "pull") where body["object"] == nil or body["type"] == nil
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
          - set(resource.attributes["clusterName"], attributes["k8s.cluster.name"])
          - set(resource.attributes["clusterUid"], attributes["k8s.cluster.uid"])
          - set(attributes["observe_transform"]["identifiers"]["uid"], attributes["k8s.cluster.uid"])
          - set(attributes["observe_transform"]["identifiers"]["kind"], "Cluster")
          - set(attributes["observe_transform"]["identifiers"]["name"], attributes["k8s.cluster.name"])
          # facets
          - set(attributes["observe_transform"]["facets"]["creationTimestamp"], body["metadata"]["creationTimestamp"])
          - set(attributes["observe_transform"]["facets"]["labels"], body["metadata"]["labels"])
          - set(attributes["observe_transform"]["facets"]["annotations"], body["metadata"]["annotations"])
          # this is a fake object, there is no k8s yaml object for it
          - set(body, "")

service:
  extensions: [health_check]
  pipelines:
      logs/objects:
        receivers: [k8sobjects/objects]
        processors: [memory_limiter, batch, attributes/observe_common, transform/object, observek8sattributes]
        exporters: [otlphttp/observe/base, debug/override]
      logs/cluster:
        receivers: [k8sobjects/cluster]
        processors: [memory_limiter, batch, attributes/observe_common, filter/cluster, transform/cluster]
        exporters: [otlphttp/observe/base, debug/override]
      {{ if .Values.observe.entityToken.use  -}}
      logs/entity:
        receivers: [k8sobjects/objects]
        processors: [memory_limiter, batch, attributes/observe_common, transform/object, observek8sattributes]
        exporters: [otlphttp/observe/entity, debug/override]
      logs/cluster/entity:
        receivers: [k8sobjects/cluster]
        processors: [memory_limiter, batch, attributes/observe_common, filter/cluster, transform/cluster]
        exporters: [otlphttp/observe/entity, debug/override]
      {{- end }}

{{- include "config.service.telemetry" . | nindent 2 }}

 {{- end }}
