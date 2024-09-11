#!/usr/bin/env python3

import pytest
import base64 
import json, yaml
import re
from . import helpers as h


@pytest.mark.tags("default.yaml", "observe")
def test_errors_logs(kube_client, helm_config):
     # List all pods in the specified namespace
    pods = kube_client.list_namespaced_pod(namespace=helm_config['namespace'])
    
