#!/bin/bash
# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Printf format functions
printf_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$@"
}

printf_success() {
    printf "${GREEN}[SUCCESS]${NC} %s\n" "$@"
}

printf_warning() {
    printf "${YELLOW}[WARNING]${NC} %s\n" "$@"
}

printf_info() {
    printf "${BLUE}[INFO]${NC} %s\n" "$@"
}

printf_debug() {
    [[ "${DEBUG}" == "true" ]] && printf "${BLUE}[DEBUG]${NC} %s\n" "$@"
}