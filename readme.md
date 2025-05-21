

# WordPress + LEMP Auto-Setup Script (AutoLEMPW)

This bash script automates the setup of a full **WordPress + LEMP stack** on Ubuntu. It installs Nginx, MariaDB, PHP, WordPress, and configures everything for a functional site.

---

## Features

- Installs and configures:
  - Nginx
  - MySQL
  - PHP with required extensions
  - WordPress with database and `wp-config.php`
  - Nginx virtual host config
  - (Optional) VSCode

- Uninstalls everything (add `--remove` flag):
  - WordPress files
  - Database + user
  - Nginx configuration

---

## Quick Install via curl

```bash
sudo apt install curl
```

```bash
curl -O https://raw.githubusercontent.com/Aizhee/AutoLEMPW/main/AutoLEMPW.sh
chmod +x AutoLEMPW.sh
sudo ./AutoLEMPW.sh

````

## Quick Uninstall via curl

```bash
curl -O https://raw.githubusercontent.com/Aizhee/AutoLEMPW/main/AutoLEMPW.sh
chmod +x AutoLEMPW.sh
sudo ./AutoLEMPW.sh --remove
```

> ⚠️ Be sure to verify the script before running if you're using it in production environments.


## View Summary
```bash
cat ~/wordpress_installation_summary.txt
```
---

## Requirements

* Ubuntu 18.04/20.04/22.04+
* Root or sudo privileges
* Internet access

---






