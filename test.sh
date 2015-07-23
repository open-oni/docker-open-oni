#!/bin/bash

BATCH=$1

source /opt/chronam/ENV/bin/activate

cd /opt/chronam
django-admin.py test core