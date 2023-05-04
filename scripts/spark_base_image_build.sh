eval $(minikube -p minikube docker-env)

$SPARK_HOME/bin/docker-image-tool.sh -r spark-base -t 1.0.0 -p $SPARK_HOME/kubernetes/dockerfiles/spark/bindings/python/Dockerfile build