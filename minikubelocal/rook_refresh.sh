#!/bin/bash -e

kubectl -n rook-ceph delete pod -l app=rook-ceph-mgr
kubectl -n rook-ceph delete pod -l app=rook-ceph-mon
