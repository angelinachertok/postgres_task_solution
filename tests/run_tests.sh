#!/bin/bash

# Install dependencies
pip install -r requirements.txt

# Run tests
python tests/test_schema.py
