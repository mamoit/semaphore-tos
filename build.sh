#!/bin/bash

WD=`pwd`

# BUILD CAR
cd car
make $1

# BUILD SEMAPHORE
cd $WD/semaphore
make $1
