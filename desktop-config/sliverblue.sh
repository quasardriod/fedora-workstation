#!/bin/bash

source ./include/formatter.sh

# Check if os variant is Fedora Silverblue
if [[ "$(cat /etc/os-release | grep '^VARIANT_ID=')" != "VARIANT_ID=silverblue" ]]; then
    printf_error "This script is intended to be run on Fedora Silverblue."
    exit 1
fi
printf_info "Detected Fedora Silverblue."

function install_powerline_go() {
    printf_info "Installing Powerline Go..."
    if command -v powerline-go &> /dev/null; then
        printf_info "Powerline Go is already installed."
        return
    fi
    sudo rpm-ostree install powerline-go
    if [[ $? -ne 0 ]]; then
        printf_error "Failed to install Powerline."
        exit 1
    fi
    printf_success "Powerline installed successfully."
}

function configure_powerline_go_prompt() {
    # Check if _upload_ps1 function already exists in .bashrc
    if grep -q "_update_ps1" ~/.bashrc; then
        printf_info "Powerline Go prompt is already configured in .bashrc."
        return
    fi
    printf_info "Configuring Powerline Go Prompt..."
    cat << 'EOF' >> ~/.bashrc
# Powerline Go Prompt Configuration
function _update_ps1(){
    local venv=""
    if [[ -n "$VIRTUAL_ENV" ]]; then
        venv="($(basename $VIRTUAL_ENV)) "
    fi
    PS1="${venv}$(powerline-go     \
        -error $? \
        -colorize-hostname \
        -newline \
        -cwd-max-depth 4 \
        -cwd-mode plain \
        -truncate-segment-width 64 \
        -shorten-gke-names \
        -shell bash \
        -modules "aws,host,docker,cwd,perms,git,kube,exit,root,venv" \
        -priority "root,cwd,perms,git-branch,git-status,user,venv,exit,host" \
        -shorten-openshift-names \
        -max-width 90
    )"
}

if [ "$TERM" != "linux" ];then
        PROMPT_COMMAND="_update_ps1; $PROMPT_COMMAND"
fi
EOF
    if [[ $? -ne 0 ]]; then
        printf_error "Failed to configure Powerline Go prompt."
        exit 1
    fi

    printf_success "Powerline Go configured successfully."
}

function main() {
    install_powerline_go
    configure_powerline_go_prompt
    printf_success "All tasks completed successfully."
}

main