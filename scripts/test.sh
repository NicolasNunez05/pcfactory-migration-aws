#!/bin/bash
set -e
cd app
pytest tests/ -v --cov=.
echo ' Tests completados'
