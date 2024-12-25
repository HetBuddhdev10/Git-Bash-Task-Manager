# auth.sh
#!/bin/bash

source config.sh

register_user() {
    separator
    echo -e "${BLUE}=== User Registration ===${NC}"
    read -p "Enter username: " username
    # Check if user exists
    if jq -e --arg user "$username" '.[$user]' "$USER_FILE" > /dev/null; then
        echo -e "${RED}Username already exists. Please choose another.${NC}"
        return 1
    fi
    read -s -p "Enter password: " password
    echo
    read -s -p "Confirm password: " password_confirm
    echo
    if [ "$password" != "$password_confirm" ]; then
        echo -e "${RED}Passwords do not match.${NC}"
        return 1
    fi
    # Hash the password
    hashed_password=$(echo -n "$password" | sha256sum | awk '{print $1}')
    # Add user to users.json
    tmp=$(mktemp)
    jq --arg user "$username" --arg pass "$hashed_password" '. + {($user): {password: $pass}}' "$USER_FILE" > "$tmp" && mv "$tmp" "$USER_FILE"
    echo -e "${GREEN}User registered successfully.${NC}"
}

login_user() {
    separator
    echo -e "${BLUE}=== User Login ===${NC}"
    read -p "Enter username: " username
    read -s -p "Enter password: " password
    echo
    # Hash the entered password
    hashed_password=$(echo -n "$password" | sha256sum | awk '{print $1}')
    # Verify user
    stored_hash=$(jq -r --arg user "$username" '.[$user].password' "$USER_FILE")
    if [ "$stored_hash" == "null" ]; then
        echo -e "${RED}User does not exist.${NC}"
        return 1
    elif [ "$hashed_password" != "$stored_hash" ]; then
        echo -e "${RED}Incorrect password.${NC}"
        return 1
    else
        echo -e "${GREEN}Login successful.${NC}"
        CURRENT_USER=$(echo -n "$username" | tr -d '\r')
        CURRENT_USER=$(sed 's/\r//g' <<< "$username")
        
        echo "[$CURRENT_USER]" | cat -A
        echo "TASK_FILE=[$TASK_FILE]" | cat -A


        return 0
    fi
}



