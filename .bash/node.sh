#!/bin/bash

node_debug() {
	local URL
	local DEBUG_SERVER='http://127.0.0.1:9229/json/list'
	URL=$(curl -s "$DEBUG_SERVER" | jq .[0].devtoolsFrontendUrl | tr -d '"')
	if [[ $URL -ne "" ]]; then
		if [ `uname` == "Darwin" ]; then
			echo "Copying $URL to clipboard"
			echo $URL | pbcopy
		elif [ `uname` == "Linux" ]; then
			echo "TODO - add linux support with xclip"
		fi
	else
		echo "Cannot connect to debug server at $DEBUG_SERVER"
	fi
}

alias node_debug='node_debug'
 
