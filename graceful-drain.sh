#!/bin/bash

if [ $# -lt 2 ]; then
	echo "error: usage ./graceful-drain.sh --node NODENAME" >&2
	exit 3
fi

echo "condoning node $2"
# echo debug kubectl cordon node $2
kubectl get pods --all-namespaces --field-selector="spec.nodeName=$2" -o jsonpath='{range .items[*]}{.metadata.namespace},{.metadata.name},{.metadata.ownerReferences[0].kind},{.metadata.ownerReferences[0].name}{"\n"}{end}' | \
while IFS="," read namespace name ownerKind ownerName ; do
 	if [ "$ownerKind" != "ReplicaSet" ] ; then
		# ignore daemonsets or other owners
		continue
 	fi
 	IFS="," read readyReplicas replicaOwner replicaOwnerName <<< $(kubectl get -n $namespace -o jsonpath='{.status.readyReplicas},{.metadata.ownerReferences[0].kind},{.metadata.ownerReferences[0].name}' ReplicaSet $ownerName)
	if [ "$replicaOwner" != "Deployment" ] ; then
		echo "error: $replicaOwner not expected" >&2
		exit 2
 	fi
	if [ $readyReplicas -le 1 ] ; then
		echo "rolling restarting $replicaOwner $replicaOwnerName with $readyReplicas ready replicas"
		# echo debug kubectl -n $namespace rollout restart $replicaOwner $replicaOwnerName &
	else
    echo "deleting pod $name owned by $replicaOwner $replicaOwnerName with $readyReplicas ready replicas"
	# echo debug kubectl -n $namespace delete pod $name &
	fi
	while [ $( jobs | wc -l ) -ge 4 ]; do sleep 1; done
done
