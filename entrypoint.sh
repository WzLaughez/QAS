#!/bin/bash
set -e

echo "🔁 Checking if model 'llama3' is available..."
if ! ollama list | grep -q "llama3"; then
    echo "📥 Pulling model 'llama3'..."
    ollama pull llama3
else
    echo "✅ Model 'llama3' already pulled."
fi

echo "🚀 Starting Ollama server..."
exec "$@"
