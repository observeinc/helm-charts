{{- define "observe.deployment.clusterEvents.config" -}}
extensions:
  # https://github.com/open-telemetry/opentelemetry-helm-charts/issues/816
  # 0.0.0.0 is hack for ipv6 on eks clusters
  health_check:
      endpoint: "0.0.0.0:13133"
receivers:
  # this is used to create a cluster resource by pulling namespaces and then dropping all but kube-system with filter processor
  k8sobjects/cluster:
    auth_type: serviceAccount
    objects:
      - name: namespaces
        mode: pull
        interval: 15m
  # this pulls all objects listed below
  k8sobjects/objects_pull:
    auth_type: serviceAccount
    objects:
      ## P1
      - {name: events, mode: pull, interval: 15m}
      - {name: pods, mode: pull, interval: 15m}
      - {name: namespaces, mode: pull, interval: 15m}
      - {name: nodes, mode: pull, interval: 15m}
      - {name: deployments, mode: pull, interval: 15m}
      - {name: replicasets, mode: pull, interval: 15m}
      - {name: configmaps, mode: pull, interval: 15m}
      - {name: endpoints, mode: pull, interval: 15m}
      ## P2
      - {name: jobs, mode: pull, interval: 15m}
      - {name: cronjobs, mode: pull, interval: 15m}
      - {name: daemonsets, mode: pull, interval: 15m}
      - {name: statefulsets, mode: pull, interval: 15m}
      - {name: services, mode: pull, interval: 15m}
      - {name: ingresses, mode: pull, interval: 15m}
      - {name: secrets, mode: pull, interval: 15m}
      - {name: persistentvolumeclaims, mode: pull, interval: 15m}
      - {name: persistentvolumes, mode: pull, interval: 15m}
      - {name: storageclasses, mode: pull, interval: 15m}
      - {name: roles, mode: pull, interval: 15m}
      - {name: rolebindings, mode: pull, interval: 15m}
      - {name: clusterroles, mode: pull, interval: 15m}
      - {name: clusterrolebindings, mode: pull, interval: 15m}
      - {name: serviceaccounts, mode: pull, interval: 15m}
  k8sobjects/objects_watch:
    auth_type: serviceAccount
    objects:
      ## P1
      - {name: events, mode: watch}
      - {name: pods, mode: watch}
      - {name: namespaces, mode: watch}
      - {name: nodes, mode: watch}
      - {name: deployments, mode: watch}
      - {name: replicasets, mode: watch}
      - {name: configmaps, mode: watch}
      - {name: endpoints, mode: watch}
      ## P2
      - {name: jobs, mode: watch}
      - {name: cronjobs, mode: watch}
      - {name: daemonsets, mode: watch}
      - {name: statefulsets, mode: watch}
      - {name: services, mode: watch}
      - {name: ingresses, mode: watch}
      - {name: secrets, mode: watch}
      - {name: persistentvolumeclaims, mode: watch}
      - {name: persistentvolumes, mode: watch}
      - {name: storageclasses, mode: watch}
      - {name: roles, mode: watch}
      - {name: rolebindings, mode: watch}
      - {name: clusterroles, mode: watch}
      - {name: clusterrolebindings, mode: watch}
      - {name: serviceaccounts, mode: watch}
processors:
  observek8sattributes:
  batch/k8s:
    send_batch_size: 100
    send_batch_max_size: 100
  k8sattributes:
    extract:
      annotations:
      - from: pod
        key_regex: (.*)
        tag_name: $$1
      labels:
      - from: pod
        key_regex: (.*)
        tag_name: $$1
      metadata:
      - k8s.namespace.name
      - k8s.deployment.name
      - k8s.statefulset.name
      - k8s.daemonset.name
      - k8s.cronjob.name
      - k8s.job.name
      - k8s.node.name
      - k8s.pod.name
      - k8s.pod.uid
      - k8s.pod.start_time
      - k8s.cluster.uid
      - k8s.node.name
      - k8s.node.uid
    passthrough: false
    pod_association:
    - sources:
      - from: resource_attribute
        name: k8s.pod.ip
    - sources:
      - from: resource_attribute
        name: k8s.pod.uid
    - sources:
      - from: connection

  resourcedetection/cloud:
    detectors: ["eks","gcp", "ecs", "ec2", "azure"]
    timeout: 2s
    override: false
  attributes/observe_common:
    actions:
      - key: k8s.cluster.name
        action: insert
        value: ${env:OBSERVE_CLUSTER_NAME}
      - key: k8s.cluster.uid
        action: insert
        value:  ${env:OBSERVE_CLUSTER_UID}
  # attributes to append to objects
  attributes/observe_object_pull:
    actions:
      - key: objectSource
        action: insert
        value: object_pull
  # attributes to append to objects
  attributes/observe_object_watch:
    actions:
      - key: objectSource
        action: insert
        value: object_watch
  # attributes to append to objects
  attributes/observe_object_final:
    actions:
      - key: object_log_pipeline
        action: insert
        value: log
  attributes/observe_filter:
    actions:
      - key: observe_filter
        action: insert
        value: objects_pull_watch
  # transform for k8s objects
  transform/object:
    error_mode: ignore
    log_statements:
      # Comment logic
      - context: log
        statements:
          # unwrapping for the object_watch stream
          - set(attributes["observe_transform"]["control"]["isDelete"], true) where attributes["objectSource"] == "object_watch" and body["type"] == "DELETED"
          - set(body, body["object"]) where attributes["objectSource"] == "object_watch"
          # native columns: valid_from, valid_to, kind
          - set(attributes["observe_transform"]["valid_from"], observed_time_unix_nano)
          - set(attributes["observe_transform"]["valid_to"], Int(observed_time_unix_nano) + 5400000000000)
          - set(attributes["observe_transform"]["kind"], body["kind"])
          # control
          - set(attributes["observe_transform"]["control"]["isDelete"], false) where attributes["observe_transform"]["control"]["isDelete"] == nil
          - set(attributes["observe_transform"]["control"]["version"], body["metadata"]["resourceVersion"])
          - set(attributes["observe_transform"]["control"]["debug_objectSource"], attributes["objectSource"])
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
          - set(attributes["observe_transform"]["facets"]["ownerReferences"], body["metadata"]["ownerReferences"])
          - set(attributes["observe_transform"]["facets"]["labels"], body["metadata"]["labels"])
          - set(attributes["observe_transform"]["facets"]["annotations"], body["metadata"]["annotations"])
      # For Pod
      - context: log
        conditions:
          - body["kind"] == "Pod"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["podName"], body["metadata"]["name"])
          - set(attributes["observe_transform"]["facets"]["phase"], body["status"]["phase"])
          - set(attributes["observe_transform"]["facets"]["status"], attributes["observe_transform.facets.status"])
          - set(attributes["observe_transform"]["facets"]["podIP"], body["status"]["podIP"])
          - set(attributes["observe_transform"]["facets"]["qosClass"], body["status"]["qosClass"])
          - set(attributes["observe_transform"]["facets"]["startTime"], body["status"]["startTime"])
          - set(attributes["observe_transform"]["facets"]["containerStatuses"], body["status"]["containerStatuses"])
          ### conditions
          - set(attributes["observe_transform"]["facets"]["conditions"]["conditions_array"],body["status"]["conditions"])
          #### flatten array to object
          - flatten(attributes["observe_transform"]["facets"]["conditions"])
          #### set value in cache to type name to replace autogenerated name from flatten
          - set(cache["conditions_array.0"],attributes["observe_transform"]["facets"]["conditions"]["conditions_array.0"]["type"])
          - set(cache["conditions_array.1"],attributes["observe_transform"]["facets"]["conditions"]["conditions_array.1"]["type"])
          - set(cache["conditions_array.2"],attributes["observe_transform"]["facets"]["conditions"]["conditions_array.2"]["type"])
          - set(cache["conditions_array.3"],attributes["observe_transform"]["facets"]["conditions"]["conditions_array.3"]["type"])
          - set(cache["conditions_array.4"],attributes["observe_transform"]["facets"]["conditions"]["conditions_array.4"]["type"])
          #### remove type key from flattened object
          - delete_key(attributes["observe_transform"]["facets"]["conditions"]["conditions_array.0"],"type")
          - delete_key(attributes["observe_transform"]["facets"]["conditions"]["conditions_array.1"],"type")
          - delete_key(attributes["observe_transform"]["facets"]["conditions"]["conditions_array.2"],"type")
          - delete_key(attributes["observe_transform"]["facets"]["conditions"]["conditions_array.3"],"type")
          - delete_key(attributes["observe_transform"]["facets"]["conditions"]["conditions_array.4"],"type")
          #### replace autogenerated name from flatten with type name from cache
          - replace_all_patterns(attributes["observe_transform"]["facets"]["conditions"], "key", "conditions_array.0", cache["conditions_array.0"])
          - replace_all_patterns(attributes["observe_transform"]["facets"]["conditions"], "key", "conditions_array.1", cache["conditions_array.1"])
          - replace_all_patterns(attributes["observe_transform"]["facets"]["conditions"], "key", "conditions_array.2", cache["conditions_array.2"])
          - replace_all_patterns(attributes["observe_transform"]["facets"]["conditions"], "key", "conditions_array.3", cache["conditions_array.3"])
          - replace_all_patterns(attributes["observe_transform"]["facets"]["conditions"], "key", "conditions_array.4", cache["conditions_array.4"])
      # For Event
      - context: log
        conditions:
          - body["kind"] == "Event"
        statements:
          - set(attributes["observe_transform"]["identifiers"]["involvedObject"], body["involvedObject"])
          - set(attributes["observe_transform"]["facets"]["firstTimestamp"], body["firstTimestamp"]) where body["kind"] == "Event"
          - set(attributes["observe_transform"]["facets"]["lastTimestamp"], body["lastTimestamp"]) where body["kind"] == "Event"
          - set(attributes["observe_transform"]["facets"]["message"], body["message"]) where body["kind"] == "Event"
          - set(attributes["observe_transform"]["facets"]["reason"], body["reason"]) where body["kind"] == "Event"
          - set(attributes["observe_transform"]["facets"]["count"], body["count"]) where body["kind"] == "Event"
  # drop all namespace except kube-system
  filter/cluster:
    error_mode: ignore
    logs:
      log_record:
        - 'attributes["observe_transform"]["identifiers"]["name"] != "kube-system"'
  # transform for creating cluster resource
  transform/cluster:
    error_mode: ignore
    log_statements:
      - context: log
        statements:
          - set(attributes["observe_transform"]["identifiers"]["kind"], "Cluster")
          - set(attributes["observe_transform"]["identifiers"]["source"], attributes["observe_transform"]["identifiers"]["name"])
          - delete_key(attributes["observe_transform"]["identifiers"], "name")
          - delete_key(attributes["observe_transform"]["identifiers"], "nodeName")
          - delete_key(attributes["observe_transform"]["identifiers"], "uid")
  #########################
# use set command line arguments
exporters:
  otlphttp/observe:
    endpoint: "https://101.collect.observe-eng.com/v2/otel"
    headers:
      authorization: "Bearer ds1PWYJz3K8ZagZfrjd8:JzTQrGzdg0bJtMjH1dEAHtRxxn3iXuf_"
connectors:
  forward/watch:
  forward/pull:
service:
  pipelines:
    logs/objects_watch:
      receivers: [k8sobjects/objects_watch]
      processors: [memory_limiter, batch/k8s, attributes/observe_object_watch, observek8sattributes]
      exporters: [forward/watch]
    logs/objects_pull:
      receivers: [k8sobjects/objects_pull]
      processors: [memory_limiter, batch/k8s, attributes/observe_object_pull, observek8sattributes]
      exporters: [forward/pull]
    logs:
      receivers: [forward/pull,forward/watch]
      processors: [memory_limiter, batch/k8s, resourcedetection/cloud, k8sattributes, attributes/observe_common, attributes/observe_object_final, attributes/observe_filter, transform/object]
      exporters: [otlphttp/observe]
    logs/cluster:
      receivers: [k8sobjects/cluster]
      processors: [memory_limiter, batch/k8s, resourcedetection/cloud, k8sattributes, attributes/observe_common, transform/object, filter/cluster, transform/cluster]
      exporters: [otlphttp/observe]
{{- end }}
