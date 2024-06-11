#!/bin/bash

set -ex

# Store password and server name in variables (avoid using environment variables directly in the command)
SERVER_NAME=sonardb2
PASSWORD=$1

# Create a logical server (using az command)
az sql server create \
  --name "$SERVER_NAME" \
  --resource-group devsecops-lab \
  --location australiaeast \
  --admin-user sonar \
  --admin-password "$PASSWORD"

# Configure a firewall rule to allow Azure Services (using az command)
az sql server firewall-rule create \
  --resource-group devsecops-lab \
  --server "$SERVER_NAME" \
  --name AzureServices \
  --start-ip-address 0.0.0.0 \
  --end-ip-address 0.0.0.0

# Create a database in the server (using az command)
az sql db create \
  --resource-group devsecops-lab \
  --server "$SERVER_NAME" \
  --name sonarqubeDb \
  --service-objective S0 \
  --collation SQL_Latin1_General_CP1_CS_AS

# Create a container instance using the official SonarQube image (using az command)
az containerapp create \
  --cpu 2 \
  --memory 4 \
  --environment "devops-app-env" \
  --resource-group "devsecops-lab" \
  --name "sonarqube-app" \
  --image "sonarqube:9.9.4-community" \
  --target-port 9000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 1 \
  --env-vars "SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true" \
            "SONAR_JDBC_USERNAME=sonar" \
            "SONAR_JDBC_PASSWORD=$PASSWORD" \
            "SONAR_JDBC_URL=jdbc:sqlserver://$SERVER_NAME.database.windows.net:1433;database=sonarqubeDb;user=sonar@srv-sqlsonarqube;password=$PASSWORD;encrypt=true;trustServerCertificate=false;hostNameInCertificate=*.database.windows.net;loginTimeout=30"
