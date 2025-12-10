#!/bin/bash

# GLM-4.6 Entry Point for Multi-Session AI IDE
set -e

function setup_glm_environment() {
    echo "🤖 GLM-4.6 Multi-Session Environment Initializing..."
    
    if [[ -z "$ZAI_API_KEY" ]]; then
        echo "❌ ZAI_API_KEY not set. Please set ZAI_API_KEY environment variable."
        echo "💡 Get your API key from: https://z.ai/manage-apikey"
        exit 1
    fi
    
    export GLM_MODEL=${GLM_MODEL:-"glm-4.6"}
    export SESSION_ID=${SESSION_ID:-"$(date +%s)"}
    export GLM_WORKSPACE_ROOT=${GLM_WORKSPACE_ROOT:-"/workspace"}
    
    mkdir -p "$GLM_WORKSPACE_ROOT"
    
    echo "✅ GLM-4.6 environment ready"
    echo "📋 Model: $GLM_MODEL"
    echo "🆔 Session ID: $SESSION_ID"
    echo "📁 Workspace: $GLM_WORKSPACE_ROOT"
}

function main() {
    setup_glm_environment
    
    echo ""
    echo "🚀 Starting GLM-4.6 session..."
    
    if [[ $# -gt 0 ]]; then
        echo "🎯 Executing: claude $*"
        exec claude "$@"
    else
        echo "🎯 Starting interactive GLM session..."
        exec claude
    fi
}

main "$@"
