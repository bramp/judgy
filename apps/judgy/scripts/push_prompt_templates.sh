#!/bin/bash
# Pushes the local YAML prompt templates to Firebase AI Logic using the REST API.
# Requirements: gcloud CLI (authenticated and configured for the right project).

PROJECT_ID=$(gcloud config get-value project)
LOCATION="global" # Templates are typically created globally

if [ -z "$PROJECT_ID" ]; then
  echo "Error: Could not determine Google Cloud Project ID. Run 'gcloud config set project YOUR_PROJECT_ID'."
  exit 1
fi

echo "Deploying prompt templates to project: $PROJECT_ID..."
TOKEN=$(gcloud auth print-access-token)

function deploy_template() {
  local TEMPLATE_ID=$1
  local FILE_PATH=$2

  echo "Deploying $TEMPLATE_ID from $FILE_PATH..."

  # Note: The exact endpoint and payload format for Firebase AI Logic server templates
  # might be updated since it's currently a Preview feature.
  # This uses the v1beta create endpoint which generally expects a PromptTemplate JSON object
  # containing the template config, but we try passing the raw YAML if the CLI doesn't exist yet.

  curl -s -X POST "https://firebaseml.googleapis.com/v1beta/projects/$PROJECT_ID/locations/$LOCATION/templates?templateId=$TEMPLATE_ID" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/yaml" \
    --data-binary @"$FILE_PATH" | jq .
}

deploy_template "bot-select-noun" "../prompt_templates/bot-select-noun.yaml"
deploy_template "bot-judge" "../prompt_templates/bot-judge.yaml"

echo "Done."
