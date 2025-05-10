#!/bin/bash

#
# Global Environment / Defaults
#
# Kafka Connect endpoint
CONNECT_HOST="http://localhost:8083"

# S3 Defaults
DEFAULT_S3_BUCKET="${DEFAULT_S3_BUCKET:-warehouse}"
S3_ENDPOINT="${S3_ENDPOINT:-http://localhost:4566}"

# Connector Config Directory
CONFIG_DIR="${CONFIG_DIR:-./kafka-connect/connectors-config}"

#####################################
# Connector Functions
#####################################

list_connectors() {
    echo "Fetching list of connectors..."
    curl -s "$CONNECT_HOST/connectors" | jq .
}

register_connector() {
    if ! command -v jq &> /dev/null; then
        echo "jq is required but not installed. Please install jq."
        return 1
    fi

    if [ ! -d "$CONFIG_DIR" ]; then
        echo "Config directory '$CONFIG_DIR' does not exist!"
        return 1
    fi

    # List all JSON files in the config directory
    echo "Listing connector config files in '$CONFIG_DIR'..."
    mapfile -t config_files < <(ls -1 "$CONFIG_DIR"/*.json 2>/dev/null)
    if [ ${#config_files[@]} -eq 0 ]; then
        echo "No .json config files found in $CONFIG_DIR!"
        return 1
    fi

    echo "Available config files:"
    for i in "${!config_files[@]}"; do
        echo "$((i+1))) ${config_files[$i]}"
    done

    # Prompt user to select a config file
    read -p "Select a config file to register: " selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#config_files[@]}" ]; then
        echo "Invalid selection."
        return 1
    fi

    chosen_file="${config_files[$((selection-1))]}"
    echo "Registering connector from file: $chosen_file"

    # POST the config file to the Connect REST API
    curl -X POST -H "Content-Type: application/json" \
         --data @"$chosen_file" \
         "$CONNECT_HOST/connectors"

    echo -e "\nConnector registration request sent."
}

check_status() {
    echo "Fetching connectors for status check..."
    connectors_json=$(curl -s "$CONNECT_HOST/connectors")

    if [ -z "$connectors_json" ] || [ "$connectors_json" == "[]" ]; then
        echo "No connectors found."
        return 1
    fi

    connectors_list=$(echo "$connectors_json" | jq -r '.[]' | tr -s '\n' ' ' | xargs)
    read -ra connectors <<< "$connectors_list"

    if [ ${#connectors[@]} -eq 0 ]; then
        echo "No connectors found."
        return 1
    fi

    echo "Available connectors:"
    for i in "${!connectors[@]}"; do
        echo "$((i+1))) ${connectors[$i]}"
    done

    read -p "Select connector number for status check: " selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#connectors[@]}" ]]; then
        echo "Invalid selection."
        return 1
    fi

    selected_connector="${connectors[$((selection-1))]}"
    selected_connector=$(echo "$selected_connector" | tr -d '\r')  # Remove carriage return
    encoded_connector=$(echo -n "$selected_connector" | jq -sRr @uri)

    STATUS_URL="$CONNECT_HOST/connectors/$encoded_connector/status"
    echo "Fetching status of connector: $STATUS_URL"
    curl -s "$STATUS_URL" | jq .
}


restart_connector() {
    echo "Fetching connectors for restart..."
    connectors_json=$(curl -s "$CONNECT_HOST/connectors")

    if [ -z "$connectors_json" ] || [ "$connectors_json" == "[]" ]; then
        echo "No connectors found."
        return 1
    fi

    connectors_list=$(echo "$connectors_json" | jq -r '.[]' | tr -s '\n' ' ' | xargs)
    read -ra connectors <<< "$connectors_list"

    if [ ${#connectors[@]} -eq 0 ]; then
        echo "No connectors found."
        return 1
    fi

    echo "Available connectors:"
    for i in "${!connectors[@]}"; do
        echo "$((i+1))) ${connectors[$i]}"
    done

    read -p "Select connector number to restart: " selection
    if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt "${#connectors[@]}" ]; then
        echo "Invalid selection."
        return 1
    fi

    selected_connector="${connectors[$((selection-1))]}"
    echo "Restarting connector: $selected_connector"
    curl -X POST "$CONNECT_HOST/connectors/$selected_connector/restart"
    echo -e "\nConnector restart request sent."
}

restart_connector_with_tasks() {
    echo "Fetching connectors for restart (all tasks)..."
    connectors_json=$(curl -s "$CONNECT_HOST/connectors")

    if [ -z "$connectors_json" ] || [ "$connectors_json" == "[]" ]; then
        echo "No connectors found."
        return 1
    fi

    connectors_list=$(echo "$connectors_json" | jq -r '.[]' | tr -s '\n' ' ' | xargs)
    read -ra connectors <<< "$connectors_list"

    if [ ${#connectors[@]} -eq 0 ]; then
        echo "No connectors found."
        return 1
    fi

    echo "Available connectors:"
    for i in "${!connectors[@]}"; do
        echo "$((i+1))) ${connectors[$i]}"
    done

    read -p "Select connector number to restart (all tasks): " selection
    if [[ ! "$selection" =~ ^[0-9]+$ || "$selection" -lt 1 || "$selection" -gt ${#connectors[@]} ]]; then
        echo "Invalid selection."
        return 1
    fi

    selected_connector="${connectors[$((selection-1))]}"
    selected_connector=$(echo "$selected_connector" | tr -d '\r\n')
    encoded_connector=$(echo -n "$selected_connector" | jq -sRr @uri)

    echo "Restarting connector and all tasks: $selected_connector"
    curl -X POST "$CONNECT_HOST/connectors/$encoded_connector/restart?includeTasks=true"
    echo -e "\nConnector and tasks restart request sent."
}

delete_connector() {
    echo "Fetching connectors for deletion..."
    connectors_json=$(curl -s "$CONNECT_HOST/connectors")

    if [ -z "$connectors_json" ] || [ "$connectors_json" == "[]" ]; then
        echo "No connectors found."
        return 1
    fi

    connectors_list=$(echo "$connectors_json" | jq -r '.[]' | tr -s '\n' ' ' | xargs)
    read -ra connectors <<< "$connectors_list"

    if [ ${#connectors[@]} -eq 0 ]; then
        echo "No connectors found."
        return 1
    fi

    echo "Available connectors:"
    for i in "${!connectors[@]}"; do
        echo "$((i+1))) ${connectors[$i]}"
    done

    read -p "Select connector number to delete: " selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt "${#connectors[@]}" ]]; then
        echo "Invalid selection."
        return 1
    fi

    selected_connector="${connectors[$((selection-1))]}"
    selected_connector=$(echo "$selected_connector" | tr -d '\r')  # Remove carriage return
    encoded_connector=$(echo -n "$selected_connector" | jq -sRr @uri)

    echo "Deleting connector: $selected_connector"
    curl -X DELETE "$CONNECT_HOST/connectors/$encoded_connector"
    echo -e "\nConnector deletion request sent."
}


#####################################
# Main menu
#####################################

while true; do
    echo -e "\nKafka Connect Manager"
    echo "1) List Connectors"
    echo "2) Register Connector (from local config)"
    echo "3) Check Connector Status"
    echo "4) Restart Connector"
    echo "5) Restart Connector (All Tasks)"
    echo "6) Delete Connector"
    echo "e) Exit"

    read -p "Choose an option: " choice
    case $choice in
        1) list_connectors ;;
        2) register_connector ;;
        3) check_status ;;
        4) restart_connector ;;
        5) restart_connector_with_tasks ;;
        6) delete_connector ;;
        e) echo "Exiting."; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
done
