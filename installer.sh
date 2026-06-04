#!/bin/bash

# ============================================================
#   Stellar Theme & SubDomain Manager Installer
#   For Pterodactyl Panel
#   GitHub: https://github.com/NebulaCloudID/stellar
# ============================================================

PANEL_PATH="/var/www/pterodactyl"
GITHUB_RAW="https://raw.githubusercontent.com/NebulaCloudID/stellar/main"
BACKUP_DIR="/var/www/pterodactyl-backups"

STELLAR_ZIP="Stellar_v3_3_Plus_MCPack_with_Subdomain.zip"

# ============================================================
#   COLORS
# ============================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
RESET='\033[0m'

# ============================================================
#   BANNER
# ============================================================
print_banner() {
    clear
    echo -e "${CYAN}"
    echo "  ███████╗████████╗███████╗██╗     ██╗      █████╗ ██████╗ "
    echo "  ██╔════╝╚══██╔══╝██╔════╝██║     ██║     ██╔══██╗██╔══██╗"
    echo "  ███████╗   ██║   █████╗  ██║     ██║     ███████║██████╔╝"
    echo "  ╚════██║   ██║   ██╔══╝  ██║     ██║     ██╔══██║██╔══██╗"
    echo "  ███████║   ██║   ███████╗███████╗███████╗██║  ██║██║  ██║"
    echo "  ╚══════╝   ╚═╝   ╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝"
    echo -e "${RESET}"
    echo -e "${WHITE}  ╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "${WHITE}  ║       Pterodactyl Theme & Addon Installer v1.0          ║${RESET}"
    echo -e "${WHITE}  ║       Stellar Theme + SubDomain Manager                 ║${RESET}"
    echo -e "${WHITE}  ║       github.com/NebulaCloudID/stellar                  ║${RESET}"
    echo -e "${WHITE}  ╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# ============================================================
#   HELPERS
# ============================================================
info()    { echo -e "  ${CYAN}[INFO]${RESET}  $1"; }
success() { echo -e "  ${GREEN}[OK]${RESET}    $1"; }
warning() { echo -e "  ${YELLOW}[WARN]${RESET}  $1"; }
error()   { echo -e "  ${RED}[ERROR]${RESET} $1"; }
step()    { echo -e "\n  ${BOLD}${BLUE}▶ $1${RESET}"; }
die()     { error "$1"; echo ""; exit 1; }

confirm() {
    echo -ne "\n  ${YELLOW}$1 [y/N]: ${RESET}"
    read -r reply
    [[ "$reply" =~ ^[Yy]$ ]]
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        die "Please run as root or with sudo."
    fi
}

check_panel() {
    step "Checking panel installation..."
    if [ ! -d "$PANEL_PATH" ]; then
        die "Panel not found at $PANEL_PATH — please check your installation path."
    fi
    success "Panel found at $PANEL_PATH"
}

check_dependencies() {
    step "Checking dependencies..."
    local deps=("wget" "unzip" "php" "composer")
    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            success "$dep found"
        else
            warning "$dep not found — installing..."
            apt-get install -y "$dep" -qq || die "Failed to install $dep"
        fi
    done
}

check_node() {
    if command -v node &>/dev/null; then
        success "Node.js $(node -v) found"
    else
        warning "Node.js not found — installing..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash - -qq
        apt-get install -y nodejs -qq || die "Failed to install Node.js"
    fi
    if command -v yarn &>/dev/null; then
        success "Yarn found"
    else
        npm install -g yarn -q
    fi
}

fix_permissions() {
    step "Fixing permissions..."
    chown -R www-data:www-data "$PANEL_PATH"/* 2>/dev/null
    chmod -R 755 "$PANEL_PATH/storage" "$PANEL_PATH/bootstrap/cache" 2>/dev/null
    success "Permissions fixed"
}

build_assets() {
    step "Building frontend assets..."
    cd "$PANEL_PATH" || die "Cannot cd to $PANEL_PATH"
    yarn install --silent 2>/dev/null
    yarn build:production --silent 2>/dev/null
    success "Assets built successfully"
}

run_migrations() {
    step "Running database migrations..."
    cd "$PANEL_PATH" || die "Cannot cd to $PANEL_PATH"
    php artisan migrate --force --quiet || die "Migration failed"
    success "Migrations completed"
}

clear_cache() {
    step "Clearing application cache..."
    cd "$PANEL_PATH" || die "Cannot cd to $PANEL_PATH"
    php artisan config:clear --quiet
    php artisan cache:clear --quiet
    php artisan view:clear --quiet
    php artisan route:clear --quiet
    success "Cache cleared"
}

# ============================================================
#   BACKUP
# ============================================================
create_backup() {
    step "Creating backup..."
    local timestamp
    timestamp=$(date +"%Y%m%d_%H%M%S")
    local backup_path="$BACKUP_DIR/$timestamp"

    mkdir -p "$backup_path" || die "Cannot create backup directory"

    local dirs=("app" "resources" "routes" "database/migrations")
    for dir in "${dirs[@]}"; do
        if [ -d "$PANEL_PATH/$dir" ]; then
            cp -r "$PANEL_PATH/$dir" "$backup_path/" 2>/dev/null
        fi
    done

    echo "$timestamp" > "$BACKUP_DIR/latest"
    success "Backup created at $backup_path"
}

restore_backup() {
    print_banner
    step "Restore Backup"

    if [ ! -f "$BACKUP_DIR/latest" ]; then
        die "No backup found at $BACKUP_DIR"
    fi

    local latest
    latest=$(cat "$BACKUP_DIR/latest")
    local backup_path="$BACKUP_DIR/$latest"

    if [ ! -d "$backup_path" ]; then
        die "Backup directory not found: $backup_path"
    fi

    info "Latest backup: $latest"
    if ! confirm "Restore this backup? This will overwrite current files."; then
        info "Restore cancelled."
        exit 0
    fi

    step "Restoring files..."
    local dirs=("app" "resources" "routes" "database/migrations")
    for dir in "${dirs[@]}"; do
        if [ -d "$backup_path/$dir" ]; then
            rm -rf "$PANEL_PATH/$dir"
            cp -r "$backup_path/$dir" "$PANEL_PATH/" 2>/dev/null
            success "Restored: $dir"
        fi
    done

    fix_permissions
    run_migrations
    build_assets
    clear_cache

    echo ""
    echo -e "  ${GREEN}╔══════════════════════════════════════════╗${RESET}"
    echo -e "  ${GREEN}║     Restore completed successfully!      ║${RESET}"
    echo -e "  ${GREEN}╚══════════════════════════════════════════╝${RESET}"
    echo ""
}

# ============================================================
#   DOWNLOAD ZIP
# ============================================================
download_zip() {
    local url="$1"
    local dest="$2"
    local label="$3"

    info "Downloading $label..."
    info "URL: $url"

    if wget -q --show-progress -O "$dest" "$url" 2>&1; then
        if file "$dest" | grep -q "Zip archive\|zip"; then
            success "$label downloaded"
            return 0
        else
            error "Downloaded file is not a valid ZIP (possibly a 404 page)"
            error "Please make sure the file exists at: $url"
            rm -f "$dest"
            return 1
        fi
    else
        error "Failed to download $label"
        return 1
    fi
}

# ============================================================
#   INSTALL STELLAR + SUBDOMAIN (1 ZIP)
# ============================================================
install_stellar() {
    local mode="$1"
    local install_subdomain="$2"  # "yes" or "no"

    step "Stellar Theme — $mode"

    local tmp_dir
    tmp_dir=$(mktemp -d)

    download_zip \
        "${GITHUB_RAW}/releases/${STELLAR_ZIP}" \
        "$tmp_dir/stellar.zip" \
        "Stellar Theme + SubDomain Manager" || { rm -rf "$tmp_dir"; die "Download failed. Aborting."; }

    info "Extracting files..."
    unzip -q "$tmp_dir/stellar.zip" -d "$tmp_dir/stellar" || { rm -rf "$tmp_dir"; die "Failed to extract ZIP"; }

    # Find source folder
    local src
    if [ -d "$tmp_dir/stellar/pterodactyl" ]; then
        src="$tmp_dir/stellar/pterodactyl"
    else
        src=$(find "$tmp_dir/stellar" -maxdepth 2 -type d -name "pterodactyl" | head -1)
        [ -z "$src" ] && src="$tmp_dir/stellar" && warning "Using root of ZIP as source"
    fi

    info "Installing from: $src"

    # Always install core theme files
    local theme_dirs=("app" "resources" "routes" "config")
    for dir in "${theme_dirs[@]}"; do
        if [ -d "$src/$dir" ]; then
            cp -rf "$src/$dir/"* "$PANEL_PATH/$dir/" 2>/dev/null
            success "Installed: $dir"
        fi
    done

    [ -f "$src/tailwind.config.js" ] && cp "$src/tailwind.config.js" "$PANEL_PATH/" && success "Installed: tailwind.config.js"

    # Install migrations (includes subdomain migrations)
    if [ -d "$src/database/migrations" ]; then
        cp -rf "$src/database/migrations/"* "$PANEL_PATH/database/migrations/" 2>/dev/null
        success "Installed: database/migrations"
    fi

    rm -rf "$tmp_dir"

    if [ "$install_subdomain" = "yes" ]; then
        success "Stellar Theme + SubDomain Manager files installed"
    else
        success "Stellar Theme files installed"
    fi
}

# ============================================================
#   INSTALL FLOW
# ============================================================
do_install() {
    print_banner
    echo -e "  ${BOLD}Select what to install:${RESET}"
    echo ""
    echo -e "  ${GREEN}[1]${RESET} Stellar Theme + SubDomain Manager ${CYAN}(Recommended)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Stellar Theme only"
    echo -e "  ${RED}[0]${RESET} Cancel"
    echo ""
    echo -ne "  ${YELLOW}Your choice: ${RESET}"
    read -r choice

    case "$choice" in
        1|2) ;;
        0) info "Cancelled."; exit 0 ;;
        *) error "Invalid choice."; exit 1 ;;
    esac

    check_dependencies
    check_node
    create_backup

    case "$choice" in
        1) install_stellar "install" "yes" ;;
        2) install_stellar "install" "no" ;;
    esac

    run_migrations
    build_assets
    fix_permissions
    clear_cache

    echo ""
    echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "  ${GREEN}║          Installation completed successfully!            ║${RESET}"
    echo -e "  ${GREEN}║                                                          ║${RESET}"
    echo -e "  ${GREEN}║  Next steps:                                             ║${RESET}"
    echo -e "  ${GREEN}║  cd /var/www/pterodactyl                                 ║${RESET}"
    echo -e "  ${GREEN}║  php artisan queue:restart                               ║${RESET}"
    echo -e "  ${GREEN}║  Then reload your panel in the browser.                  ║${RESET}"
    echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# ============================================================
#   UPGRADE FLOW
# ============================================================
do_upgrade() {
    print_banner
    echo -e "  ${BOLD}Select what to upgrade:${RESET}"
    echo ""
    echo -e "  ${GREEN}[1]${RESET} Stellar Theme + SubDomain Manager ${CYAN}(Recommended)${RESET}"
    echo -e "  ${GREEN}[2]${RESET} Stellar Theme only"
    echo -e "  ${RED}[0]${RESET} Cancel"
    echo ""
    echo -ne "  ${YELLOW}Your choice: ${RESET}"
    read -r choice

    case "$choice" in
        1|2) ;;
        0) info "Cancelled."; exit 0 ;;
        *) error "Invalid choice."; exit 1 ;;
    esac

    check_dependencies
    check_node

    info "Creating backup before upgrade..."
    create_backup

    case "$choice" in
        1) install_stellar "upgrade" "yes" ;;
        2) install_stellar "upgrade" "no" ;;
    esac

    run_migrations
    build_assets
    fix_permissions
    clear_cache

    echo ""
    echo -e "  ${GREEN}╔══════════════════════════════════════════════════════════╗${RESET}"
    echo -e "  ${GREEN}║            Upgrade completed successfully!               ║${RESET}"
    echo -e "  ${GREEN}║                                                          ║${RESET}"
    echo -e "  ${GREEN}║  cd /var/www/pterodactyl && php artisan queue:restart    ║${RESET}"
    echo -e "  ${GREEN}╚══════════════════════════════════════════════════════════╝${RESET}"
    echo ""
}

# ============================================================
#   MAIN MENU
# ============================================================
main_menu() {
    print_banner
    echo -e "  ${BOLD}What would you like to do?${RESET}"
    echo ""
    echo -e "  ${GREEN}[1]${RESET} 🚀 Install"
    echo -e "  ${GREEN}[2]${RESET} ⬆️  Upgrade"
    echo -e "  ${GREEN}[3]${RESET} 🔄 Restore Backup"
    echo -e "  ${RED}[0]${RESET} ❌ Exit"
    echo ""
    echo -ne "  ${YELLOW}Your choice: ${RESET}"
    read -r main_choice

    case "$main_choice" in
        1) do_install ;;
        2) do_upgrade ;;
        3) restore_backup ;;
        0) echo ""; info "Bye!"; echo ""; exit 0 ;;
        *) error "Invalid choice."; main_menu ;;
    esac
}

# ============================================================
#   ENTRY POINT
# ============================================================
check_root
check_panel
main_menu
