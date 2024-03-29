#!/bin/bash

# ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.120"

ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.121"
ssh-keyscan -H 192.168.1.121 >> ~/.ssh/known_hosts

ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.122"
ssh-keyscan -H 192.168.1.122 >> ~/.ssh/known_hosts

ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.123"
ssh-keyscan -H 192.168.1.123 >> ~/.ssh/known_hosts

ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.124"
ssh-keyscan -H 192.168.1.124 >> ~/.ssh/known_hosts

ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.125"
ssh-keyscan -H 192.168.1.125 >> ~/.ssh/known_hosts

ssh-keygen -f "/home/nasenov/.ssh/known_hosts" -R "192.168.1.126"
ssh-keyscan -H 192.168.1.126 >> ~/.ssh/known_hosts
