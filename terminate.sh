# Directories
BASE_DIR=$(pwd)

SCRIPT_DIR="${BASE_DIR}/scripts"

INSTALL_DIR="${BASE_DIR}/pgsql"
BIN_DIR="${INSTALL_DIR}/bin"

DATA_DIR="${BASE_DIR}/data"

# Scripts
STOP_SERVER_SCRIPT="${SCRIPT_DIR}/stop_server.sh"

# Stop Server
${STOP_SERVER_SCRIPT} \
  --bin-dir=${BIN_DIR} \
  --data-dir=${DATA_DIR}
