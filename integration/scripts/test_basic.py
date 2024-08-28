import pytest





# def test_list_pods(kube_client):
#     print("Listing pods with their IPs:")
#     ret = kube_client.list_pod_for_all_namespaces(watch=False)
#     for i in ret.items:
#         print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))

# def test_list_pods_2(kube_client):
#     print("Listing pods with their IPs:")
#     ret = kube_client.list_pod_for_all_namespaces(watch=False)
#     for i in ret.items:
#         print("%s\t%s\t%s" % (i.status.pod_ip, i.metadata.namespace, i.metadata.name))