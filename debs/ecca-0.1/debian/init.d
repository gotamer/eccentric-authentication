#!/bin/sh

### BEGIN INIT INFO
# Provides:          ecca
# Required-Start:    $local_fs $network $memcachedb
# Required-Stop:     
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: starts the nginx web server configured for Eccentric Authentication
# Description:       starts nginx using start-stop-daemon for Eccentric Authentication
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
DAEMON=/usr/sbin/nginx
DAEMON_ARGS="-c /etc/ecca/web/nginx.conf"
NAME=ecca
DESC=ecca

# Include nginx defaults if available
if [ -f /etc/default/nginx ]; then
	. /etc/default/nginx
fi

test -x $DAEMON || exit 0

set -ex

. /lib/lsb/init-functions

test_nginx_config() {
	if $DAEMON -t $DAEMON_OPTS >/dev/null 2>&1; then
		return 0
	else
		$DAEMON -t $DAEMON_OPTS
		return $?
	fi
}

case "$1" in
	start)
		echo -n "Starting $DESC: "
		test_nginx_config
		# Check if the ULIMIT is set in /etc/default/nginx
		if [ -n "$ULIMIT" ]; then
			# Set the ulimits
			ulimit $ULIMIT
		fi
		start-stop-daemon --start --quiet --pidfile /var/run/$NAME.pid \
		    --exec $DAEMON -- $DAEMON_OPTS || true
		echo "$NAME."
		;;

	stop)
		echo -n "Stopping $DESC: "
		start-stop-daemon --stop --quiet --pidfile /var/run/$NAME.pid || true
		echo "$NAME."
		;;

	restart|force-reload)
		echo -n "Restarting $DESC: "
		start-stop-daemon --stop --quiet --pidfile \
		    /var/run/$NAME.pid --exec $DAEMON || true
		sleep 1
		test_nginx_config
		# Check if the ULIMIT is set in /etc/default/nginx
		if [ -n "$ULIMIT" ]; then
			# Set the ulimits
			ulimit $ULIMIT
		fi
		start-stop-daemon --start --quiet --pidfile \
		    /var/run/$NAME.pid --exec $DAEMON -- $DAEMON_OPTS || true
		echo "$NAME."
		;;

	reload)
		echo -n "Reloading $DESC configuration: "
		test_nginx_config
		start-stop-daemon --stop --signal HUP --quiet --pidfile /var/run/$NAME.pid \
		    --exec $DAEMON || true
		echo "$NAME."
		;;

	configtest|testconfig)
		echo -n "Testing $DESC configuration: "
		if test_nginx_config; then
			echo "$NAME."
		else
			exit $?
		fi
		;;

	status)
		status_of_proc -p /var/run/$NAME.pid "$DAEMON" nginx && exit 0 || exit $?
		;;
	*)
		echo "Usage: $NAME {start|stop|restart|reload|force-reload|status|configtest}" >&2
		exit 1
		;;
esac

exit 0
