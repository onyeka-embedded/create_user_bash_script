#!/bin/bash

#create main directory to save files
mkdir var
cd var #move inside the created dir

#create log folder and user_mgt.log inside the folder
mkdir log && touch log/user_management.log

#create secure folder and user_passwd file inside the folder
mkdir secure && touch secure/user_passwords.txt
#Read and Write permission for the owner only
chmod 700 secure
# go back to the home dir
cd ..

#LOG_FILE_PATH=./var/log/user_management.log
#PASSWD_PATH=./var/secure/user_password.txt

#function to generate password
generate_password() {
  local password=$(openssl rand -base64 12)
  echo "$password"
}

#Create users, groups and generate password
#for them, then  assign groups to the created users

#function to create users
createUser(){
  local user="$1"
  id "$user" &>/dev/null
  if [ $? -eq 1 ]; then #check if user is existing
     sudo useradd -m "$user"
     echo "user $user created"
  else
     echo "$user already created"
  fi
}

#function to create group
createGroup(){
  local group="$1"
  getent group "$group" &>/dev/null
  if [ $? -eq 2 ]; then #check if group has been created
     sudo groupadd "$group"
     echo "group $group created"
  else
     echo "$group already created"
  fi
}

#function to add users to group
addUser_to_group(){
  local user="$1"
  local group="$2"

  sudo usermod -aG "$group" "$user"
  echo "$user added to group: $group"
}
########## MAIN ENTRY POINT OF THE SCRIPT ##############
#Read and validate .txt file containing
#employees username and groups

# Check if the correct number of arguments is provided
(
if [[ $# -ne 1 ]]; then
  echo "error: check the file provided"
  exit 1
fi

# user details
user_file="$1"

# Check if the file exists
if [[ ! -f "$user_file" ]]; then
  echo "user file not found!"
  exit 1
fi

# Read the file line by line
while IFS=";" read -r user groups; do
  user=$(echo $user | xargs)
 # Check to know if user and group
 # contains strings for validation
 if [[ -z "$user" && -z "$groups" ]];
 then
    echo "Empty entry!!"
 else
    #create group and user if they don't exist
    createUser "$user"
    createGroup "$user"
    #create group with the same name as the user
    sudo usermod -aG "$user" "$user"

    IFS=',' read -ra group_array <<< "$groups"
    for group in "${group_array[@]}"; do
        group=$(echo $group | xargs)
        createGroup "$group"
        addUser_to_group "$user" "$group"
    done

    password=$(generate_password)
    echo "$user:$password" | sudo chpasswd
    echo "password assigned to $user"
    echo "$user,$password" >> ./var/secure/user_passwords.txt #PASSWD_PATH
 fi

done < "$user_file"

) | tee -a ./var/log/user_management.log
