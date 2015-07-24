#!/bin/bash

APP=core

source /opt/chronam/ENV/bin/activate

cd /opt/chronam
django-admin.py test $APP