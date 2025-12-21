#!/bin/bash

kind create cluster --config dev-cluster.yaml
kind create cluster --config prod-cluster.yaml


# How multiple cluster works with kubeconfig
# How clusters in different vpc can communicate each other