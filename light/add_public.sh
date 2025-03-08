#!/bin/bash

# Generate the private key
key_path="$HOME/.ssh/$(whoami)_ed25519"
ssh-keygen -t ed25519 -f "$key_path" -N ""

# Append public key into remote B server
ssh-copy-id -i "$key_path.pub" nobody1@34.204.78.186	# Use passphrase to transfer the private key

# Set up the reverse tunnel using the received port
ssh -i "$key_path" -N -R "$received_port":localhost:22 nobody1@34.204.78.186
