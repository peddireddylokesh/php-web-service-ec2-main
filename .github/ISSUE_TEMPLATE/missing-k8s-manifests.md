---
title: Missing Kubernetes Manifests
labels: bug, k8s
assignees: peddireddylokesh
---

## Missing Kubernetes Manifests

The workflow detected missing required Kubernetes manifest files.

### Details

The following files are missing:

{% if env.MISSING_FILES %}
{{ env.MISSING_FILES }}
{% else %}
- One or more required Kubernetes manifest files
{% endif %}

### Impact

Deployment may fail due to missing configuration files.

### Resolution

Please create the missing manifest files in the `kubernetes/` directory. You can use the verification script to generate templates:

```bash
./scripts/verify-manifests.sh
```

Or create them manually with appropriate configuration.
