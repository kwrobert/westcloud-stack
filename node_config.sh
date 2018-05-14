#!/bin/bash

apt update -y
apt upgrade -y
apt install -y python-pip python3 python3-pip
pip install ansible python-openstackclient
