#!/bin/bash

# Имя кластера и API-сервер
CLUSTER_NAME=$(kubectl config view -o jsonpath='{.clusters[0].name}')
CLUSTER_SERVER=$(kubectl config view -o jsonpath='{.clusters[0].cluster.server}')
CA_CERT=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d)

# Сгенерировать пользователей
for USER in viewer-user operator-user admin-user; do
  openssl genrsa -out ${USER}.key 2048
  openssl req -new -key ${USER}.key -out ${USER}.csr -subj "/CN=${USER}"
  openssl x509 -req -in ${USER}.csr -CA <(echo "$CA_CERT") -CAkey ~/.minikube/ca.key -CAcreateserial -out ${USER}.crt -days 365
done

# Добавить пользователей в kubeconfig
for USER in viewer-user operator-user admin-user; do
  kubectl config set-credentials ${USER} --client-certificate=${USER}.crt --client-key=${USER}.key
  kubectl config set-context ${USER}-context --cluster=${CLUSTER_NAME} --user=${USER}
done