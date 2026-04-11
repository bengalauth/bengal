#BASEDIR="${0:a:h}"
BASEDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
sudo cp -rf ${BASEDIR}/../AuthorizationBundle/build/BengalLogin.bundle /Library/Security/SecurityAgentPlugins