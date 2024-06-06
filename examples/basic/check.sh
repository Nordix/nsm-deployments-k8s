#!/bin/bash
##
## check.sh --
##
##   Help script for fetching recource consumption data on a given pod in kind
##
## Commands;
##

prg=$(basename $0)
dir=$(dirname $0); dir=$(readlink -f $dir)
tmp=/tmp/${prg}_$$
DEBUG_DIR=/tmp/profiles
LOCAL_DIR=$DEBUG_DIR
die() {
    echo "ERROR: $*" >&2
    rm -rf $tmp
    exit 1
}
help() {
    grep '^##' $0 | cut -c3-
    rm -rf $tmp
    exit 0
}

##
## memory [--any] <proc>
##   Check <proc> related memory consumption using different tools on worker
##         or any (--any) nodes
##
cmd_memory() {
    proc=$1
    if test "$__any" = "yes"; then nodes=$(kubectl get nodes -o=custom-columns=:.metadata.name --no-headers=true)
    else nodes=$(kubectl get nodes -o=custom-columns=:.metadata.name --selector='!node-role.kubernetes.io/control-plane' --no-headers=true)
    fi

    for kworker in ${nodes}
    do
	if test -z "$(docker exec ${kworker} pgrep -f $proc)"
	then
	    echo "* Something went wrong or ${proc} does not running on this node ${kworker}"
	    echo "--------------------------------------------------------------------------------"
	    continue
	fi
	echo "${kworker}"
	kubectl get pod -n nsm-system -owide --field-selector spec.nodeName=${kworker} -l app=${proc}
	pid=$(docker exec ${kworker} pgrep -f "${proc}")
	echo "* memory usage for $proc listed by ps (RSS in kilobytes)"
	echo " ps -o pid -o rss -o size -p ${pid}"
	docker exec $kworker ps -o pid -o rss -o size -p ${pid}
	echo "* systemctl status $pid"
	docker exec $kworker systemctl status $pid 2> /dev/null
	echo "* cgroup fs current memory (Bytes)"
	cgroupdir=$(docker exec $kworker systemctl status ${pid} 2>/dev/null| grep CGroup| awk '{print $2}')
	docker exec $kworker cat /sys/fs/cgroup/${cgroupdir}/memory.current
	echo "--------------------------------------------------------------------------------"
    done
}


test -n "$1" || help
echo "$1" | grep -qi "^help\|-h" && help

cmd=$1
shift
grep -q "^cmd_$cmd()" $0 $hook || die "Invalid command [$cmd]"

while echo "$1" | grep -q '^--'; do
    if echo $1 | grep -q =; then
	o=$(echo "$1" | cut -d= -f1 | sed -e 's,-,_,g')
	v=$(echo "$1" | cut -d= -f2-)
	eval "$o=\"$v\""
    else
	o=$(echo "$1" | sed -e 's,-,_,g')
	eval "$o=yes"
    fi
    shift
done
unset o v
long_opts=`set | grep '^__' | cut -d= -f1`

# Execute command
trap "die Interrupted" INT TERM
cmd_$cmd "$@"
status=$?
rm -rf $tmp
