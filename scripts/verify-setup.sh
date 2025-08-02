#!/bin/zsh

# Ashfolio Development Environment Verification Script
# Verifies that all required tools are properly installed

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

echo "🔍 Verifying Ashfolio development environment..."
echo ""

# Track overall status
all_good=true

# Check Erlang
print_status "Checking Erlang/OTP..."
if command -v erl &> /dev/null; then
    erlang_version=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null)
    print_success "Erlang/OTP $erlang_version installed"
else
    print_error "Erlang not found"
    all_good=false
fi

# Check Elixir
print_status "Checking Elixir..."
if command -v elixir &> /dev/null; then
    # Use a safer method to get Elixir version that doesn't cause crashes
    elixir_version=$(elixir -e "IO.puts System.version()" 2>/dev/null || echo "installed")
    print_success "Elixir $elixir_version installed"
else
    print_error "Elixir not found"
    all_good=false
fi

# Check Hex
print_status "Checking Hex package manager..."
if mix hex.info &> /dev/null; then
    hex_version=$(mix hex.info | grep "Hex version" | awk '{print $3}')
    print_success "Hex $hex_version installed"
else
    print_error "Hex not found or not working"
    all_good=false
fi

# Check Phoenix
print_status "Checking Phoenix framework..."
if mix phx.new --version &> /dev/null; then
    phoenix_version=$(mix phx.new --version | awk '{print $3}')
    print_success "Phoenix $phoenix_version installed"
else
    print_error "Phoenix not found or not working"
    all_good=false
fi

# Check Node.js
print_status "Checking Node.js..."
if command -v node &> /dev/null; then
    node_version=$(node --version)
    print_success "Node.js $node_version installed"
else
    print_error "Node.js not found"
    all_good=false
fi

# Check npm
print_status "Checking npm..."
if command -v npm &> /dev/null; then
    npm_version=$(npm --version)
    print_success "npm $npm_version installed"
else
    print_error "npm not found"
    all_good=false
fi

# Check SQLite
print_status "Checking SQLite..."
if command -v sqlite3 &> /dev/null; then
    sqlite_version=$(sqlite3 --version | awk '{print $1}')
    print_success "SQLite $sqlite_version installed"
else
    print_error "SQLite not found"
    all_good=false
fi

# Check Git
print_status "Checking Git..."
if command -v git &> /dev/null; then
    git_version=$(git --version | awk '{print $3}')
    print_success "Git $git_version installed"
else
    print_error "Git not found"
    all_good=false
fi

# Check Homebrew
print_status "Checking Homebrew..."
if command -v brew &> /dev/null; then
    brew_version=$(brew --version | head -n 1 | awk '{print $2}')
    print_success "Homebrew $brew_version installed"
else
    print_warning "Homebrew not found (optional but recommended)"
fi

# Check project directories
print_status "Checking project directories..."
missing_dirs=()
for dir in "data" "logs" "tmp"; do
    if [[ ! -d "$dir" ]]; then
        missing_dirs+=("$dir")
    fi
done

if [[ ${#missing_dirs[@]} -eq 0 ]]; then
    print_success "All project directories exist"
else
    print_warning "Missing directories: ${missing_dirs[*]} (will be created automatically)"
fi

echo ""

# Final status
if [[ "$all_good" == true ]]; then
    echo "✅ All required tools are properly installed!"
    echo ""
    echo "You're ready to start developing Ashfolio:"
    echo "  1. Install project dependencies: mix deps.get"
    echo "  2. Set up the database: mix ecto.setup"
    echo "  3. Start the development server: mix phx.server"
    echo ""
    exit 0
else
    echo "❌ Some required tools are missing or not working properly."
    echo ""
    echo "Please run the setup script to install missing dependencies:"
    echo "  ./scripts/setup-dev-env.sh"
    echo ""
    exit 1
fi