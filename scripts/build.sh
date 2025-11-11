#!/bin/bash
set -e
cd app
pip install --upgrade pip
pip install -r requirements.txt
echo ' Build completado'
