#!/usr/bin/env bash

# Run this on a host that have access to your swarm manager and all workers

swarm_manager='deb-docker1'
stack_name='mongo_sharded'
replica_sets_initiators=(
    'config01'
    'shard01b'
    'shard02b'
    'shard03b'
    )
scripts=(
    'init-configserver.js'
    'init-shard01.js'
    'init-shard02.js'
    'init-shard03.js'
)

router='router'
router_replicas=3
router_script='init-router.js'

# For docker remote exec
_docker_manage="/usr/bin/env ssh $swarm_manager sudo docker"
_ssh="/usr/bin/env ssh"

##########################################################################

function is_unique () {
    res=$($_docker_manage stack ps "$stack_name" -q -f name="$1" -f desired-state=running | wc -l)
    return $((res - 1))
}
function get_node_by_service () {
    # Give a service name as argument and print the swarm node that is executing it
    #$_docker service ps -f name="$1" -f desired-state=running "$1" --format="{{.Node}}"

    $_docker_manage stack ps "$stack_name" -f name="$1" -f desired-state=running --format="{{.Node}}"
    return $?
}
function get_service_id () {
    #$_docker service ps -f name="$1" -f desired-state=running "$1" -q --no-trunc

    $_docker_manage stack ps "$stack_name" -f name="$1" -f desired-state=running -q --no-trunc
    return $?
}

##########################################################################

# Initialize Replica Sets
for i in "${!replica_sets_initiators[@]}"; do
    err=""
    service_name="${stack_name}_${replica_sets_initiators[i]}"
    if ! is_unique "$service_name"; then
        err+="Error: $service_name is not unique\n"
    fi
    node="$(get_node_by_service $service_name)"
    if [ -z "$node" ]; then
        err+="Error: failed to retrieve worker node for $service_name\n"
    fi
    service_id="$(get_service_id $service_name)"
    if [ -z "$service_id" ]; then
        err+="Error: failed to retrieve worker node for $service_name\n"
    fi

    if [ ! -z "$err" ]; then
        echo -ne "One or more errors occured:\n${err}\nAborting\n" >&2
        exit 1
    fi

    echo -e "\n[*] Initializing $service_name\n"
    $_ssh "$node" "sudo docker exec '${service_name}.1.${service_id}' sh -c 'mongo --port 27017 < /scripts/${scripts[i]}'"
    #$_ssh "$node" "sudo docker exec '${service_name}.1.${service_id}' sh -c 'cat < /scripts/${scripts[i]}'"
    [ $? -ne 0 ] && echo "Error: could not initialize $service_name" >&2 && exit 1
done

#echo "Sleeping 20sec to be sure that all replica set are initialized..."
#for i in $(seq 1 20); do
#    echo -ne "\r\033[K$i"
#    sleep 1
#done
#echo ''

# Initialize routers
# Breaking news: only 1 router needs to be initialized, as the others ones
# get all their conf/metadata from config servers, which are authenticated
# with the keyFile!!
# https://programmersought.com/article/69584268245/

#for i in $(seq 1 $router_replicas); do
for i in '1'; do
    err=""
    service_name="${stack_name}_${router}.$i" # stack_router.1
    if ! is_unique "$service_name"; then
        err+="Error: $service_name is not unique\n"
    fi
    node="$(get_node_by_service $service_name)"
    if [ -z "$node" ]; then
        err+="Error: failed to retrieve worker node for $service_name\n"
    fi
    service_id="$(get_service_id $service_name)"
    if [ -z "$service_id" ]; then
        err+="Error: failed to retrieve worker node for $service_name\n"
    fi

    if [ ! -z "$err" ]; then
        echo -ne "One or more errors occured:\n${err}\nAborting\n" >&2
        exit 1
    fi

    echo -e "\n[*] Initializing $service_name\n"
    $_ssh "$node" "sudo docker exec '${service_name}.${service_id}' sh -c 'mongo --port 27017 < /scripts/${router_script}'"
    #$_ssh "$node" "sudo docker exec '${service_name}.${service_id}' sh -c 'cat < /scripts/${router_script}'"
    [ $? -ne 0 ] && echo "Error: could not initialize $service_name" >&2 && exit 1
done

echo -e "\n[*] You should now be able to connect to your mongo cluster:\n"
echo -e "mongo mongodb://mongo1:27017,mongo2:27017,mongo3:27017\n"

exit $?
