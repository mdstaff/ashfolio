#!/bin/zsh

# Ashfolio Development Environment Setup Script
# For macOS with Homebrew and zsh (default shell)
# Optimized for Apple Silicon (M1/M2) Macs

set -e  # Exit on any error

echo "🚀 Setting up Ashfolio development environment..."
echo "This script will install Elixir, Erlang, Phoenix, and other dependencies."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_status "Homebrew not found. Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    
    # Add Homebrew to PATH for Apple Silicon Macs (zsh is default shell on macOS)
    if [[ $(uname -m) == "arm64" ]]; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
        eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
else
    print_success "Homebrew is already installed"
fi

# Update Homebrew
print_status "Updating Homebrew..."
brew update

# Install Erlang and Elixir
if command -v erl &> /dev/null && command -v elixir &> /dev/null; then
    ERLANG_VERSION=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)
    ELIXIR_VERSION=$(elixir --version | head -n 1)
    print_success "Erlang/OTP $ERLANG_VERSION already installed"
    print_success "$ELIXIR_VERSION already installed"
else
    print_status "Installing Erlang and Elixir..."
    brew install erlang elixir
    
    # Verify installation
    if command -v erl &> /dev/null; then
        ERLANG_VERSION=$(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell)
        print_success "Erlang/OTP $ERLANG_VERSION installed successfully"
    else
        print_error "Erlang installation failed"
        exit 1
    fi

    if command -v elixir &> /dev/null; then
        ELIXIR_VERSION=$(elixir --version | head -n 1)
        print_success "$ELIXIR_VERSION installed successfully"
    else
        print_error "Elixir installation failed"
        exit 1
    fi
fi

# Install Hex package manager
if mix hex.info &> /dev/null; then
    HEX_VERSION=$(mix hex.info | grep "Hex version" | awk '{print $3}')
    print_success "Hex $HEX_VERSION already installed"
else
    print_status "Installing Hex package manager..."
    mix local.hex --force
    
    # Verify installation
    if mix hex.info &> /dev/null; then
        HEX_VERSION=$(mix hex.info | grep "Hex version" | awk '{print $3}')
        print_success "Hex $HEX_VERSION installed successfully"
    else
        print_error "Hex installation failed"
        exit 1
    fi
fi

# Install Phoenix framework
if mix phx.new --version &> /dev/null; then
    PHOENIX_VERSION=$(mix phx.new --version)
    print_success "Phoenix $PHOENIX_VERSION already installed"
else
    print_status "Installing Phoenix framework..."
    mix archive.install hex phx_new --force
    
    # Verify installation
    if mix phx.new --version &> /dev/null; then
        PHOENIX_VERSION=$(mix phx.new --version)
        print_success "Phoenix $PHOENIX_VERSION installed successfully"
    else
        print_error "Phoenix installation failed"
        exit 1
    fi
fi

# Install additional development tools
print_status "Installing additional development tools..."

# Install Node.js for asset compilation
if ! command -v node &> /dev/null; then
    print_status "Installing Node.js..."
    brew install node
    print_success "Node.js installed successfully"
else
    print_success "Node.js is already installed"
fi

# Install SQLite for database
if ! command -v sqlite3 &> /dev/null; then
    print_status "Installing SQLite..."
    brew install sqlite
    print_success "SQLite installed successfully"
else
    print_success "SQLite is already installed"
fi

# Install Git if not present
if ! command -v git &> /dev/null; then
    print_status "Installing Git..."
    brew install git
    print_success "Git installed successfully"
else
    print_success "Git is already installed"
fi

# Create project directory structure
print_status "Creating project directory structure..."
mkdir -p data
mkdir -p logs
mkdir -p tmp

if [[ -d "data" && -d "logs" && -d "tmp" ]]; then
    print_success "Project directories created/verified"
else
    print_error "Failed to create project directories"
    exit 1
fi

# Final verification
print_status "Running final verification..."

# Function to verify all tools are working
verify_installation() {
    local all_good=true
    
    # Test Erlang
    if ! erl -eval 'halt().' -noshell &> /dev/null; then
        print_error "Erlang verification failed"
        all_good=false
    fi
    
    # Test Elixir
    if ! elixir -e "System.version()" &> /dev/null; then
        print_error "Elixir verification failed"
        all_good=false
    fi
    
    # Test Hex
    if ! mix hex.info &> /dev/null; then
        print_error "Hex verification failed"
        all_good=false
    fi
    
    # Test Phoenix
    if ! mix phx.new --version &> /dev/null; then
        print_error "Phoenix verification failed"
        all_good=false
    fi
    
    # Test Node.js
    if ! node --version &> /dev/null; then
        print_error "Node.js verification failed"
        all_good=false
    fi
    
    # Test SQLite
    if ! sqlite3 --version &> /dev/null; then
        print_error "SQLite verification failed"
        all_good=false
    fi
    
    if [ "$all_good" = true ]; then
        print_success "All tools verified successfully!"
        return 0
    else
        print_error "Some tools failed verification. Please check the errors above."
        return 1
    fi
}

if verify_installation; then
    echo ""
    echo "🎉 Development environment setup complete!"
    echo ""
    echo "Installed versions:"
    echo "  • Erlang/OTP: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo 'Unknown')"
    echo "  • Elixir: $(elixir -e "IO.puts System.version()" 2>/dev/null || echo 'Unknown')"
    echo "  • Hex: $(mix hex.info 2>/dev/null | grep "Hex version" | awk '{print $3}' || echo 'Unknown')"
    echo "  • Phoenix: $(mix phx.new --version 2>/dev/null | awk '{print $2}' || echo 'Unknown')"
    echo "  • Node.js: $(node --version 2>/dev/null || echo 'Unknown')"
    echo "  • SQLite: $(sqlite3 --version 2>/dev/null | awk '{print $1}' || echo 'Unknown')"
    echo ""
    echo "Next steps:"
    echo "  1. Run 'source ~/.zshrc' to reload your shell environment"
    echo "  2. Install project dependencies: mix deps.get"
    echo "  4. Set up the database: mix ecto.setup"
    echo "  5. Start the development server: mix phx.server"
    echo ""
    print_success "Ready to start developing Ashfolio! 🚀"
else
    echo ""
    print_error "Setup completed with errors. Please review the output above and fix any issues."
    exit 1
fi