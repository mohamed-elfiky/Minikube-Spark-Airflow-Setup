FROM apache/airflow:2.6.0
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
         vim \
  && apt-get autoremove -yqq --purge \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# RUN mkdir ${AIRFLOW_HOME}/custom_log


# COPY log_config.py ${AIRFLOW_HOME}/config/log_config.py

USER airflow

RUN pip install --no-cache-dir apache-airflow-providers-cncf-kubernetes kubernetes apache-airflow-providers-apache-druid
