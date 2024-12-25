# config.sh
#!/bin/bash

# File paths
USER_FILE="data/users.json"
TASK_FILE="data/tasks.json"

# Colors for output
GREEN="\e[32m"
YELLOW="\e[33m"
RED="\e[31m"
BLUE="\e[34m"
NC="\e[0m" # No Color

# Function to display a separator
separator() {
    echo -e "${BLUE}==============================${NC}"
}
