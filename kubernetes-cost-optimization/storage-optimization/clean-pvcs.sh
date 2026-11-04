#!/bin/bash

echo "=== Kubernetes Conditional PVC Snapshot & Cleanup ==="
echo "Scanning all namespaces for unused PVCs..."

### Auto-detect the available VolumeSnapshotClass in the cluster (AWS, Azure, GCP)
snapshot_class=$(kubectl get volumesnapshotclass -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -z "$snapshot_class" ]; then
    echo "WARNING: No VolumeSnapshotClass found in this cluster!"
    echo "Automatic snapshot creation for production PVCs will be skipped."
else
    echo "Detected VolumeSnapshotClass: $snapshot_class"
fi

### Collect all PVC names currently mounted by any Pod in any namespace
mounted_pvcs=$(kubectl get pods -A -o json | jq -r '.items[].spec.volumes[]? | select(.persistentVolumeClaim != null) | .persistentVolumeClaim.claimName' | sort -u)

orphaned_count=0

### Read all PVC info into an array, including the environment label
mapfile -t pvc_items < <(kubectl get pvc -A -o json | jq -r '.items[] | "\(.metadata.namespace) \(.metadata.name) \(.metadata.ownerReferences // [] | length) \(.metadata.labels.environment // "none")"')

### Iterate through the array cleanly
for item in "${pvc_items[@]}"; do
    read -r ns pvc owner_count env_label <<< "$item"
    [ -z "$pvc" ] && continue

### Skip if managed by a StatefulSet, Helm, etc. (has owner references)
    if [ -n "$owner_count" ] && [ "$owner_count" -gt 0 ]; then
        continue
    fi

### Check if the PVC is present in the mounted volumes list
    if ! echo "$mounted_pvcs" | grep -qx "$pvc"; then
        echo "-----------------------------------------------------------------"
        echo "Found orphaned PVC: $pvc in namespace: $ns (Environment: $env_label)"
        orphaned_count=$((orphaned_count + 1))

### Conditional Snapshot Logic based strictly on the label
        if [ "$env_label" = "prod" ] || [ "$env_label" = "production" ]; then
            echo "-> [PRODUCTION] PVC detected. Creating backup snapshot..."

            if [ -n "$snapshot_class" ]; then
                timestamp=$(date +%Y%m%d-%H%M%S)
                snapshot_name="${pvc}-snap-${timestamp}"

                kubectl apply -f - <<EOF
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: ${snapshot_name}
  namespace: ${ns}
spec:
  volumeSnapshotClassName: ${snapshot_class}
  source:
    persistentVolumeClaimName: ${pvc}
EOF

### Wait for the snapshot to become ready to use
                echo "-> Waiting for snapshot to complete..."
                ready="false"
                for i in {1..60}; do
                    ready=$(kubectl get volumesnapshot "$snapshot_name" -n "$ns" -o jsonpath='{.status.readyToUse}' 2>/dev/null)
                    if [ "$ready" = "true" ]; then
                        echo "-> Snapshot successfully created and ready!"
                        break
                    fi
                    sleep 5
                done

                if [ "$ready" != "true" ]; then
                    echo "-> ERROR: Snapshot timed out or failed for production PVC $pvc. Skipping deletion for safety."
                    continue
                fi
            else
                echo "-> ERROR: Production PVC found, but no VolumeSnapshotClass available! Skipping deletion for safety."
                continue
            fi
        else
            echo "-> [NON-PRODUCTION] Skipping snapshot creation."
        fi

### Proceed to delete the orphaned PVC
        echo "-> Deleting PVC: $pvc from namespace: $ns..."
        kubectl delete pvc "$pvc" -n "$ns"
    fi
done

echo "-----------------------------------------------------------------"
if [ "$orphaned_count" -eq 0 ]; then
    echo "Scan complete! Result: No unused or orphaned PVCs found. All PVCs are actively in use or managed."
else
    echo "Scan complete! Processed $orphaned_count orphaned PVC(s)."
fi
