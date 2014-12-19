#!/bin/bash

# All the strings and paths used
HEAD1=" pydio installation script"
HEAD2=" version 1.0.19122014"
HEAD3=" by ronald.aai"
HEAD4="-=============================-"
STR1="[+] Checking APT Sources for pydio repo ... "
STR2="[+] Adding pydio repo ... "
STR3="[Found]"
STR4="[Not Found]"
STR5="//Skip"
STR6="[+] Downloading pydio repo key ..."
STR7="[Done]"
STR8="[Fail]"
STR9="[+] Adding pydio repo key ... "
STR10="[*] Fatal Error, cannot continue, because step failed!"
STR11="[+] Updating repos (*might take a while) ... "
STR11a="[+] Upgrading OS (*might take a while) ... "
STR12="[+] Installing pydio (*might take a while) ... "
STR13="[+] Copying pydio apache2 config to apache2 path ... " 
STR14="[+] Setting up MCrypt ... "
STR15="[+] Enabling MCrypt in PHP5 ... "
STR16="[+] Installing Sqlite3 ... "
STR17="[+] Disabling PHP Output Buffer ..."
STR18="[+] Setting Server Locale for pydio ..."
STR19="[*] All done. Reboot for changes."
tmp_file="installpydio.tmp"
php_ini="/etc/php5/apache2/php.ini"
bootstrap_url="/etc/pydio/bootstrap_conf.php"
setlocale='setlocale(LC_ALL, "en_US.UTF-8");'
definelocale='define("AJXP_LOCALE", "en_US.UTF-8");'
repo="deb http://dl.ajaxplorer.info/repos/apt stable main"
repo_src="deb-src http://dl.ajaxplorer.info/repos/apt stable main"
repo_key_url="http://dl.ajaxplorer.info/repos/"
repo_key="charles@ajaxplorer.info.gpg.key"
pydio_apache_conf="/usr/share/doc/pydio/apache2.sample.conf"
apache_site_conf="/etc/apache2/sites-enabled/pydio.conf"
apt_path="/etc/apt/sources.list"

echo $HEAD4
echo $HEAD1
echo $HEAD2
echo $HEAD3
echo $HEAD4
echo ""

#This part is to add the pydio repo into apt/sources.list
echo -n $STR1
x=`grep "$repo" /etc/apt/sources.list`
case "$x" in
  *"$repo"*)
	echo $STR3 $STR5
	;;
  *)
	echo $STR4
	echo $STR2
	echo $repo >> $apt_path
	echo $repo_src  >> $apt_path
	;;
esac

#Now this is the updating part
#First check if the file exists... if not we'll wget it down.

echo -n $STR6

if [ -f $repo_key ]
then
	echo $STR3 $STR5
else
	x=`wget "$repo_key_url$repo_key" --append-output="$tmp_file"`
	x=`grep saved "$tmp_file"`

	if [ -f $repo_key ]
	then
		echo $STR7
	else
		echo $STR8
		echo ""
		echo $STR10
		exit 1
	fi
fi

#install the key
echo -n $STR9

x=`apt-key add "$repo_key"`
if [ $x="OK" ]
then
	echo $STR7
else
	echo $STR8
	echo ""
	echo $STR10
	exit 1
fi

#doing the apt-get update
echo -n $STR11
x=`apt-get update > "$tmp_file"`
x=`grep * "$tmp_file"`
case "$x" in
	*"ERROR")
		echo $STR8
		echo ""
		echo $STR10
		exit 1
		;;
	*)
		echo $STR7
		;;
esac

#doing the apt-get upgrade
echo -n $STR11a
x=`apt-get upgrade -y > "$tmp_file"`
x=`grep * "$tmp_file"`
case "$x" in
	*"ERROR")
		echo $STR8
		echo ""
		echo $STR10
		exit 1
		;;
	*)
		echo $STR7
		;;
esac

#install pydio from repo
echo -n $STR12
x=`apt-get install -y pydio > "$tmp_file"`
x=`grep * "$tmp_file"`
case "$x" in
	*"newest version"*)
		echo $STR3 $STR5
		;;
	*"ERROR"*)
		echo $STR8
		echo ""
		echo $STR10
		exit 1
		;;
	*)
		echo $STR7
		;;
esac

#Copy the sample apache2 config from pydio to apache2
echo -n $STR13
if [ -f $apache_site_conf ]
then
	echo $STR3 $STR5
else
	x=`cp "$pydio_apache_conf" "$apache_site_conf" > "$tmp_file"`
	if [ -f $apache_site_conf ]
	then
		echo $STR7
	else
		echo $STR8
		echo ""
		echo $STR10
		exit 1
	fi
fi

#enable mcrypt mod in php5
echo -n $STR14
x=`cd /etc/php5/mods-available`
case "$x" in
	*"No such file or directory"*)
		echo $STR8
		echo ""
		echo $STR10
		exit 1
		;;
	*)
		y=`ln -s ../conf.d/mcrypt.so > "$tmp_file"`
		y=`grep * "$tmp_file"`
		case "$y" in
			*"File exists"*)
				echo $STR5 $STR3
				;;
			*"No such file or directory"*)
				echo $STR8
				echo ""
				echo $STR10
				exit 1
				;;
			*)
				z=`php5enmod mcrypt`
				case "$z" in
					*"doesn't exist"*)
						echo $STR8
						echo ""
						echo $STR10
						exit 1
						;;
					*)
						echo $STR7
						;;
		esac
	esac
esac

#install sqlite from repo
echo -n $STR16
x=`apt-get install -y sqlite php5-sqlite > "$tmp_file"`
x=`cat "$tmp_file"`
case "$x" in
	*"newest version"*)
		echo $STR3 $STR5
		;;
	*"ERROR"*)
		echo $STR8
		echo ""
		echo $STR10
		exit 1
		;;
	*)
		echo $STR7
		;;
esac

#changing PHP Output buffering
echo -n $STR17
x=`sed -i 's/output_buffering = 4096/output_buffering = Off/g' "$php_ini"`
echo $STR7

#adding server locale
echo -n $STR18
x=`grep '["\047].*["\047]' "$bootstrap_url"`
case "$x" in
  *"$setlocale"*)
	echo $STR3 $STR5
	;;
  *)
	echo $setlocale >> $bootstrap_url
	echo $definelocale  >> $bootstrap_url
	echo $STR7
	;;
esac

#All Done
echo $STR19
#sleep 3
#sudo reboot

