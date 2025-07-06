#!/usr/bin/env bash

# ==============================================================================
#
#          Automated iRedMail & Roundcube Setup Script for Ubuntu
#
# ==============================================================================
#
# DESCRIPTION:
# This script automates the installation and basic configuration of a full-featured
# mail server on a FRESH Ubuntu system. It uses iRedMail, an open-source mail
# server solution that bundles and configures all necessary components, including
# Postfix, Dovecot, Nginx, Roundcube webmail, and more.
#
# WARNING:
# 1.  **FOR FRESH SYSTEMS ONLY:** Run this on a brand new, clean Ubuntu server.
#     Do NOT run this on a production server with existing data or services.
# 2.  **EDIT CONFIGURATION:** You MUST change the variables in the configuration
#     section below to match your environment.
# 3.  **NO WARRANTY:** This script is provided as-is. Use at your own risk.
#     Always back up your data.
# 4.  **INTERACTION MAY BE NEEDED:** While mostly automated, the iRedMail installer
#     may still ask for a 'y' to confirm settings.
#
# ==============================================================================

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
#                       !!! EDIT THIS CONFIGURATION !!!
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# iRedMail version to install. Check https://www.iredmail.org/download.html for the latest.
IREDMAIL_VERSION="1.6.8"

# Set your server's Fully Qualified Domain Name (FQDN). e.g., "mail.yourdomain.com"
FQDN="mail.example.com"

# Set your primary mail domain. e.g., "yourdomain.com"
FIRST_MAIL_DOMAIN="example.com"

# Set the password for the postmaster@<your_domain.com> admin account.
# USE A STRONG, UNIQUE PASSWORD.
ADMIN_PASSWORD="MySuperStrongPassword123!"

# Set the password for the MariaDB (MySQL) root user.
# USE A STRONG, UNIQUE PASSWORD.
DB_ROOT_PASSWORD="MySuperStrongDatabasePassword456!"

# Set to "YES" to disable Amavisd (which includes ClamAV antivirus and SpamAssassin).
# Any other value will keep it enabled.
DISABLE_AV_SPAM_SCANNER="YES"

# Define the mail user accounts you want to create.
# Format: "user@domain.com:PasswordForUser"
# Add as many users as you like, separated by spaces.
# IMPORTANT: Use strong passwords for each user.
USERS_TO_CREATE=(
"John.Smith@beleng1.local:Password1!"
"Jane.Johnson@beleng1.local:Password1!"
"Michael.Williams@beleng1.local:Password1!"
"Emily.Jones@beleng1.local:Password1!"
"Chris.Brown@beleng1.local:Password1!"
"Sarah.Davis@beleng1.local:Password1!"
"David.Miller@beleng1.local:Password1!"
"Laura.Wilson@beleng1.local:Password1!"
"Robert.Moore@beleng1.local:Password1!"
"Jessica.Taylor@beleng1.local:Password1!"
"John.Anderson@beleng1.local:Password1!"
"Jane.Thomas@beleng1.local:Password1!"
"Michael.Jackson@beleng1.local:Password1!"
"Emily.White@beleng1.local:Password1!"
"Chris.Harris@beleng1.local:Password1!"
"Sarah.Martin@beleng1.local:Password1!"
"David.Thompson@beleng1.local:Password1!"
"Laura.Garcia@beleng1.local:Password1!"
"Robert.Martinez@beleng1.local:Password1!"
"Jessica.Robinson@beleng1.local:Password1!"
"John.Clark@beleng1.local:Password1!"
"Jane.Rodriguez@beleng1.local:Password1!"
"Michael.Lewis@beleng1.local:Password1!"
"Emily.Lee@beleng1.local:Password1!"
"Chris.Walker@beleng1.local:Password1!"
"Sarah.Hall@beleng1.local:Password1!"
"David.Allen@beleng1.local:Password1!"
"Laura.Young@beleng1.local:Password1!"
"Robert.Hernandez@beleng1.local:Password1!"
"Jessica.King@beleng1.local:Password1!"
"John.Wright@beleng1.local:Password1!"
"Jane.Lopez@beleng1.local:Password1!"
"Michael.Hill@beleng1.local:Password1!"
"Emily.Scott@beleng1.local:Password1!"
"Chris.Green@beleng1.local:Password1!"
"Sarah.Adams@beleng1.local:Password1!"
"David.Baker@beleng1.local:Password1!"
"Laura.Gonzalez@beleng1.local:Password1!"
"Robert.Nelson@beleng1.local:Password1!"
"Jessica.Carter@beleng1.local:Password1!"
"John.Mitchell@beleng1.local:Password1!"
"Jane.Perez@beleng1.local:Password1!"
"Michael.Roberts@beleng1.local:Password1!"
"Emily.Turner@beleng1.local:Password1!"
"Chris.Phillips@beleng1.local:Password1!"
"Sarah.Campbell@beleng1.local:Password1!"
"David.Parker@beleng1.local:Password1!"
"Laura.Evans@beleng1.local:Password1!"
"Robert.Edwards@beleng1.local:Password1!"
)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
#                 END OF CONFIGURATION - DO NOT EDIT BELOW
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Prevent errors in a pipeline from being masked.
set -o pipefail

# --- Check if running as root ---
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use 'sudo'."
   exit 1
fi

echo "### Automated Mail Server Setup Initializing ###"
echo "###"
echo "### FQDN: ${FQDN}"
echo "### Mail Domain: ${FIRST_MAIL_DOMAIN}"
echo "###"
echo "### This script will make significant changes to the system."
echo "### Press ENTER to begin in 5 seconds, or Ctrl+C to cancel."
read -t 5 || echo "Continuing..."


# --- STEP 1: System Preparation ---
echo
echo "### 1/5: Updating system and setting hostname... ###"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y wget gzip bzip2 dialog

# Set hostname
hostnamectl set-hostname "${FQDN}"
# Update /etc/hosts
echo "127.0.0.1   ${FQDN} ${FIRST_MAIL_DOMAIN}" >> /etc/hosts
echo "::1         ${FQDN} ${FIRST_MAIL_DOMAIN}" >> /etc/hosts
echo "System preparation complete."


# --- STEP 2: Download and Extract iRedMail ---
echo
echo "### 2/5: Downloading and extracting iRedMail v${IREDMAIL_VERSION}... ###"
cd /root/
wget "https://github.com/iredmail/iRedMail/archive/refs/tags/${IREDMAIL_VERSION}.tar.gz" -O "iRedMail-${IREDMAIL_VERSION}.tar.gz"
tar -xf "iRedMail-${IREDMAIL_VERSION}.tar.gz"
echo "iRedMail downloaded and extracted."


# --- STEP 3: Automated iRedMail Installation ---
echo
echo "### 3/5: Starting unattended iRedMail installation... ###"
IREDMAIL_DIR="/root/iRedMail-${IREDMAIL_VERSION}"
cd "${IREDMAIL_DIR}"

# Create the config file for unattended installation
cat <<EOF > config
# General
HOSTNAME="${FQDN}"
FIRST_MAIL_DOMAIN="${FIRST_MAIL_DOMAIN}"
USE_DEFAULT_CONFIG="y"
AUTO_USE_EXISTING_CONFIG_FILE="y"
AUTO_INSTALL_WITHOUT_CONFIRM="y"
AUTO_CLEANUP_REMOVE_SENDMAIL="y"
AUTO_CLEANUP_RESTART_SERVICES="y"

# Web Server
PREFERRED_WEB_SERVER="nginx"

# Backend for mail accounts (MariaDB is a good default)
BACKEND="mariadb"

# MariaDB settings
MYSQL_ROOT_PASSWD="${DB_ROOT_PASSWORD}"

# Mail admin account
FIRST_MAIL_ADMIN_FULLNAME="Mail Admin"
FIRST_MAIL_ADMIN_EMAIL="postmaster@${FIRST_MAIL_DOMAIN}"
FIRST_MAIL_ADMIN_PASSWD="${ADMIN_PASSWORD}"

# Optional Components
# Roundcube is the webmail client
INSTALL_ROUNDCUBE="y"
# iRedAdmin is the admin panel
INSTALL_IREDADMIN="y"
# SOGo is an optional groupware
INSTALL_SOGO="n"
# Fail2ban helps prevent brute-force attacks
INSTALL_FAIL2BAN="y"
EOF

echo "iRedMail configuration file created. Starting installer..."
# The iRedMail.sh script will automatically pick up the 'config' file
bash iRedMail.sh

echo "iRedMail installation process finished."
echo "You should find detailed credentials in /root/iRedMail-${IREDMAIL_VERSION}/iRedMail.tips"


# --- STEP 4: Disable Antivirus/Spam Scanner (if configured) ---
echo
echo "### 4/5: Configuring Antivirus and Spam Scanner... ###"
if [[ "${DISABLE_AV_SPAM_SCANNER}" == "YES" ]]; then
    echo "Disabling Amavisd (ClamAV and SpamAssassin)..."
    # Stop and disable the service
    systemctl stop amavis
    systemctl disable amavis

    # Postfix needs to be told not to send mail to amavis
    # This comments out the content_filter line in the main Postfix config
    sed -i 's/^\(content_filter = smtp-amavis:\[127.0.0.1\]:10024\)/#\1/' /etc/postfix/main.cf

    # Reload postfix to apply the change
    systemctl reload postfix
    echo "Amavisd has been disabled and Postfix reloaded."
else
    echo "Keeping Amavisd (ClamAV and SpamAssassin) enabled as per configuration."
fi


# --- STEP 5: Create Mail User Accounts ---
echo
echo "### 5/5: Creating mail user accounts... ###"
if [ ${#USERS_TO_CREATE[@]} -gt 0 ]; then
    # The tool to create users is located in the iRedMail tools directory
    CREATE_USER_SCRIPT="${IREDMAIL_DIR}/tools/create_mail_user_SQL.sh"
    
    if [[ ! -f "${CREATE_USER_SCRIPT}" ]]; then
        echo "ERROR: User creation script not found at ${CREATE_USER_SCRIPT}"
        exit 1
    fi

    for user_info in "${USERS_TO_CREATE[@]}"; do
        # Split the string "user@domain.com:Password" into two parts
        IFS=':' read -r email password <<< "$user_info"
        echo "Creating user: ${email}"
        # The script takes the email address and password as arguments
        bash "${CREATE_USER_SCRIPT}" "${email}" "${password}"
    done
    echo "All specified user accounts have been created."
else
    echo "No users specified in USERS_TO_CREATE. Skipping user creation."
fi

echo
echo "=========================================================================="
echo "          MAIL SERVER INSTALLATION COMPLETE!"
echo "=========================================================================="
echo
echo "IMPORTANT:"
echo "A file with critical information (URLs, usernames, passwords) has been"
echo "created at: /root/iRedMail-${IREDMAIL_VERSION}/iRedMail.tips"
echo
echo "You can access Roundcube webmail at: https://${FQDN}/roundcube"
echo "You can access the admin panel (iRedAdmin) at: https://${FQDN}/iredadmin"
echo
echo "A system reboot is highly recommended to ensure all services start correctly."
echo "You can reboot by typing: 'reboot'"
echo

exit 0
