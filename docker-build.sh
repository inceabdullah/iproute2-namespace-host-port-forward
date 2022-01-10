#!/bin/bash
docker rmi -f nshostforward > /dev/null 2>&1 
docker build . -t nshostforward
