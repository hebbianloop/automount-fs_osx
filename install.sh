#!/bin/bash
#
# Set Up Auto Mount

function whereami(){
	while [ -h "${SOURCE}" ]; do # resolve $SOURCE until the file is no longer a symlink
		DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"
		SOURCE="$(readlink "${SOURCE}")"
		[[ ${SOURCE} != /* ]] && SOURCE="${DIR}/${SOURCE}" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
	done
	DIR="$( cd -P "$( dirname "${SOURCE}" )" && pwd )"	
	# get where this script lives
	SOURCEPATH="`dirname \"$0\"`"              # relative
	SOURCEPATH="`( cd \"${SOURCEPATH}\" && pwd )`"	
}

function install(){

}

# Input list of hosts and matching users/passwords/protocols
# Create SSH key pairs and test SSH connection
# Copy startup_daeamon to /private/etc/
# 	--> set permissions
# Auto-Generate PLISTS for each host/user/password/protocol with HERETO doc 
# 	--> substitute input to call function
# 	--> place in /Library/LaunchDaemons/com.auto_protocol_user@address.plist
# Add to launchctl 
#	--> sudo launchctl -w load /Library/LaunchDaemons/com.auto_protocol_user@address.plist


cat <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>EnvironmentVariables</key>
	<dict>
		<key>PATH</key>
		<string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/opt/X11/bin:/usr/local/sbin</string>
	</dict>
	<key>Label</key>
	<string>automount_kiln</string>
	
	<key>ProgramArguments</key>
	<array>
	  <string>/private/etc/auto_sshfs_kiln_startup_daemon.sh</string>
	</array>
	<key>RunAtLoad</key>
	<true/>
	<key>KeepAlive</key>
	<true/>
	<key>StandardOutPath</key>
	<string>/tmp/com.kiln.mount.stdout</string>
	<key>StandardErrorPath</key>
	<string>/tmp/com.kiln.mount.stderr</string>
</dict>
</plist>
EOF
