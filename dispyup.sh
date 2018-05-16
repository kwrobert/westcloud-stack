#!/bin/bash

ansible -B 86400 -P 0 -f 3 compute -m shell -a '(/home/ubuntu/.local/bin/dispynode.py --clean --dest_path_prefix /mnt/data/`date -I` -d --daemon > dispynode.log 2>&1 &)'
ansible -B 86400 -P 0 -f 3 headnode -m shell -a '(/home/ubuntu/.local/bin/dispynode.py --clean --dest_path_prefix /mnt/data/`date -I` -c 2 -d --daemon > dispynode.log 2>&1 &)'
