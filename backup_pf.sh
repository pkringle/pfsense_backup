#!/bin/bash
set -e
HOMEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source $HOMEDIR/config.sh

# Download script to makeing emails pretty
if [ ! -f "/tmp/ansi2html.sh" ]; then
	wget "http://www.pixelbeat.org/scripts/ansi2html.sh" -O /tmp/ansi2html.sh
	chmod +x /tmp/ansi2html.sh
fi

for HOSTNAME in ${HOSTS[@]}; do

if [ ! -d "$DIRECTORY" ]; then
	mkdir -p $DIRECTORY
	git clone $REPO $DIRECTORY
fi
cd $DIRECTORY

# Prepare encryption if missing.
if [ ! -f "$DIRECTORY/.gitattributes" ]; then
	echo "* filter=openssl diff=openssl" > $DIRECTORY/.gitattributes
	echo "[merge]" >> $DIRECTORY/.gitattributes
	echo "    renormalize = true" >> $DIRECTORY/.gitattributes

	echo "[filter \"openssl\"]" >> $DIRECTORY/.git/config
	echo "    smudge = $HOMEDIR/smudge_filter_openssl " >> $DIRECTORY/.git/config
	echo "    clean = $HOMEDIR/clean_filter_openssl" >> $DIRECTORY/.git/config
	echo "[diff \"openssl\"]" >> $DIRECTORY/.git/config
	echo "    textconv = $HOMEDIR/diff_filter_openssl" >> $DIRECTORY/.git/config
fi

git pull $REPO master &> /dev/null

# pulled these wget lines from pfsense's documentation
wget -qO- --keep-session-cookies --save-cookies cookies.txt \
  --no-check-certificate $HTTPACCESS://$HOSTNAME/diag_backup.php \
  | grep "name='__csrf_magic'" | sed 's/.*value="\(.*\)".*/\1/' > csrf.txt

wget -qO- --keep-session-cookies --load-cookies cookies.txt \
  --save-cookies cookies.txt --no-check-certificate \
  --post-data "login=Login&usernamefld=$PFUSER&passwordfld=$PFPASSWD&__csrf_magic=$(cat csrf.txt)" \
  $HTTPACCESS://$HOSTNAME/diag_backup.php  | grep "name='__csrf_magic'" \
  | sed 's/.*value="\(.*\)".*/\1/' > csrf2.txt

wget -qO --keep-session-cookies --load-cookies cookies.txt --no-check-certificate \
  --post-data "Submit=download&donotbackuprrd=yes&__csrf_magic=$(head -n 1 csrf2.txt)" \
  $HTTPACCESS://$HOSTNAME/diag_backup.php -O $DIRECTORY/${HOSTNAME}_config.xml

# Look for differences and check them in if one is found
git add ${HOSTNAME}_config.xml &> /dev/null
if [ `git diff-index --name-only HEAD | wc -l` -gt 0 ];
then
	git diff --cached | /tmp/ansi2html.sh > $DIRECTORY/filediff.txt 2>&1
	cat $DIRECTORY/filediff.txt | mail -s "$(echo -e "Config change found on $HOSTNAME\nContent-Type: text/html")" $ADMINEMAIL
	git commit -m "Config change found on $HOSTNAME" &> /dev/null
	git push origin master &> /dev/null
	rm $DIRECTORY/filediff.txt
fi

# Clean up
rm csrf.txt cookies.txt csrf2.txt
done
exit 0
