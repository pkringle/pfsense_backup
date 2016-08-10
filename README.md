# pfsense_backup
A shell script to monitor pfsense firewall changes and commit changes to a backup git repo.  On top of this it does enable AES ECB encryption so that your config files are not in plan text on your git repo.  I am sure there is a more secure way, but this way works and is simple

## requirements
- bash
- git
- wget
- openssl

## install
- Create a private / secure git repo
- Create a backup user on pfsense firewall that only access to diag_backup.php
- ```cp config.sh.sample config.sh```
- vi config.sh
- Add backup_pf.sh to your cron
- ```15 * * * * <MY PATH>/pfsense_backup/backup_pf.sh```

## Credits
- https://gist.github.com/shadowhand/873637
- https://doc.pfsense.org/index.php/Remote_Config_Backup
- http://www.pixelbeat.org/cv.html
