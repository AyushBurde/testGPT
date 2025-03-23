# Install Keploy binary using curl command
set -x
curl --silent --location "https://github.com/keploy/keploy/releases/latest/download/keploy_linux_amd64.tar.gz" | tar xz -C /tmp
echo "curl --silent --location 'https://github.com/keploy/keploy/releases/latest/download/keploy_linux_amd64.tar.gz' | tar xz -C /tmp"

sudo mv /tmp/keploy /usr/local/bin/keploy
chmod +x /usr/local/bin/keploy

echo "Keploy installed successfully 🎉"

cd ${GITHUB_WORKSPACE}/${WORKDIR}
echo "${GITHUB_WORKSPACE}/${WORKDIR}"
# Generate app binary
echo "ls"
ls

if [[ "$COMMAND" =~ .*"go".* ]]; then
  echo "go is present."
  go mod download
  go build -o application
    echo "Starting Server in Background"
  ${COMMAND} &  # this runs `node dummy.js` in the background
  sleep 3 
  curl 127.0.0.1:3000
  echo 'Record Mode Starting 🎥'
  sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  echo 'Test Mode Starting 🎉'
  echo sudo -E keploy test -c "./application" --delay ${DELAY} --path "${KEPLOY_PATH}"
  sudo -E keploy test -c "./application" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"node".* ]]; then
  echo "Node is present."
  npm install
    ${COMMAND} & 
   sleep 3 
  curl 127.0.0.1:3000
  echo 'Record Mode Starting 🎥'
sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  echo 'Test Mode Starting 🎉'
  echo sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"java".* ]]  || [[ "$COMMAND" =~ .*"mvn".* ]]; then
  echo "Java is present."
  mvn clean install
    ${COMMAND} & 
   sleep 3 
  curl 127.0.0.1:3000
  echo 'Record Mode Starting 🎥'
sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  echo 'Test Mode Starting 🎉'
  echo sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"python".* ]] || [[ "$COMMAND" =~ .*"python3".* ]]; then
  echo "Python is present."
  pip install -r requirements.txt
    ${COMMAND} & 
   sleep 3 
  curl 127.0.0.1:3000
  echo 'Record Mode Starting 🎥'
sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  echo 'Test Mode Starting 🎉'
  echo sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"

elif [[ "$COMMAND" =~ .*"docker-compose".* ]] || [[ "$COMMAND" =~ .*"docker compose".* ]]; then
  echo "Docker compose is present."
    ${COMMAND} & 
   sleep 3 
  curl 127.0.0.1:3000
  echo 'Record Mode Starting 🎥'
sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  echo 'Test Mode Starting 🎉'
  echo sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" --containerName "${CONTAINER_NAME}" --buildDelay ${BUILD_DELAY}
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" --containerName "${CONTAINER_NAME}" --buildDelay ${BUILD_DELAY}

elif [[ "$COMMAND" =~ .*"docker".* ]]; then
  echo "Docker is present."
    ${COMMAND} & 
   sleep 3 
  curl 127.0.0.1:3000
  echo 'Record Mode Starting 🎥'
sudo -E keploy record -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}"
  echo 'Test Mode Starting 🎉'
  echo sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" --buildDelay ${BUILD_DELAY}
  sudo -E keploy test -c "${COMMAND}" --delay ${DELAY} --path "${KEPLOY_PATH}" --buildDelay ${BUILD_DELAY}

else
echo "Language not found, but proceeding anyway."

fi