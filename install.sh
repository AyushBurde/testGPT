#!/bin/bash

set -x # Debug mode
set -e # Exit on any command failure

# Install Keploy binary
curl --silent --location "https://github.com/keploy/keploy/releases/latest/download/keploy_linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/keploy /usr/local/bin/keploy
chmod +x /usr/local/bin/keploy
echo "Keploy installed successfully 🎉"

# Validate required environment variables
if [ -z "$COMMAND" ]; then
  echo "Error: COMMAND is not set." >&2
  exit 1
fi

if [ -z "$DELAY" ]; then
  echo "Error: DELAY is not set." >&2
  exit 1
fi

if [ -z "$KEPLOY_PATH" ]; then
  echo "Error: KEPLOY_PATH is not set." >&2
  exit 1
fi

if [ -z "$WORKDIR" ]; then
  echo "Error: WORKDIR is not set." >&2
  exit 1
fi

APP_PORT=${APP_PORT:-3000} # Default to port 3000 if not set

cd "${GITHUB_WORKSPACE}/${WORKDIR}"
echo "Working Directory: ${GITHUB_WORKSPACE}/${WORKDIR}"
ls

# Function to check if the application is running
check_application_running() {
  curl http://127.0.0.1:$APP_PORT || {
    echo "Error: Application is not running on port $APP_PORT." >&2
    exit 1
  }
}

# Function to check if test cases were recorded
check_test_cases_recorded() {
  if [ ! -d "${KEPLOY_PATH}" ] || [ -z "$(ls -A "${KEPLOY_PATH}")" ]; then
    echo "Error: No test cases found in ${KEPLOY_PATH}. Please ensure test cases are recorded." >&2
    exit 1
  fi
}

if [[ "$COMMAND" =~ .*"go".* ]]; then
  echo "Go is present."
  go mod download
  go build -o application
  echo "Starting Server in Background"
  ${COMMAND} &
  APP_PID=$!
  trap "kill $APP_PID" EXIT
  sleep 3
  check_application_running
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  check_test_cases_recorded
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "./application" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"node".* ]]; then
  echo "Node is present."
  npm install
  ${COMMAND} &
  APP_PID=$!
  trap "kill $APP_PID" EXIT
  sleep 3
  check_application_running
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  check_test_cases_recorded
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"java".* ]] || [[ "$COMMAND" =~ .*"mvn".* ]]; then
  echo "Java is present."
  mvn clean install
  ${COMMAND} &
  APP_PID=$!
  trap "kill $APP_PID" EXIT
  sleep 3
  check_application_running
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  check_test_cases_recorded
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"python".* ]] || [[ "$COMMAND" =~ .*"python3".* ]]; then
  echo "Python is present."
  pip install -r requirements.txt
  ${COMMAND} &
  APP_PID=$!
  trap "kill $APP_PID" EXIT
  sleep 3
  check_application_running
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  check_test_cases_recorded
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"docker-compose".* ]] || [[ "$COMMAND" =~ .*"docker compose".* ]]; then
  echo "Docker Compose is present."
  ${COMMAND} &
  APP_PID=$!
  trap "kill $APP_PID" EXIT
  sleep 3
  check_application_running
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  check_test_cases_recorded
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" --containerName "${CONTAINER_NAME}" --buildDelay ${BUILD_DELAY}

elif [[ "$COMMAND" =~ .*"docker".* ]]; then
  echo "Docker is present."
  ${COMMAND} &
  APP_PID=$!
  trap "kill $APP_PID" EXIT
  sleep 3
  check_application_running
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  check_test_cases_recorded
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" --buildDelay ${BUILD_DELAY}

else
  echo "Language not found, but proceeding anyway."
fi