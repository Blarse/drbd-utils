#!/bin/bash
# This script exists to work around SELinux policies created for DRBD v8
# utilities. If drbdadm or drbdsetup would be called directly in a service
# we would be transitioned to the drbd_t context, which is targeted at
# DRBD v8 tools and disallow things like netlink sockets.
#
# By using this script, we first transition to a general unconfined context,
# which allows us calling drbdadm and drbdsetup without these restrictions.

cmd=$1
res=$2

case "$cmd" in
adjust)
  exec /usr/sbin/drbdadm adjust "$res"
  ;;
down)
  exec /usr/sbin/drbdsetup down "$res"
  ;;
primary)
  exec /usr/sbin/drbdsetup primary "$res"
  ;;
secondary)
  exec /usr/sbin/drbdsetup secondary "$res"
  ;;
secondary-or-escalate)
	# Log something and try to get journald to flush its logs
	# to (hopefully) persistent storage, so we at least have some
	# indication of why we rebooted -- if that turns out to be necessary.
	echo >&2 "<6>about to demote (or escalate to the FailureAction)"
	journalctl --flush --sync
	/usr/sbin/drbdsetup secondary "$res"
	ex_secondary=$?
	case $ex_secondary in
	 0)
		# successfully demoted, already secondary anyways,
		# or module is not even loaded
		systemctl reset-failed "drbd-promote@$res.service"
		exit 0 ;;

	# any other special treatment for special exit codes?
	*)
		# double check for "resource does not exist"
		current_state=$(/usr/sbin/drbdsetup events2 --now "$res")
		if [[ $current_state = "exists -" ]]; then
			echo >&2 "<7>not even configured"
			exit 0
		fi
		echo >&2 "<7>current state: ${current_state//$'\n'/ // }"

		# TODO: optionally call some hook script,
		# which can go crazy trying to make this resource "demotable".
		# Then try again.
		;;
	esac

	# if we fail due to timeout, this won't even be reached :-(
	echo >&2 "<0>failed to demote, exit code=$ex_secondary; about to escalate to FailureAction"
	exit $ex_secondary
	;;

*)
  echo "Unknown verb $cmd" >&2
  exit 1
  ;;
esac
