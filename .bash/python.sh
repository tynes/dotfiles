#!/bin/bash

export PYTHON_3_VIRTUAL_ENV_PATH=$HOME/python
mkdir -p "$PYTHON_3_VIRTUAL_ENV_PATH"

# can run venv when not active with an argument to create/use
# that virtual env. can run with no args when active to deactivate
# from the activated virtual environment
function venv() {
    if [[ "$(which python)" =~ .*$PYTHON_3_VIRTUAL_ENV_PATH.* ]]; then
        deactivate
    else
        if [ "$#" -ne 1 ]; then
            echo "Usage: $ venv <virtual env name>"
            return 1
        fi
        echo "activating python environment: $1"
        local venv_path="${PYTHON_3_VIRTUAL_ENV_PATH}/${1}"
        python3 -m venv "$venv_path"
        source "$venv_path/bin/activate"
    fi
}
