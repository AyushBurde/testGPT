#!/bin/bash

set -x
set -e

# Install Keploy
curl --silent --location "https://github.com/keploy/keploy/releases/latest/download/keploy_linux_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/keploy /usr/local/bin/keploy
chmod +x /usr/local/bin/keploy
echo "Keploy installed successfully 🎉"

cd "${GITHUB_WORKSPACE}/${WORKDIR}"
echo "Working Directory: ${GITHUB_WORKSPACE}/${WORKDIR}"
ls

# Install dependencies and build app
if [[ "$COMMAND" =~ .*"go".* ]]; then
  echo "Go detected."
  go mod download
  go build -o application
  APP_COMMAND="./application"

elif [[ "$COMMAND" =~ .*"node".* ]]; then
  echo "Node detected."
  npm install
  APP_COMMAND="${COMMAND}"

elif [[ "$COMMAND" =~ .*"java".* ]] || [[ "$COMMAND" =~ .*"mvn".* ]]; then
  echo "Java detected."
  mvn clean install
  APP_COMMAND="${COMMAND}"

elif [[ "$COMMAND" =~ .*"python".* ]] || [[ "$COMMAND" =~ .*"python3".* ]]; then
  echo "Python detected."
  pip install -r requirements.txt
  APP_COMMAND="${COMMAND}"

else
  echo "Unsupported language or Docker required. Skipping record."
  echo 'Test Mode Starting 🎉'
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" \
    ${CONTAINER_NAME:+--containerName "${CONTAINER_NAME}"} \
    ${BUILD_DELAY:+--buildDelay ${BUILD_DELAY}}
  exit 0
fi

# Start app in background
${APP_COMMAND} &
APP_PID=$!
trap "kill $APP_PID" EXIT
sleep 3

# Check if app is running
curl http://127.0.0.1:${APP_PORT:-3000} || {
  echo "App not responding on port ${APP_PORT:-3000}."
  kill $APP_PID
  exit 1
}

# Record with Keploy
echo "Recording testcases with Keploy 🎥"
sudo -E keploy record -c "${APP_COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" > keploy_record.log 2>&1 &
RECORD_PID=$!
sleep 5

# Send requests during recording
for i in {1..3}; do
  curl http://127.0.0.1:${APP_PORT:-3000} || echo "Request $i failed"
  sleep 1
done

wait $RECORD_PID

# Retry recording if no test-sets are found
if [ ! -d "${KEPLOY_PATH}" ] || [ -z "$(ls -A "${KEPLOY_PATH}")" ]; then
  echo "No test-sets found in ${KEPLOY_PATH}. Retrying recording..."
  sudo -E keploy record -c "${APP_COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" > keploy_record_retry.log 2>&1 &
  RECORD_PID=$!
  sleep 5

  for i in {1..3}; do
    curl http://127.0.0.1:${APP_PORT:-3000} || echo "Retry request $i failed"
    sleep 1
  end

  wait $RECORD_PID
fi

# Final check if test-sets are recorded
if [ ! -d "${KEPLOY_PATH}" ] || [ -z "$(ls -A "${KEPLOY_PATH}")" ]; then
  echo "No test-sets found in ${KEPLOY_PATH} after retry. Recording failed."
  exit 1
fi

# Test with Keploy
echo "Running tests with Keploy 🎯"
sudo -E keploy test -c "${APP_COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
