#!/usr/bin/env bash
# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-
# notes on helm_install.sh
# -----------------------------------------------------------------------
#
# "`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-'"`-._,-

set -e

echo   "*****************************************************"
echo   "create namespace"
echo   "*****************************************************"
ns='druid'

echo "checking namespace ${ns}"
if [ -z "kubectl get namespace | grep $ns" ]; then
    echo   "- creating $ns..."
    kubectl create namespace $ns
fi

echo "checking namespace ${ns}"
if [ -z "kubectl get namespace | grep $ns" ]; then
    echo   "- creating $ns..."
    kubectl create namespace $ns
fi



echo   "*****************************************************"
echo   "minio deployment"
echo   "*****************************************************"

helm repo add minio https://charts.min.io/
helm upgrade --install minio minio/minio \
					-n druid \
                    -f ./minio/minio_values.yaml


echo   "*****************************************************"
echo   "druid deployment"
echo   "*****************************************************"

cd druid
helm dependency update helm/druid
helm upgrade --install druid helm/druid --namespace druid -f druid_values.yaml --create-namespace


echo   "*****************************************************"
echo   "superset deployment"
echo   "*****************************************************"

helm repo add minio https://charts.min.io/
helm upgrade --install superset superset/superset \
					-n superset \
                    -f ./superset/superset_values.yaml




echo   "*****************************************************"
echo   "spark deployment"
echo   "*****************************************************"
# https://github.com/rovio/rovio-ingest spark connector jdbc
# https://gist.github.com/vivek-balakrishnan-rovio/d7ac058d7a70cccf5f4165e8aeed9e9c
helm repo add spark-operator https://googlecloudplatform.github.io/spark-on-k8s-operator
helm upgrade --install spark spark-operator/spark-operator --set webhook.enable=true
kubectl create serviceaccount spark -n airflow
kubectl create clusterrolebinding spark-role --clusterrole=edit --serviceaccount=airflow:spark


echo   "*****************************************************"
echo   "airflow deployment"
echo   "*****************************************************"

helm repo add airflow-stable https://airflow-helm.github.io/charts
helm upgrade --install \
  airflow \
  airflow-stable/airflow \
  --namespace airflow \
  --values ./airflow/airflow_values.yaml

"*************************************************************"
helm repo add apache-airflow https://airflow.apache.org

helm upgrade --install airflow -f values.yaml apache-airflow/airflow 