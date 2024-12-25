# main.sh
#!/bin/bash
# Git-Bash-Task-Manager
# Ensure scripts are executable
chmod +x auth.sh tasks.sh

# Source necessary 
source config.sh
source auth.sh
source tasks.sh

# Function to display main menu
main_menu() {
    separator
    echo -e "${GREEN}=== Task Management System ===${NC}"
    echo "1. Register"
    echo "2. Login"
    echo "3. Exit"
}

# Function to display user menu
user_menu() {
    separator
    echo -e "${GREEN}=== Main Menu ===${NC}"
    echo "1. Add Task"
    echo "2. View Tasks"
    echo "3. Edit Task"
    echo "4. Delete Task"
    echo "5. Search Tasks"
    echo "6. Logout"
}

# Main loop
while true; do
    if [ -z "$CURRENT_USER" ]; then
        main_menu
        read -p "Choose an option [1-3]: " option
        case $option in
            1)
                register_user
                ;;
            2)
                login_user
                ;;
            3)
                echo -e "${YELLOW}Goodbye!${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid option, Please choose between 1-3.${NC}"
                ;;
        esac
    else
        user_menu
        echo "[$CURRENT_USER]" | cat -A
        echo "TASK_FILE=[$TASK_FILE]" | cat -A

        read -p "Choose an option [1-6]: " user_option
        case $user_option in
            1)
                add_task
                ;;
            2)
                view_tasks
                ;;
            3)
                edit_task
                ;;
            4)
                delete_task
                ;;
            5)
                search_tasks
                ;;
            6)
                echo -e "${YELLOW}Logged out successfully.${NC}"
                unset CURRENT_USER
                ;;
            *)
                echo -e "${RED}Invalid option. Please choose between 1-6.${NC}"
                ;;
        esac
    fi
    echo ""
done
