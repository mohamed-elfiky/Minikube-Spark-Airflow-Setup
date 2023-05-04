from __future__ import annotations
import os
from datetime import datetime, timedelta
import logging
from airflow import DAG
from airflow.providers.cncf.kubernetes.operators.spark_kubernetes import SparkKubernetesOperator
from airflow.providers.cncf.kubernetes.sensors.spark_kubernetes import SparkKubernetesSensor
from airflow.providers.apache.druid.operators.druid import DruidOperator
from airflow.operators.python_operator import PythonOperator
from airflow.hooks.base_hook import BaseHook
    
DAG_ID = "spark_pipeline_dag"

def get_connection_id():
    conn = BaseHook.get_connection('druid_ingest_conn_id')
    host = conn.host
    port = conn.port
    conn_type = conn.conn_type or "http"
    endpoint = conn.extra_dejson.get("endpoint", "")
    print(f"{conn_type}://{host}:{port}/{endpoint}")

with DAG(
    DAG_ID,
    default_args={"max_active_runs": 1},
    description="submit spark jobs as sparkApplication on kubernetes",
    schedule= "*/10 * * * *", #every 10 mins
    start_date=datetime(2023, 5, 3),
    catchup=False,
) as dag:
    t1 = SparkKubernetesOperator(
        task_id="spark_job",
        namespace="default",
        application_file="spark-job-deployment.yaml",
        kubernetes_conn_id="k8s_id",
        do_xcom_push=True,
        dag=dag,
    )

    t2 = SparkKubernetesSensor(
        task_id="spark_job_monitor",
        namespace="default",
        application_name="{{ task_instance.xcom_pull(task_ids='spark_job')['metadata']['name'] }}",
        dag=dag,
        kubernetes_conn_id="k8s_id",
        attach_log=True
    )
    
    
    t3 = PythonOperator(
        task_id='python_task',
        python_callable=get_connection_id,
        dag=dag
    )
    
    t4 = DruidOperator(task_id='druid_ingest', 
                                json_index_file='druid_spec.json', 
                                druid_ingest_conn_id='druid_ingest_conn_id',
                                timeout=5,
                                max_ingestion_time=3600
                                )
    
    
    t1 >> t2 >> t3 >> t4

