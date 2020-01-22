#!/bin/bash
## 
############################################################################################################################################
# --------------------------------------------> 																					Defaults 
############################################################################################################################################
# Default Variables are set in this function
function defaults(){
	ADDRESSES=''
	USER=''
	SOURCEPOINT=''
	PASSWORD=''
	MOUNTPOINT=/Volumes/Anvil
	SSHFSOPTS="-o resvport,rw"
	NFSOPTS="-o Compression=no,cache=yes,kernel_cache,defer_permissions,reconnect,follow_symlinks,allow_other,PASSWORD_stdin"
}
############################################################################################################################################
# --------------------------------------------> 																					   Check 
############################################################################################################################################
# Default Variables are set in this function
function check(){
	# check HOSTs file
	# check for ssh key pairs if sshfs is specified
	# test sshfs connection
	# check for installation of sshfs + osxfuse
	# check for existence of mount
	# check for existence of ping
	# check for existence of diskutil
	# check for existence of date
	# check for variables
	echo ''
	checkroute
}
############################################################################################################################################
# --------------------------------------------> 																				 Check Route
############################################################################################################################################
# check for ADDRESSES in order of preference
function checkroute(){
for ADDRESS in ${ADDRESSES}; do
	if ping -c 1 ${ADDRESS} > /dev/null; then
		HOST=${ADDRESS}
		echo "$(date) >> Connecting to ${ADDRESS}"
		break
	else
		echo "$(date) >> NFS Route ${ADDRESS} Not Detected"
		continue
	fi
done
}
############################################################################################################################################
# --------------------------------------------> 																				 Mount | NFS 
############################################################################################################################################
# routine for NFS mount
function mount_nfs(){
    if mount -t nfs ${NFSOPTS} ${HOST}:${SOURCEPOINT} ${MOUNTPOINT}; then
    	echo "$(date) success >> mount -t nfs ${NFSOPTS} ${HOST}:${SOURCEPOINT} ${MOUNTPOINT}"
    	return 0
	else
		echo "$(date) failed >> mount -t nfs ${NFSOPTS} ${HOST}:${SOURCEPOINT} ${MOUNTPOINT}"
		return 1
	fi
}
############################################################################################################################################
# --------------------------------------------> 																			 Mount | osxfuse
############################################################################################################################################
# routine for SSHFS mount
function mount_sshfs(){
    if echo ${PASSWORD} | sudo sshfs ${USER}@${HOST}:${SOURCEPOINT} ${MOUNTPOINT} ${SSHFSOPTS}; then
    	echo "$(date) success >> sudo sshfs ${USER}@${HOST}:${SOURCEPOINT} ${MOUNTPOINT} ${SSHFSOPTS}"
    	return 0
	else
		echo "$(date) failed >> sudo sshfs ${USER}@${HOST}:${SOURCEPOINT} ${MOUNTPOINT} ${SSHFSOPTS}"
		return 1
	fi	
}
############################################################################################################################################
# --------------------------------------------> 																					  Daemon
############################################################################################################################################
# control flow
function startup_daemon(){
	# only attempt to connect if HOST is detected on network
	if [ -z ${HOST} ]; then
		echo "$(date) >> No available network route to ${ADDRESS}:${SOURCEPOINT}"
		return 1
	else
		# check status of mount point
		find "${MOUNTPOINT}" -type d -d 1 1>/dev/null 2>/tmp/check-mount_${HOST}.tmp
		if [ $(cat /tmp/check-mount_${HOST}.tmp| grep 'Device not configured') ]; then
			echo "$(date) >> SSHFS mount failed, force unmounting"
			# force unmount if device not configured
			if sudo diskutil umount force ${MOUNTPOINT} 1>/dev/null 2>/dev/null; then
				echo "$(date) >> Unmount successful for ${MOUNTPOINT}"
				continue
			else
				echo "$(date) >> Unmount failed ${MOUNTPOINT}"
				return 1
			fi
		fi
		# create folder if needed
		if [ $(cat /tmp/check-mount_${HOST}.tmp | grep 'No such file or directory') ]; then
			[ ! -d "${MOUNTPOINT}" ] && mkdir -v "${MOUNTPOINT}"
		fi
		# check for mount
		if [ ! "$(mount | grep "${HOST}:${SOURCEPOINT} on ${MOUNTPOINT} .*${PROTOCOL}.*")" ]; then
			echo "$(date) >> Mounting ${MOUNTPOINT} via ${PROTOCOL}"		
			if [ "${PROTOCOL}" == 'nfs' ]; then
				mount_nfs
			elif [ "${PROTOCOL}" == 'osxfuse' ]; then
				mount_sshfs		
			fi
		fi
	fi
}
############################################################################################################################################
# --------------------------------------------> 																			   Parse Options 
############################################################################################################################################
## Default Variables are set in this function
# parse options
function parseoptions(){
	while :; do
	    case ${1} in	    	
		-a|--address)
		    if [ -n "$2" ]; then
				ADDRESSES+=("${2}")
				shift
			else
				echo -e "${BRED}ERROR: ${NC}-a --ADDRESS requires a non empty option argument.\n" >&2
				exit
		    fi			
			;;
		-u|--user)
		    if [ -n "$2" ]; then
				USER=${2}
				shift
			else
				echo -e "${BRED}ERROR: ${NC}-u --user requires a non empty option argument.\n" >&2
				exit
		    fi			
			;;
		-p|--password)
		    if [ -n "$2" ]; then
				PASSWORD=${2}
				shift
			else
				echo -e "${BRED}ERROR: ${NC}-p --password requires a non empty option argument.\n" >&2
				exit
		    fi			
			;;				
		-mp|--mount-point)
		    if [ -n "$2" ]; then
				MOUNTPOINT=${2}
				shift
			else
				echo -e "${BRED}ERROR: ${NC}-mp --mount-point requires a non empty option argument.\n" >&2
				exit
		    fi			
			;;
		-sp|--source-point)
		    if [ -n "$2" ]; then
				MOUNTPOINT=${2}
				shift
			else
				echo -e "${BRED}ERROR: ${NC}-sp --source-point requires a non empty option argument.\n" >&2
				exit
		    fi			
			;;																
		-sshfso|--sshfs-opts)
		    if [ -n "$2" ]; then
				export SSHFSOPTS=${2}
				shift
		    else
				echo -e "${BRED}ERROR: ${NC}-sshfso --sshfs-opts requires a non empty option argument.\n" >&2
				exit
		    fi
		    ;;
		-nfso|--nfs-opts)
		    if [ -n "$2" ]; then
				export NFSOPTS=${2}
				shift
		    else
				echo -e "${BRED}ERROR: ${NC}-nfso --nfs-opts requires a non empty option argument.\n" >&2
				exit
		    fi
		    ;;
		-h|--help|help)
			HELP='more'
			surfergems_usage
			exit
			;;
		?)
		    printf '\n'${YELLOW}' Warning: '${NC}'Unknown option: "%s"\n..exiting' "${1}" >&2
		    exit
		    ;;
		*)
		    break
	    esac
	    shift
	done
}
############################################################################################################################################
# --------------------------------------------> 																			   MAIN BODY
############################################################################################################################################
# declare default values
defaults
# populate namespace with user input
parseopts $@
# check prerequistes
check
# run control flow to mount desired file system
startup_daemon
#
############################################################################################################################################
# --------------------------------------------> 																			   			FIN
############################################################################################################################################
