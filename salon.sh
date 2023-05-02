#!/bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon --tuples-only -q -c"

# Get a list of services and their IDs
services=$($PSQL "SELECT service_id, name FROM services")

# Display the numbered list of services
while true;do
  echo "Select a service:"
  echo "$services" | while read ID BAR NAME
  do
    echo "$ID) $NAME"
  done
  read SERVICE_ID_SELECTED
  # if input is not a number
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    # send to main menu
    echo "That is not a valid bike number."
  else
    SERVICE_AVAILABILITY=$($PSQL "SELECT service_id FROM services WHERE service_id = $SERVICE_ID_SELECTED ")
     
    if [[ -n $SERVICE_AVAILABILITY ]]
    then
      # service is available
      echo "AVAILABLE"

      # Prompt the user to enter a phone number
      echo "Please enter your phone number:"
      read CUSTOMER_PHONE

      # Check if the customer is already registered
      CUSTOMER_NAME=""
      CUSTOMER_ID=""
      CUSTOMER_EXISTENCE=$($PSQL "SELECT name, customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE'")
      
      if [[ -z $CUSTOMER_EXISTENCE ]]; then
        # Prompt the user to enter a name if they are a new customer
        echo "Please enter your name:"
        read CUSTOMER_NAME
        # Insert new customer into customers table
        $PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE', '$CUSTOMER_NAME')"
        CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
      else
        # Set the customer name to the existing name if the customer is already registered
        CUSTOMER_NAME=${CUSTOMER_EXISTENCE%%|*}
        CUSTOMER_ID=${CUSTOMER_EXISTENCE#*|}
      fi


      # Prompt the user to enter a service time
      echo "Please enter a service time:"
      read SERVICE_TIME

       # Insert the appointment and retrieve the appointment id
      APPOINTMENT_ID=$($PSQL "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME') RETURNING appointment_id")
      
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
      echo "I have put you down for a $(echo $SERVICE_NAME | tr -d '[:space:]') at $(echo $SERVICE_TIME | tr -d '[:space:]'), $(echo $CUSTOMER_NAME | tr -d '[:space:]')."


      break
    else
      # service is not available
      echo "NOT AVAILABLE"
    fi


  fi
done

