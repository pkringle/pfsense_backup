# pfsense_backup
A shell script to monitor pfsense firewall changes and commit changes to a backup git repo.

## install
- Create a private / secure git repo
- Create a backup user on pfsense firewall that only access to diag_backup.php
- ```cp config.sh.sample config.sh```
- vi config.sh

