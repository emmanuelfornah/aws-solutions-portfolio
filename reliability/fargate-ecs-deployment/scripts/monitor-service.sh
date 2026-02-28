#!/bin/bash

# Monitor ECS Service and View Logs
# This script checks service status, lists tasks, and retrieves CloudWatch logs

set -e

# Configuration
CLUSTER_NAME="lab-cluster-fargate"
SERVICE_NAME="url-checker-service"
REGION="us-west-2"
LOG_GROUP="/ecs/url-checker"

echo "Monitoring ECS Service..."
echo "Cluster: $CLUSTER_NAME"
echo "Service: $SERVICE_NAME"
echo "Region: $REGION"
echo ""

# Function to display service status
show_service_status() {
  echo "=== Service Status ==="
  aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --region "$REGION" \
    --query 'services[0].{Name:serviceName,Status:status,DesiredCount:desiredCount,RunningCount:runningCount,PendingCount:pendingCount}' \
    --output table
  echo ""
}

# Function to list tasks
list_tasks() {
  echo "=== Tasks ==="
  TASK_ARNS=$(aws ecs list-tasks \
    --cluster "$CLUSTER_NAME" \
    --service-name "$SERVICE_NAME" \
    --region "$REGION" \
    --query 'taskArns' \
    --output text)
  
  if [ -z "$TASK_ARNS" ]; then
    echo "No tasks currently running."
    echo ""
    
    # Check for stopped tasks
    echo "Checking for recently stopped tasks..."
    STOPPED_TASK_ARNS=$(aws ecs list-tasks \
      --cluster "$CLUSTER_NAME" \
      --service-name "$SERVICE_NAME" \
      --desired-status STOPPED \
      --region "$REGION" \
      --query 'taskArns[0:5]' \
      --output text)
    
    if [ -n "$STOPPED_TASK_ARNS" ]; then
      echo "Recent stopped tasks found."
      echo "$STOPPED_TASK_ARNS"
      
      # Get details of most recent stopped task
      LATEST_TASK=$(echo "$STOPPED_TASK_ARNS" | awk '{print $1}')
      if [ -n "$LATEST_TASK" ]; then
        echo ""
        echo "=== Latest Stopped Task Details ==="
        aws ecs describe-tasks \
          --cluster "$CLUSTER_NAME" \
          --tasks "$LATEST_TASK" \
          --region "$REGION" \
          --query 'tasks[0].{TaskArn:taskArn,LastStatus:lastStatus,StoppedReason:stoppedReason,StoppedAt:stoppedAt,CPU:cpu,Memory:memory}' \
          --output table
        
        # Extract task ID for logs
        TASK_ID=$(echo "$LATEST_TASK" | awk -F'/' '{print $NF}')
        echo ""
        echo "Task ID: $TASK_ID"
      fi
    else
      echo "No stopped tasks found."
    fi
  else
    echo "Active tasks:"
    aws ecs describe-tasks \
      --cluster "$CLUSTER_NAME" \
      --tasks $TASK_ARNS \
      --region "$REGION" \
      --query 'tasks[*].{TaskArn:taskArn,LastStatus:lastStatus,HealthStatus:healthStatus,CPU:cpu,Memory:memory}' \
      --output table
    
    # Get task ID from first task
    TASK_ID=$(echo "$TASK_ARNS" | awk '{print $1}' | awk -F'/' '{print $NF}')
    echo ""
    echo "Task ID: $TASK_ID"
  fi
  echo ""
}

# Function to view CloudWatch logs
view_logs() {
  echo "=== CloudWatch Logs ==="
  
  # Check if log group exists
  LOG_GROUP_EXISTS=$(aws logs describe-log-groups \
    --log-group-name-prefix "$LOG_GROUP" \
    --region "$REGION" \
    --query 'logGroups[0].logGroupName' \
    --output text 2>/dev/null || echo "")
  
  if [ -z "$LOG_GROUP_EXISTS" ] || [ "$LOG_GROUP_EXISTS" == "None" ]; then
    echo "Log group not found: $LOG_GROUP"
    echo "Logs may not be available yet. Wait for task to start running."
    return
  fi
  
  # Get log streams (most recent first)
  LOG_STREAMS=$(aws logs describe-log-streams \
    --log-group-name "$LOG_GROUP" \
    --order-by LastEventTime \
    --descending \
    --max-items 5 \
    --region "$REGION" \
    --query 'logStreams[*].logStreamName' \
    --output text)
  
  if [ -z "$LOG_STREAMS" ]; then
    echo "No log streams found in log group: $LOG_GROUP"
    return
  fi
  
  echo "Recent log streams:"
  echo "$LOG_STREAMS"
  echo ""
  
  # Get logs from most recent stream
  LATEST_STREAM=$(echo "$LOG_STREAMS" | awk '{print $1}')
  echo "Fetching logs from: $LATEST_STREAM"
  echo "---"
  
  aws logs get-log-events \
    --log-group-name "$LOG_GROUP" \
    --log-stream-name "$LATEST_STREAM" \
    --region "$REGION" \
    --query 'events[*].message' \
    --output text
  
  echo "---"
  echo ""
}

# Function to get task events
show_task_events() {
  echo "=== Service Events (Last 10) ==="
  aws ecs describe-services \
    --cluster "$CLUSTER_NAME" \
    --services "$SERVICE_NAME" \
    --region "$REGION" \
    --query 'services[0].events[0:10].{Time:createdAt,Message:message}' \
    --output table
  echo ""
}

# Main execution
show_service_status
list_tasks
show_task_events
view_logs

# Provide helpful commands
echo "=== Useful Commands ==="
echo ""
echo "Watch service status:"
echo "  watch -n 5 'aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --query \"services[0].{Status:status,Running:runningCount,Pending:pendingCount}\"'"
echo ""
echo "Tail logs (if task is running):"
echo "  aws logs tail $LOG_GROUP --follow --region $REGION"
echo ""
echo "List all tasks (including stopped):"
echo "  aws ecs list-tasks --cluster $CLUSTER_NAME --service-name $SERVICE_NAME --desired-status STOPPED --region $REGION"
echo ""
echo "Delete service:"
echo "  aws ecs delete-service --cluster $CLUSTER_NAME --service $SERVICE_NAME --force --region $REGION"
echo ""
