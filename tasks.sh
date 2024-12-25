# tasks.sh
#!/bin/bash

source config.sh

# Function to check if a user is logged in
check_user_logged_in() {
    if [ -z "$CURRENT_USER" ]; then
        echo -e "${RED}No user is logged in.${NC}"
        return 1
    fi
}

add_task() {
    check_user_logged_in || return
    separator
    echo -e "${BLUE}=== Add New Task ===${NC}"
    read -p "Enter task description: " description
    if [ -z "$description" ]; then
        echo -e "${RED}Description cannot be empty.${NC}"
        return
    fi
    # Generate task ID safely
    task_id=$(jq --arg user "$CURRENT_USER" 'if .[$user] then (.[$user] | length + 1) else 1 end' "$TASK_FILE")
    if [ -z "$task_id" ]; then
        echo -e "${RED}Failed to generate task ID.${NC}"
        return
    fi
    echo "DEBUG: Generated task_id = $task_id"
    # Create task JSON
    task=$(jq -n \
        --arg id "$task_id" \
        --arg desc "$description" \
        --arg status "Pending" \
        '{
            id: ($id | tonumber),
            description: $desc,
            status: $status
        }')
    echo "DEBUG: Created task JSON: $task"
    # Add task to tasks.json
    tmp=$(mktemp)
    if jq --arg user "$CURRENT_USER" --argjson task "$task" \
        '(.[$user] // []) += [$task]' \
        "$TASK_FILE" > "$tmp"; then
        mv "$tmp" "$TASK_FILE"
        echo -e "${GREEN}Task added successfully.${NC}"
    else
        echo -e "${RED}Failed to add task.${NC}"
        rm "$tmp"
    fi
    echo "DEBUG: Updated tasks.json:"
    cat "$TASK_FILE"
}




view_tasks() {
    check_user_logged_in || return
    separator
    echo -e "${BLUE}=== Your Tasks ===${NC}"
    tasks=$(jq --arg user "$CURRENT_USER" '.[$user] // []' "$TASK_FILE")
    if [ "$(echo "$tasks" | jq length)" -eq 0 ]; then
        echo -e "${YELLOW}No tasks found.${NC}"
        return
    fi
    echo "$tasks" | jq -r '.[] | "\(.id). [\(.status)] \(.description)"'
}

edit_task() {
    check_user_logged_in || return
    separator
    echo -e "${BLUE}=== Edit Task ===${NC}"
    view_tasks
    read -p "Enter task ID to edit: " task_id
    # Check if task exists
    task=$(jq --arg user "$CURRENT_USER" --arg id "$task_id" '.[$user][] | select(.id == ($id | tonumber))' "$TASK_FILE")
    if [ -z "$task" ]; then
        echo -e "${RED}Task not found.${NC}"
        return
    fi
    echo "Leave fields empty to keep current values."
    read -p "Enter new description [$(echo "$task" | jq -r '.description')]: " new_desc
    read -p "Enter new status (Pending/Completed) [$(echo "$task" | jq -r '.status')]: " new_status

    # Update fields if provided
    [ -n "$new_desc" ] && task_description="$new_desc" || task_description=$(echo "$task" | jq -r '.description')
    if [[ "$new_status" =~ ^(Pending|Completed)$ ]]; then
        task_status="$new_status"
    else
        task_status=$(echo "$task" | jq -r '.status')
    fi

    # Update the task in tasks.json
    tmp=$(mktemp)
    jq --arg user "$CURRENT_USER" --arg id "$task_id" \
        --arg desc "$task_description" \
        --arg status "$task_status" \
        '(.[$user][] | select(.id == ($id | tonumber))) |= {
            id: ($id | tonumber),
            description: $desc,
            status: $status
        }' "$TASK_FILE" > "$tmp" && mv "$tmp" "$TASK_FILE"
    echo -e "${GREEN}Task updated successfully.${NC}"
}

delete_task() {
    check_user_logged_in || return
    separator
    echo -e "${BLUE}=== Delete Task ===${NC}"
    view_tasks
    read -p "Enter task ID to delete: " task_id
    # Check if task exists
    task_exists=$(jq --arg user "$CURRENT_USER" --arg id "$task_id" '.[$user][] | select(.id == ($id | tonumber))' "$TASK_FILE")
    if [ -z "$task_exists" ]; then
        echo -e "${RED}Task not found.${NC}"
        return
    fi
    # Confirm deletion
    read -p "Are you sure you want to delete task ID $task_id? (y/n): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        tmp=$(mktemp)
        jq --arg user "$CURRENT_USER" --arg id "$task_id" 'del(.[$user][] | select(.id == ($id | tonumber)))' "$TASK_FILE" > "$tmp" && mv "$tmp" "$TASK_FILE"
        echo -e "${GREEN}Task deleted successfully.${NC}"
    else
        echo -e "${YELLOW}Deletion canceled.${NC}"
    fi
}

search_tasks() {
    check_user_logged_in || return
    separator
    echo -e "${BLUE}=== Search Tasks ===${NC}"
    read -p "Enter keyword to search in descriptions: " keyword
    if [ -z "$keyword" ]; then
        echo -e "${RED}Keyword cannot be empty.${NC}"
        return
    fi
    matches=$(jq --arg user "$CURRENT_USER" --arg kw "$keyword" '.[$user][] | select(.description | test($kw; "i"))' "$TASK_FILE")
    if [ -z "$matches" ]; then
        echo -e "${YELLOW}No matching tasks found.${NC}"
        return
    fi
    echo "$matches" | jq -r '.[] | "\(.id). [\(.status)] \(.description)"'
}
