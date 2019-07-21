#!/bin/sh

service knot stop
sleep 3
rm /var/lib/knot/journal/*
rm /var/lib/knot/timers/*
rm /var/lib/knot/zones/*.zone
rm /var/log/knot/knot.log
