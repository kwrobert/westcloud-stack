#!/bin/bash

ansible -B 86400 -P 0 -f 3 compute -m shell -a 'dispynode.py --dest_path_prefix /mnt/data/`date -I` -d --daemon 2>&1 >> dispynode.log &'
ansible -B 86400 -P 0 -f 3 headnode -m shell -a 'dispynode.py --dest_path_prefix /mnt/data/`date -I` -c 2 -d --daemon 2>&1 >> dispynode.log &'
