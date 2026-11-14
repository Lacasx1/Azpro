#!/bin/bash

# ============================================
# Azpro Menu - Free v5
# ============================================

LKPROXY="/opt/mpro/proxy"
LKPROXY_XHTTP="/opt/mpro/proxy-xhttp"
LKPROXY_INTEGRATED="/opt/mpro/proxy-integrated"
BYPASS_DIR="/opt/mpro"
LEGACY_MULTIPROTOCOL_FLAG="${BYPASS_DIR}/multiprotocol.enabled"
SYSTEMD_DIR="/etc/systemd/system"
LANGUAGE_FILE="${BYPASS_DIR}/language"
HCR_PORT="8880"
HCR_SERVICE="hcr-8880.service"
HCR_SSH_TARGET="127.0.0.1:22"
HCR_BINARY_CANDIDATES=("${BYPASS_DIR}/hcr-server" "/opt/hcr-server/hcr-server" "/usr/local/bin/hcr-server" "/usr/bin/hcr-server")
# Fonte pública do binário oficial hcr-server (Linux amd64). Pode ser trocada
# exportando HCR_SOURCE_URL antes de abrir o menu.
HCR_SOURCE_URL="${HCR_SOURCE_URL:-https://raw.githubusercontent.com/decodezsniff-art/hcr-server/main/hcr-server}"

# Cores
RED='\033[0;31m'
GREEN='\033[0;33m'
LIGHT_GREEN='\033[1;92m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
AQUA='\033[1;36m'
WHITE='\033[0;37m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

BOX_WIDTH=46
# The box includes four border/padding columns. Keep it within the terminal
# width so narrow mobile terminals do not wrap the English menu lines.
if [[ "${COLUMNS:-}" =~ ^[0-9]+$ ]] && (( COLUMNS >= 28 && COLUMNS < BOX_WIDTH + 4 )); then
    BOX_WIDTH=$((COLUMNS - 4))
fi

get_language() {
    local LANGUAGE="pt-BR"
    if [[ -f "$LANGUAGE_FILE" ]]; then
        LANGUAGE=$(cat "$LANGUAGE_FILE")
    fi
    case "$LANGUAGE" in
        pt-BR|en|es) printf '%s' "$LANGUAGE" ;;
        *) printf 'pt-BR' ;;
    esac
}

language_text() {
    local KEY="$1" LANGUAGE="${2:-$(get_language)}"
    case "${LANGUAGE}:${KEY}" in
        en:running) printf 'RUNNING' ;;
        en:active_ports) printf 'Active port(s):' ;;
        en:multiprotocol) printf 'MULTIPROTOCOL:' ;;
        en:active) printf 'ACTIVE' ;;
        en:offline) printf 'OFFLINE' ;;
        en:open_port) printf 'CONFIGURE PORTS' ;;
        en:close_port) printf 'CLOSE OPEN PORT' ;;
        en:restart_port) printf 'RESTART PORT' ;;
        en:xhttp) printf 'XHTTP + SSL TUNNEL' ;;
        en:integrated) printf 'INTEGRATED PROTOCOL' ;;
        en:update) printf 'UPDATE FROM GITHUB' ;;
        en:status) printf 'MULTIPROTOCOL + STATUS' ;;
        en:uninstall) printf 'UNINSTALL AZPRO' ;;
        en:language) printf 'LANGUAGE / IDIOMA' ;;
        en:exit) printf 'EXIT' ;;
        en:choose) printf 'Choose an option:' ;;
        en:open_title) printf 'Open Port' ;;
        en:default_ports) printf 'Default ports: 80, 8080, 8880, 3128' ;;
        en:port443_hint) printf 'Port 443: use option [04] XHTTP + SSL Tunnel' ;;
        en:port_prompt) printf 'Port:' ;;
        en:https_prompt) printf 'Enable HTTPS/TLS? (y/n):' ;;
        en:http_status_prompt) printf 'HTTP status (Default: @Azpro):' ;;
        en:xhttp_title) printf 'xHTTP_SSH / SSL TUNNEL - Port 443' ;;
        en:status_name_prompt) printf 'HTTP status name:' ;;
        en:integrated_title) printf 'CURRENT CONFIGURATION' ;;
        en:port_label) printf 'Port:' ;;
        en:subnet_label) printf 'Subnet:' ;;
        en:tun_label) printf 'TUN interface:' ;;
        en:protocols_label) printf 'Protocols:' ;;
        en:enable_udp_prompt) printf 'Enable UDP on the same port? (y/N)' ;;
        en:enable_quic_prompt) printf 'Enable QUIC? (y/N)' ;;
        en:quic_port_prompt) printf 'QUIC port (Enter for 8001):' ;;
        en:status_http_prompt) printf 'HTTP status name:' ;;
        en:back) printf 'BACK' ;;
        en:select_port) printf 'Select port:' ;;
        en:restart_title) printf 'Restart open port' ;;
        en:close_title) printf 'Close open port' ;;
        en:choose_port_restart) printf 'Choose port to restart:' ;;
        en:choose_port_close) printf 'Choose port to close:' ;;
        en:no_active) printf 'No active Azpro service.' ;;
        en:special_open) printf 'OPEN / CONFIGURE' ;;
        en:special_restart) printf 'RESTART PORT' ;;
        en:special_close) printf 'CLOSE PORT' ;;
        en:choose_action) printf 'Choose an option:' ;;
        en:update_title) printf 'Update Azpro from GitHub' ;;
        en:update_rebuild) printf 'The update recompiles the binaries.' ;;
        en:update_restart) printf 'Services may restart.' ;;
        en:update_reload) printf 'The menu will reload when finished.' ;;
        en:update_confirm) printf 'Continue with the update? (y/N):' ;;
        en:uninstall_title) printf 'UNINSTALL Azpro' ;;
        en:uninstall_desc1) printf 'Stops services and removes proxy binaries.' ;;
        en:uninstall_desc2) printf 'Removes TLS certificates from /opt/mpro.' ;;
        en:uninstall_desc3) printf 'Preserves SSH, Rust, OpenSSL and other files.' ;;
        en:confirm_yes) printf 'To uninstall, type: y' ;;
        en:confirm_no) printf 'To cancel, type: n' ;;
        es:running) printf 'EN EJECUCIÓN' ;;
        es:active_ports) printf 'Puerto(s) activo(s):' ;;
        es:multiprotocol) printf 'MULTIPROTOCOLO:' ;;
        es:active) printf 'ACTIVO' ;;
        es:offline) printf 'DESCONECTADO' ;;
        es:open_port) printf 'CONFIGURAR PUERTOS' ;;
        es:close_port) printf 'CERRAR PUERTO ABIERTO' ;;
        es:restart_port) printf 'REINICIAR PUERTO' ;;
        es:xhttp) printf 'XHTTP + TÚNEL SSL' ;;
        es:integrated) printf 'PROTOCOLO INTEGRADO' ;;
        es:update) printf 'ACTUALIZAR DESDE GITHUB' ;;
        es:status) printf 'MULTIPROTOCOLO + ESTADO' ;;
        es:uninstall) printf 'DESINSTALAR AZPRO' ;;
        es:language) printf 'IDIOMA / LANGUAGE' ;;
        es:exit) printf 'SALIR' ;;
        es:choose) printf 'Seleccione una opción:' ;;
        es:open_title) printf 'Abrir puerto' ;;
        es:default_ports) printf 'Puertos predeterminados: 80, 8080, 8880, 3128' ;;
        es:port443_hint) printf 'Puerto 443: use la opción [04] XHTTP + SSL Tunnel' ;;
        es:port_prompt) printf 'Puerto:' ;;
        es:https_prompt) printf '¿Activar HTTPS/TLS? (s/n):' ;;
        es:http_status_prompt) printf 'Estado HTTP (Predeterminado: @Azpro):' ;;
        es:xhttp_title) printf 'xHTTP_SSH / TÚNEL SSL - Puerto 443' ;;
        es:status_name_prompt) printf 'Nombre del estado HTTP:' ;;
        es:integrated_title) printf 'CONFIGURACIÓN ACTUAL' ;;
        es:port_label) printf 'Puerto:' ;;
        es:subnet_label) printf 'Subred:' ;;
        es:tun_label) printf 'Interfaz TUN:' ;;
        es:protocols_label) printf 'Protocolos:' ;;
        es:enable_udp_prompt) printf '¿Activar UDP en el mismo puerto? (s/N)' ;;
        es:enable_quic_prompt) printf '¿Activar QUIC? (s/N)' ;;
        es:quic_port_prompt) printf 'Puerto QUIC (Enter para 8001):' ;;
        es:status_http_prompt) printf 'Nombre del estado HTTP:' ;;
        es:back) printf 'VOLVER' ;;
        es:select_port) printf 'Seleccione el puerto:' ;;
        es:restart_title) printf 'Reiniciar puerto abierto' ;;
        es:close_title) printf 'Cerrar puerto abierto' ;;
        es:choose_port_restart) printf 'Elija el puerto para reiniciar:' ;;
        es:choose_port_close) printf 'Elija el puerto para cerrar:' ;;
        es:no_active) printf 'Ningún servicio Azpro activo.' ;;
        es:special_open) printf 'ABRIR / CONFIGURAR' ;;
        es:special_restart) printf 'REINICIAR PUERTO' ;;
        es:special_close) printf 'CERRAR PUERTO' ;;
        es:choose_action) printf 'Seleccione una opción:' ;;
        es:update_title) printf 'Actualizar Azpro desde GitHub' ;;
        es:update_rebuild) printf 'La actualización recompila los binarios.' ;;
        es:update_restart) printf 'Los servicios pueden reiniciarse.' ;;
        es:update_reload) printf 'El menú se recargará al terminar.' ;;
        es:update_confirm) printf '¿Continuar con la actualización? (s/N):' ;;
        es:uninstall_title) printf 'DESINSTALAR Azpro' ;;
        es:uninstall_desc1) printf 'Detiene servicios y elimina binarios del proxy.' ;;
        es:uninstall_desc2) printf 'Elimina certificados TLS de /opt/mpro.' ;;
        es:uninstall_desc3) printf 'Conserva SSH, Rust, OpenSSL y otros archivos.' ;;
        es:confirm_yes) printf 'Para desinstalar, escriba: s' ;;
        es:confirm_no) printf 'Para cancelar, escriba: n' ;;
        pt-BR:running) printf 'EM EXECUÇÃO' ;;
        pt-BR:active_ports) printf 'Porta(s) ativa(s):' ;;
        pt-BR:multiprotocol) printf 'MULTIPROTOCOLO:' ;;
        pt-BR:active) printf 'ATIVO' ;;
        pt-BR:offline) printf 'OFFLINE' ;;
        pt-BR:open_port) printf 'CONFIGURAR PORTAS' ;;
        pt-BR:close_port) printf 'FECHAR PORTA ABERTA' ;;
        pt-BR:restart_port) printf 'REINICIAR PORTA' ;;
        pt-BR:xhttp) printf 'XHTTP + SSL TUNNEL' ;;
        pt-BR:integrated) printf 'PROTOCOLO INTEGRADO' ;;
        pt-BR:update) printf 'ATUALIZAR PELO GITHUB' ;;
        pt-BR:status) printf 'MULTIPROTOCOLO + STATUS' ;;
        pt-BR:uninstall) printf 'DESINSTALAR AZPRO' ;;
        pt-BR:language) printf 'IDIOMA / LANGUAGE' ;;
        pt-BR:exit) printf 'SAIR' ;;
        pt-BR:choose) printf 'Escolha uma opção:' ;;
        pt-BR:open_title) printf 'Abrir Porta' ;;
        pt-BR:default_ports) printf 'Portas padrão: 80, 8080, 8880, 3128' ;;
        pt-BR:port443_hint) printf 'Porta 443: use opção [04] XHTTP + SSL Tunnel' ;;
        pt-BR:port_prompt) printf 'Porta:' ;;
        pt-BR:https_prompt) printf 'Habilitar o HTTPS/TLS? (s/n):' ;;
        pt-BR:http_status_prompt) printf 'Status HTTP (Padrão: @Azpro):' ;;
        pt-BR:xhttp_title) printf 'xHTTP_SSH / SSL TUNNEL - Porta 443' ;;
        pt-BR:status_name_prompt) printf 'Nome do status HTTP:' ;;
        pt-BR:integrated_title) printf 'CONFIGURAÇÕES ATUAIS' ;;
        pt-BR:port_label) printf 'Porta:' ;;
        pt-BR:subnet_label) printf 'Sub-rede:' ;;
        pt-BR:tun_label) printf 'Interface TUN:' ;;
        pt-BR:protocols_label) printf 'Protocolos:' ;;
        pt-BR:enable_udp_prompt) printf 'Deseja ativar UDP na mesma porta? (s/N)' ;;
        pt-BR:enable_quic_prompt) printf 'Deseja ativar QUIC? (s/N)' ;;
        pt-BR:quic_port_prompt) printf 'Porta para QUIC (Enter para 8001):' ;;
        pt-BR:status_http_prompt) printf 'Nome do status HTTP:' ;;
        pt-BR:back) printf 'VOLTAR' ;;
        pt-BR:select_port) printf 'Selecione a porta:' ;;
        pt-BR:restart_title) printf 'Reiniciar porta aberta' ;;
        pt-BR:close_title) printf 'Fechar porta aberta' ;;
        pt-BR:choose_port_restart) printf 'Escolha a porta para reiniciar:' ;;
        pt-BR:choose_port_close) printf 'Escolha a porta para fechar:' ;;
        pt-BR:no_active) printf 'Nenhum serviço Azpro ativo.' ;;
        pt-BR:special_open) printf 'ABRIR / CONFIGURAR' ;;
        pt-BR:special_restart) printf 'REINICIAR PORTA' ;;
        pt-BR:special_close) printf 'FECHAR PORTA' ;;
        pt-BR:choose_action) printf 'Escolha uma opção:' ;;
        pt-BR:update_title) printf 'Atualizar Azpro pelo GitHub' ;;
        pt-BR:update_rebuild) printf 'A atualização recompila os binários.' ;;
        pt-BR:update_restart) printf 'Os serviços podem reiniciar.' ;;
        pt-BR:update_reload) printf 'O menu será recarregado ao terminar.' ;;
        pt-BR:update_confirm) printf 'Continuar com a atualização? (s/N):' ;;
        pt-BR:uninstall_title) printf 'DESINSTALAR Azpro' ;;
        pt-BR:uninstall_desc1) printf 'Para serviços e remove binários do proxy.' ;;
        pt-BR:uninstall_desc2) printf 'Remove certificados TLS de /opt/mpro.' ;;
        pt-BR:uninstall_desc3) printf 'Preserva SSH, Rust, OpenSSL e demais arquivos.' ;;
        pt-BR:confirm_yes) printf 'Para desinstalar, digite: s' ;;
        pt-BR:confirm_no) printf 'Para cancelar, digite: n' ;;
        *) printf '%s' "$KEY" ;;
    esac
}

is_yes() {
    [[ "$1" =~ ^[sSyY]$ ]]
}

strip_len() {
    local clean
    clean=$(echo -ne "$1" | sed -r 's/\x1B\[[0-9;]*[mK]//g')
    echo -n "${#clean}"
}

box_line() {
    local content="$1"
    local visible_len
    visible_len=$(strip_len "$content")
    local pad=$(( BOX_WIDTH - visible_len ))
    [ $pad -lt 0 ] && pad=0
    echo -ne "${CYAN}║${NC} "
    echo -ne "${content}"
    printf '%*s' "$pad" ''
    echo -e " ${CYAN}║${NC}"
}

box_top() {
    printf "${CYAN}╔"
    printf '═%.0s' $(seq 1 $((BOX_WIDTH + 2)))
    printf "╗${NC}\n"
}

box_mid() {
    printf "${CYAN}╠"
    printf '═%.0s' $(seq 1 $((BOX_WIDTH + 2)))
    printf "╣${NC}\n"
}

box_bottom() {
    printf "${CYAN}╚"
    printf '═%.0s' $(seq 1 $((BOX_WIDTH + 2)))
    printf "╝${NC}\n"
}

show_banner() {
    local TITLE="A Z P R O  P R O T O C O L O  F R E E" PADDING SEPARATOR
    printf -v PADDING '%*s' "$(((BOX_WIDTH + 4 - ${#TITLE}) / 2))" ''
    printf -v SEPARATOR '%*s' "$((BOX_WIDTH + 4))" ''
    SEPARATOR=${SEPARATOR// /-}
    echo -e "${CYAN}${BOLD}${PADDING}${TITLE}${NC}"
    echo -e "${BLUE}${BOLD}${SEPARATOR}${NC}"
}

has_any_multiprotocol_enabled() {
    local FLAG
    for FLAG in "${BYPASS_DIR}"/multiprotocol-*.enabled; do
        [[ -f "$FLAG" ]] && return 0
    done
    return 1
}

has_active_azpro_service() {
    local SERVICE_FILE SERVICE
    for SERVICE_FILE in "${SYSTEMD_DIR}"/proxy-*.service; do
        [[ -f "$SERVICE_FILE" ]] || continue
        grep -Eq '^[[:space:]]*ExecStart=.*/opt/mpro/(proxy|proxy-xhttp|proxy-integrated|proxy-websocket)([[:space:]]|$)' "$SERVICE_FILE" || continue
        SERVICE=$(basename "$SERVICE_FILE")
        systemctl is-active --quiet "$SERVICE" 2>/dev/null && return 0
    done
    systemctl is-active --quiet "$HCR_SERVICE" 2>/dev/null && return 0
    return 1
}

show_execution_status() {
    local LANGUAGE="$(get_language)"
    if has_active_azpro_service; then
        box_line "Status: $(language_text running "$LANGUAGE") • ${LIGHT_GREEN}ONLINE ◉${NC}"
    else
        box_line "Status: $(language_text running "$LANGUAGE") • ${RED}$(language_text offline "$LANGUAGE") ○${NC}"
    fi
}

show_active_ports() {
    local LANGUAGE="$(get_language)"
    ACTIVE=""
    XHTTP_ACTIVE=false
    INTEGRATED_ACTIVE=false
    HCR_ACTIVE=false

    for service_file in ${SYSTEMD_DIR}/proxy-*.service; do
        if [ -f "$service_file" ]; then
            NAME=$(basename "$service_file" .service | sed 's/proxy-//')
            if systemctl is-active --quiet "proxy-${NAME}.service" 2>/dev/null; then
                if [ "$NAME" = "443" ]; then
                    XHTTP_ACTIVE=true
                elif [ "$NAME" = "integrated" ]; then
                    INTEGRATED_ACTIVE=true
                else
                    ACTIVE="$ACTIVE $NAME"
                fi
            fi
        fi
    done
    systemctl is-active --quiet "hcr-8880.service" 2>/dev/null && HCR_ACTIVE=true

    local ports_str=""
    if [ -n "$ACTIVE" ]; then
        ports_str="${AQUA}${ACTIVE# }${NC}"
    fi
    if [ "$XHTTP_ACTIVE" = true ]; then
        ports_str="${ports_str}${ports_str:+ }${AQUA}443${NC}"
    fi
    if [ "$INTEGRATED_ACTIVE" = true ]; then
        ports_str="${ports_str}${ports_str:+ }${AQUA}INTEGRADO${NC}"
    fi
    if [ "$HCR_ACTIVE" = true ]; then
        ports_str="${ports_str}${ports_str:+ }${AQUA}HCR:8880${NC}"
    fi
    if [ -z "$ports_str" ]; then
        ports_str="${RED}$( [[ "$LANGUAGE" == "en" ]] && echo none || [[ "$LANGUAGE" == "es" ]] && echo ninguno || echo nenhuma )${NC}"
    fi

    box_line "${LIGHT_GREEN}$(language_text active_ports "$LANGUAGE")${NC} ${ports_str}"
    if has_any_multiprotocol_enabled; then
        box_line "${CYAN}$(language_text multiprotocol "$LANGUAGE")${NC} ${LIGHT_GREEN}$(language_text active "$LANGUAGE")${NC}"
    else
        box_line "${CYAN}$(language_text multiprotocol "$LANGUAGE")${NC} ${RED}$(language_text offline "$LANGUAGE")${NC}"
    fi
}

create_service() {
    local PORT=$1
    local STATUS=$2
    local SSH_ONLY=$3
    local HTTPS=$4
    local SERVICE_FILE="${SYSTEMD_DIR}/proxy-${PORT}.service"
    EXTRA_ARGS="-p ${PORT}"
    [[ -n "$STATUS" ]] && EXTRA_ARGS="${EXTRA_ARGS} -s ${STATUS}"
    [[ "$SSH_ONLY" == "s" ]] && EXTRA_ARGS="${EXTRA_ARGS} -ssh"
    if [[ "$HTTPS" == "s" ]]; then
        EXTRA_ARGS="${EXTRA_ARGS} -t"
    else
        EXTRA_ARGS="${EXTRA_ARGS} --no-tls"
    fi
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Mpro - Porta ${PORT}
After=network.target
[Service]
Type=simple
ExecStart=${LKPROXY} ${EXTRA_ARGS}
Restart=on-failure
RestartSec=5
User=root
WorkingDirectory=/opt/mpro
[Install]
WantedBy=multi-user.target
EOF
}

create_xhttp_service() {
    local PORT=$1
    local STATUS=$2
    local SSH_PORT=$3
    local SERVICE_FILE="${SYSTEMD_DIR}/proxy-${PORT}.service"
    EXTRA_ARGS="-p ${PORT} -s ${STATUS} --ssh-port ${SSH_PORT}"
    cat > "$SERVICE_FILE" << EOF
[Unit]
Description=Mpro xHTTP + SSL Tunnel - Porta ${PORT}
After=network.target
[Service]
Type=simple
ExecStart=${LKPROXY_XHTTP} ${EXTRA_ARGS}
Restart=on-failure
RestartSec=5
User=root
WorkingDirectory=/opt/mpro
[Install]
WantedBy=multi-user.target
EOF
}

open_port() {
    local LANGUAGE="$(get_language)"
    clear
    show_banner
    echo ""
    box_top
    box_line "${WHITE}${BOLD}$(language_text open_title "$LANGUAGE")${NC}"
    box_mid
    box_line "${WHITE}$(language_text default_ports "$LANGUAGE")${NC}"
    box_line "${YELLOW}$(language_text port443_hint "$LANGUAGE")${NC}"
    box_bottom
    echo ""
    read -p "$(language_text port_prompt "$LANGUAGE") " PORT
    [[ -z "$PORT" ]] && return
    if systemctl is-active --quiet "proxy-${PORT}.service" 2>/dev/null; then
        echo -e "${RED}Porta ${PORT} já está em uso!${NC}"; sleep 2; return
    fi
    read -r -p "$(language_text https_prompt "$LANGUAGE") " HTTPS
    HTTPS=${HTTPS,,}
    [[ "$HTTPS" == "y" ]] && HTTPS="s"
    [[ -z "$HTTPS" ]] && HTTPS="n"
    if [[ "$HTTPS" != "s" && "$HTTPS" != "n" ]]; then
        echo -e "${RED}Resposta inválida. Use s ou n.${NC}"
        read -r -p "Enter pra continuar..."
        return
    fi
    read -r -p "$(language_text http_status_prompt "$LANGUAGE") " STATUS
    [[ -z "$STATUS" ]] && STATUS="@Azpro"
    read -p "Habilitar somente SSH? (s/n): " SSH_ONLY
    SSH_ONLY=${SSH_ONLY,,}
    [[ "$SSH_ONLY" == "y" ]] && SSH_ONLY="s"
    mkdir -p /opt/mpro
    create_service "$PORT" "$STATUS" "$SSH_ONLY" "$HTTPS"
    systemctl daemon-reload
    systemctl enable "proxy-${PORT}.service" 2>/dev/null
    systemctl start "proxy-${PORT}.service" 2>/dev/null
    sleep 2
    read -p "Enter pra continuar..."
}

hcr_binary_path() {
    local candidate
    for candidate in "${HCR_BINARY_CANDIDATES[@]}"; do
        if [[ -x "$candidate" ]]; then
            printf '%s' "$candidate"
            return 0
        fi
    done
    return 1
}

hcr_arch_ok() {
    case "$(uname -m 2>/dev/null)" in
        x86_64|amd64) return 0 ;;
        *) return 1 ;;
    esac
}

hcr_binary_version() {
    local OUTPUT=""
    OUTPUT=$(timeout 5 "$1" -version 2>&1 </dev/null) || true
    OUTPUT=${OUTPUT%%$'\n'*}
    printf '%s' "${OUTPUT:-desconhecida}"
}

hcr_install_binary() {
    local DEST="${BYPASS_DIR}/hcr-server" TMP="" MAGIC="" SOURCE="${HCR_SOURCE_URL}"

    if ! hcr_arch_ok; then
        echo -e "${RED}O hcr-server oficial só é publicado para Linux amd64. Arquitetura atual: $(uname -m).${NC}" >&2
        echo "Instale o binário manualmente em ${DEST} ou /usr/local/bin/hcr-server." >&2
        return 1
    fi
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}curl não está instalado; não é possível baixar o hcr-server.${NC}" >&2
        return 1
    fi
    if ! mkdir -p "$BYPASS_DIR"; then
        echo -e "${RED}Não foi possível criar ${BYPASS_DIR}.${NC}" >&2
        return 1
    fi
    TMP=$(mktemp /tmp/azpro-hcr.XXXXXX) || {
        echo -e "${RED}Não foi possível criar arquivo temporário.${NC}" >&2
        return 1
    }

    echo "Baixando hcr-server de ${SOURCE}" >&2
    if ! curl -fsSL --connect-timeout 15 --max-time 180 --retry 3 "$SOURCE" -o "$TMP"; then
        rm -f -- "$TMP"
        echo -e "${RED}Falha ao baixar o hcr-server.${NC}" >&2
        return 1
    fi

    # Valida ELF64 x86-64 (e_ident + e_machine = 0x3e) sem depender do pacote `file`.
    MAGIC=$(head -c 20 "$TMP" 2>/dev/null | od -An -tx1 | tr -d ' \n')
    if [[ "$MAGIC" != 7f454c46* || "${MAGIC:36:4}" != "3e00" ]]; then
        rm -f -- "$TMP"
        echo -e "${RED}O arquivo baixado não é um binário ELF Linux amd64 válido.${NC}" >&2
        return 1
    fi

    if ! chmod 755 "$TMP"; then
        rm -f -- "$TMP"
        echo -e "${RED}Não foi possível preparar o binário baixado.${NC}" >&2
        return 1
    fi
    if [[ -f "$DEST" ]]; then
        cp -a -- "$DEST" "${DEST}.bak.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
    fi
    if ! install -m 755 "$TMP" "$DEST"; then
        rm -f -- "$TMP"
        echo -e "${RED}Falha ao instalar ${DEST}.${NC}" >&2
        return 1
    fi
    rm -f -- "$TMP"
    echo -e "${GREEN}hcr-server instalado em ${DEST}${NC}" >&2
    echo "Versão: $(hcr_binary_version "$DEST")" >&2
    return 0
}

hcr_ensure_binary() {
    local BINARY="" ANSWER=""

    if BINARY=$(hcr_binary_path); then
        printf '%s' "$BINARY"
        return 0
    fi
    echo -e "${YELLOW}Servidor HCR oficial não instalado.${NC}" >&2
    if ! hcr_arch_ok; then
        echo "O binário oficial só existe para Linux amd64; instale manualmente em ${BYPASS_DIR}/hcr-server." >&2
        return 1
    fi
    read -r -p "Baixar e instalar o hcr-server oficial agora? (s/n): " ANSWER
    if ! is_yes "$ANSWER"; then
        echo "Coloque o binário oficial hcr-server em ${BYPASS_DIR}/hcr-server ou /usr/local/bin/hcr-server." >&2
        return 1
    fi
    hcr_install_binary || return 1
    hcr_binary_path
}

# Descobre o formato de argumentos aceito pelo binário instalado.
hcr_exec_args() {
    local PORT="$1" BINARY="$2" HELP=""

    HELP=$(timeout 5 "$BINARY" -h 2>&1 </dev/null) || true
    if grep -q -- "-listen" <<<"$HELP"; then
        printf '%s' "-listen :${PORT} -target ${HCR_SSH_TARGET} -transport plain"
    else
        printf '%s' "--port ${PORT} --transport plain"
    fi
}

hcr_alternate_args() {
    local ARGS="$1" PORT="$2"

    if [[ "$ARGS" == -listen* ]]; then
        printf '%s' "--port ${PORT} --transport plain"
    else
        printf '%s' "-listen :${PORT} -target ${HCR_SSH_TARGET} -transport plain"
    fi
}

hcr_port_busy() {
    ss -lntH 2>/dev/null | awk '{print $4}' | grep -Eq "[:.]$1$"
}

hcr_restore_kernel_defaults() {
    local SYSCTL_FILE="/etc/sysctl.d/99-azpro-hcr.conf"

    [[ "$EUID" -eq 0 ]] || return 0
    rm -f -- "$SYSCTL_FILE"
    command -v sysctl >/dev/null 2>&1 || return 0
    # Evita que o tuning agressivo anterior continue ativo após a atualização.
    sysctl -w net.ipv4.tcp_mtu_probing=0 >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_time=7200 >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_intvl=75 >/dev/null 2>&1 || true
    sysctl -w net.ipv4.tcp_keepalive_probes=9 >/dev/null 2>&1 || true
    if sysctl -n net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -qw cubic; then
        sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1 || true
    fi
}

hcr_apply_ssh_keepalive() {
    local SSHD_CONFIG="/etc/ssh/sshd_config"
    local SSHD_DROPIN_DIR="/etc/ssh/sshd_config.d"
    local SSHD_DROPIN="${SSHD_DROPIN_DIR}/50-azpro-hcr-keepalive.conf"
    local SSHD_BIN SSH_UNIT="" HAD_DROPIN=0

    SSHD_BIN=$(command -v sshd) || {
        echo -e "${RED}sshd não encontrado; não foi possível ativar o keepalive SSH do HCR.${NC}" >&2
        return 1
    }
    if ! grep -Eq '^[[:space:]]*Include[[:space:]].*/etc/ssh/sshd_config\.d/\*' "$SSHD_CONFIG"; then
        echo -e "${RED}A configuração do sshd não inclui ${SSHD_DROPIN_DIR}; keepalive do HCR não aplicado.${NC}" >&2
        return 1
    fi

    mkdir -p "$SSHD_DROPIN_DIR" || return 1
    local BACKUP
    BACKUP=$(mktemp) || return 1
    if [[ -f "$SSHD_DROPIN" ]]; then
        HAD_DROPIN=1
        cp -a "$SSHD_DROPIN" "$BACKUP" || { rm -f "$BACKUP"; return 1; }
    else
        : > "$BACKUP"
    fi
    cat > "$SSHD_DROPIN" <<'EOF'
# Keep SSH application traffic flowing through HCR's 120-second idle window.
ClientAliveInterval 30
ClientAliveCountMax 6
EOF
    if ! "$SSHD_BIN" -t; then
        if (( HAD_DROPIN )); then cp -a "$BACKUP" "$SSHD_DROPIN"; else rm -f "$SSHD_DROPIN"; fi
        rm -f "$BACKUP"
        echo -e "${RED}Configuração inválida do sshd; keepalive HCR não aplicado.${NC}" >&2
        return 1
    fi
    if ! "$SSHD_BIN" -T 2>/dev/null | grep -qx 'clientaliveinterval 30' ||
        ! "$SSHD_BIN" -T 2>/dev/null | grep -qx 'clientalivecountmax 6'; then
        if (( HAD_DROPIN )); then cp -a "$BACKUP" "$SSHD_DROPIN"; else rm -f "$SSHD_DROPIN"; fi
        rm -f "$BACKUP"
        echo -e "${RED}O sshd não aplicou os valores de keepalive solicitados; configuração restaurada.${NC}" >&2
        return 1
    fi

    if systemctl is-active --quiet ssh.service 2>/dev/null; then
        SSH_UNIT="ssh.service"
    elif systemctl is-active --quiet sshd.service 2>/dev/null; then
        SSH_UNIT="sshd.service"
    fi
    if [[ -z "$SSH_UNIT" ]] || ! systemctl reload "$SSH_UNIT" >/dev/null 2>&1; then
        if (( HAD_DROPIN )); then cp -a "$BACKUP" "$SSHD_DROPIN"; else rm -f "$SSHD_DROPIN"; fi
        rm -f "$BACKUP"
        echo -e "${RED}Não foi possível recarregar o sshd; keepalive HCR não aplicado.${NC}" >&2
        return 1
    fi
    rm -f "$BACKUP"
    return 0
}

hcr_apply_session_config() {
    local DROPIN_DIR="/etc/systemd/system/${HCR_SERVICE}.d"
    local DROPIN_FILE="${DROPIN_DIR}/20-azpro-persistence.conf"

    [[ "$EUID" -eq 0 ]] || return 0
    mkdir -p "$DROPIN_DIR" || return 1
    cat > "$DROPIN_FILE" <<'EOF'
[Service]
# Requests a long idle timeout when supported by the installed HCR build.
Environment=HCR_SESSION_IDLE_TIMEOUT_SECONDS=86400
Environment=HCR_SESSION_IDLE_TIMEOUT=86400
Environment=HCR_IDLE_TIMEOUT_SECONDS=86400
Environment=HCR_KEEPALIVE_INTERVAL_SECONDS=20
EOF
    systemctl daemon-reload >/dev/null 2>&1 || return 1
    hcr_apply_ssh_keepalive || return 1
}

hcr_wait_listening() {
    local PORT="$1" TENTATIVAS="${2:-10}" I
    for ((I = 0; I < TENTATIVAS; I++)); do
        hcr_port_busy "$PORT" && return 0
        sleep 0.5
    done
    return 1
}

hcr_write_unit() {
    local BINARY="$1" ARGS="$2" SERVICE_FILE="${SYSTEMD_DIR}/${HCR_SERVICE}"

    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=HCR Server - Porta ${HCR_PORT} (plain)
After=network.target
Conflicts=proxy-${HCR_PORT}.service
StartLimitIntervalSec=0

[Service]
Type=simple
ExecStart=${BINARY} ${ARGS}
Restart=always
RestartSec=2
TimeoutStopSec=10
User=root
WorkingDirectory=${BYPASS_DIR}

[Install]
WantedBy=multi-user.target
EOF
}

# A instalação oficial do hcr-server pode ter sido criada por outra versão do
# instalador. O drop-in atualiza apenas a política de recuperação, sem
# substituir a unit existente nem mexer nos argumentos escolhidos pelo usuário.
hcr_install_restart_policy() {
    local DROPIN_DIR="${SYSTEMD_DIR}/${HCR_SERVICE}.d"
    local DROPIN_FILE="${DROPIN_DIR}/restart.conf"

    mkdir -p "$DROPIN_DIR" || return 1
    cat > "$DROPIN_FILE" <<'EOF'
[Unit]
StartLimitIntervalSec=0

[Service]
Restart=always
RestartSec=2
TimeoutStopSec=10
EOF
    systemctl daemon-reload >/dev/null 2>&1 || return 1
}

hcr_manage_binary() {
    local BINARY="" ANSWER=""

    clear
    show_banner
    echo ""
    box_top
    box_line "${WHITE}${BOLD}HCR SERVIDOR${NC}"
    box_mid
    if BINARY=$(hcr_binary_path); then
        box_line "Binário: ${BINARY}"
    else
        box_line "${YELLOW}Binário não instalado${NC}"
    fi
    box_bottom
    echo ""
    if [[ -n "$BINARY" ]]; then
        echo "Versão: $(hcr_binary_version "$BINARY")"
        echo "Fonte: ${HCR_SOURCE_URL}"
        echo ""
    fi
    read -r -p "Baixar/atualizar o hcr-server oficial agora? (s/n): " ANSWER
    if ! is_yes "$ANSWER"; then
        return 0
    fi
    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Execute o menu como root para instalar o servidor HCR.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi
    if ! hcr_install_binary; then
        read -r -p "Enter para continuar..." _
        return 1
    fi
    if systemctl is-active --quiet "$HCR_SERVICE" 2>/dev/null; then
        if systemctl restart "$HCR_SERVICE" >/dev/null 2>&1 && hcr_wait_listening "$HCR_PORT"; then
            echo -e "${GREEN}${HCR_SERVICE} reiniciado com o novo binário.${NC}"
        else
            echo -e "${RED}Falha ao reiniciar ${HCR_SERVICE}; confira: journalctl -u ${HCR_SERVICE} -n 50${NC}"
        fi
    fi
    read -r -p "Enter para continuar..." _
}

hcr_open_port() {
    local PORT="${HCR_PORT}" SERVICE="${HCR_SERVICE}" SERVICE_FILE="${SYSTEMD_DIR}/${HCR_SERVICE}"
    local BINARY="" ARGS="" ALT_ARGS="" ANSWER="" ATTEMPT=""

    clear
    show_banner
    echo ""
    box_top
    box_line "${WHITE}${BOLD}HCR ABRIR PORTA${NC}"
    box_mid
    box_line "Transporte: plain (sem TLS)"
    box_line "Porta padrão: ${PORT}"
    box_line "Destino SSH: ${HCR_SSH_TARGET}"
    box_bottom
    echo ""

    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Execute o menu como root para iniciar o servidor HCR.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi
    if ! command -v systemctl >/dev/null 2>&1; then
        echo -e "${RED}systemctl não encontrado; não foi possível iniciar o HCR.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi
    hcr_restore_kernel_defaults
    if [[ -e "$SERVICE_FILE" ]]; then
        if ! hcr_install_restart_policy; then
            echo -e "${YELLOW}Não foi possível atualizar a política de recuperação da unit existente.${NC}"
        fi
    fi
    hcr_apply_session_config || {
        echo -e "${RED}Não foi possível aplicar a configuração persistente do HCR.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    }
    if ! BINARY=$(hcr_ensure_binary); then
        read -r -p "Enter para continuar..." _
        return 1
    fi
    echo "Binário: ${BINARY}"

    if systemctl is-active --quiet "$SERVICE" 2>/dev/null; then
        echo -e "${YELLOW}Aplicando configuração persistente do HCR e reiniciando uma vez...${NC}"
        if systemctl restart "$SERVICE" >/dev/null 2>&1 && hcr_wait_listening "$PORT"; then
            echo -e "${GREEN}HCR ativo com configuração persistente na porta ${PORT}.${NC}"
        else
            echo -e "${RED}O HCR não voltou a escutar a porta ${PORT}.${NC}"
        fi
        read -r -p "Enter para continuar..." _
        return 0
    fi

    if [[ -e "$SERVICE_FILE" ]]; then
        read -r -p "${SERVICE_FILE} já existe e está parado. Iniciar o serviço existente? (s/n): " ANSWER
        if is_yes "$ANSWER"; then
            hcr_apply_session_config || true
            if systemctl start "$SERVICE" >/dev/null 2>&1 && hcr_wait_listening "$PORT"; then
                echo -e "${GREEN}HCR iniciado na porta ${PORT} usando a unit existente.${NC}"
            else
                echo -e "${RED}Não foi possível iniciar ${SERVICE}.${NC}"
                journalctl -u "$SERVICE" -n 20 --no-pager 2>/dev/null
            fi
        else
            echo -e "${YELLOW}Unit mantida sem alterações.${NC}"
        fi
        read -r -p "Enter para continuar..." _
        return 0
    fi

    if systemctl is-active --quiet "proxy-${PORT}.service" 2>/dev/null || hcr_port_busy "$PORT"; then
        echo -e "${RED}A porta ${PORT} já está em uso.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi

    ARGS=$(hcr_exec_args "$PORT" "$BINARY")
    ALT_ARGS=$(hcr_alternate_args "$ARGS" "$PORT")

    for ATTEMPT in "$ARGS" "$ALT_ARGS"; do
        [[ -n "$ATTEMPT" ]] || continue
        if ! hcr_write_unit "$BINARY" "$ATTEMPT"; then
            echo -e "${RED}Não foi possível escrever ${SERVICE_FILE}.${NC}"
            read -r -p "Enter para continuar..." _
            return 1
        fi
        if ! systemctl daemon-reload; then
            rm -f -- "$SERVICE_FILE"
            echo -e "${RED}Falha ao recarregar systemd; serviço HCR não iniciado.${NC}"
            read -r -p "Enter para continuar..." _
            return 1
        fi
        systemctl enable "$SERVICE" >/dev/null 2>&1 || true
        systemctl restart "$SERVICE" >/dev/null 2>&1 || true
        if systemctl is-active --quiet "$SERVICE" 2>/dev/null && hcr_wait_listening "$PORT"; then
            echo -e "${GREEN}HCR iniciado na porta ${PORT} com transporte plain (sem TLS).${NC}"
            echo "Comando: ${BINARY} ${ATTEMPT}"
            echo "Serviço: systemctl status ${SERVICE}"
            read -r -p "Enter para continuar..." _
            return 0
        fi
        echo -e "${YELLOW}Os argumentos \"${ATTEMPT}\" não subiram a porta ${PORT}; tentando o formato alternativo...${NC}"
        systemctl stop "$SERVICE" >/dev/null 2>&1 || true
    done

    echo -e "${RED}Falha ao iniciar ${SERVICE}.${NC}"
    journalctl -u "$SERVICE" -n 20 --no-pager 2>/dev/null
    systemctl disable --now "$SERVICE" >/dev/null 2>&1 || true
    rm -f -- "$SERVICE_FILE"
    systemctl daemon-reload >/dev/null 2>&1 || true
    read -r -p "Enter para continuar..." _
    return 1
}

configure_ports() {
    local ACTION LANGUAGE
    while true; do
        clear
        LANGUAGE="$(get_language)"
        show_banner
        echo ""
        box_top
        box_line "${WHITE}${BOLD}$(language_text open_port "$LANGUAGE")${NC}"
        box_mid
        box_line "${WHITE}[01]${NC} - ABRIR PORTA"
        box_line "${WHITE}[02]${NC} - HCR ABRIR PORTA (8880 / PLAIN)"
        box_line "${WHITE}[03]${NC} - HCR INSTALAR / ATUALIZAR SERVIDOR"
        box_mid
        box_line "${WHITE}[00]${NC} - $(language_text back "$LANGUAGE")"
        box_bottom
        echo ""
        read -r -p "$(language_text choose "$LANGUAGE") " ACTION
        case "$ACTION" in
            01|1) open_port ;;
            02|2) hcr_open_port ;;
            03|3) hcr_manage_binary ;;
            00|0|"") return ;;
            *) ;;
        esac
    done
}

open_xhttp() {
    local LANGUAGE="$(get_language)"
    clear
    show_banner
    echo ""
    box_top
    box_line "${WHITE}${BOLD}$(language_text xhttp_title "$LANGUAGE")${NC}"
    box_bottom
    echo ""
    read -r -p "$(language_text status_name_prompt "$LANGUAGE") " STATUS
    [[ -z "$STATUS" ]] && STATUS="@Azpro"
    read -p "Porta SSH backend (Padrão: 22): " SSH_PORT
    [[ -z "$SSH_PORT" ]] && SSH_PORT="22"
    mkdir -p /opt/mpro
    # Um serviço já ativo não recebe os novos argumentos com `systemctl start`.
    # Pare-o antes de sobrescrever a unit para garantir que o status novo seja aplicado.
    if systemctl is-active --quiet "proxy-443.service" 2>/dev/null; then
        systemctl stop "proxy-443.service" || {
            echo -e "${RED}Não foi possível parar proxy-443.service; configuração não alterada.${NC}"
            read -r -p "Enter para continuar..." _
            return 1
        }
    fi
    if [ ! -f "/opt/mpro/cert.pem" ]; then
        openssl req -x509 -newkey rsa:2048 -keyout /opt/mpro/key.pem -out /opt/mpro/cert.pem -days 365 -nodes -subj "/CN=mpro" 2>/dev/null
    fi
    create_xhttp_service "443" "$STATUS" "$SSH_PORT"
    systemctl daemon-reload
    systemctl enable "proxy-443.service" 2>/dev/null
    if ! systemctl start "proxy-443.service" 2>/dev/null; then
        echo -e "${RED}Não foi possível iniciar proxy-443.service com o novo status.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi
    echo -e "${GREEN}Status HTTP aplicado: 200 ${STATUS}${NC}"
    sleep 2
    read -p "Enter pra continuar..."
}

open_integrated() {
    local LANGUAGE="$(get_language)"
    clear
    echo -e "${CYAN}+--------------------------------------------------------+${NC}"
    echo -e "${CYAN}+--------------------------------------------------------+${NC}"
    echo -e "${WHITE}|  $(language_text integrated_title "$LANGUAGE")                       |${NC}"
    echo -e "${CYAN}+--------------------------------------------------------+${NC}"
    echo -e "${WHITE}|  $(language_text port_label "$LANGUAGE") 8000                                      |${NC}"
    echo -e "${WHITE}|  $(language_text subnet_label "$LANGUAGE") 10.10.0.0/16                         |${NC}"
    echo -e "${WHITE}|  $(language_text tun_label "$LANGUAGE") tun0                                    |${NC}"
    echo -e "${WHITE}|  $(language_text protocols_label "$LANGUAGE") tcp:8000,udp:8000,quic:8001  |${NC}"
    echo -e "${CYAN}+--------------------------------------------------------+${NC}"
    read -p "$(language_text port_label "$LANGUAGE") (Enter para manter [8000]): " PORT
    [[ -z "$PORT" ]] && PORT="8000"
    read -p "$(language_text subnet_label "$LANGUAGE") CIDR (Enter para manter [10.10.0.0/16]): " SUBNET
    [[ -z "$SUBNET" ]] && SUBNET="10.10.0.0/16"
    read -p "$(language_text tun_label "$LANGUAGE") (Enter para manter [tun0]): " TUN
    [[ -z "$TUN" ]] && TUN="tun0"
    read -p "$(language_text enable_udp_prompt "$LANGUAGE") " ENABLE_UDP
    UDP_ARG=""
    is_yes "$ENABLE_UDP" && UDP_ARG="--udp"
    read -p "$(language_text enable_quic_prompt "$LANGUAGE") " ENABLE_QUIC
    QUIC_ARG=""
    if is_yes "$ENABLE_QUIC"; then
        read -p "$(language_text quic_port_prompt "$LANGUAGE") " QPORT
        [[ -z "$QPORT" ]] && QPORT="8001"
        QUIC_ARG="--quic --quic-port $QPORT"
    fi
    read -r -p "$(language_text status_http_prompt "$LANGUAGE") " STATUS
    [[ -z "$STATUS" ]] && STATUS="@Azpro"
    mkdir -p /opt/mpro
    if [ ! -f "/opt/mpro/cert.pem" ]; then
        openssl req -x509 -newkey rsa:2048 -keyout /opt/mpro/key.pem -out /opt/mpro/cert.pem -days 365 -nodes -subj "/CN=mpro" 2>/dev/null
    fi
    cat > "${SYSTEMD_DIR}/proxy-integrated.service" << EOF
[Unit]
Description=Mpro Integrated
After=network.target
[Service]
Type=simple
ExecStart=${LKPROXY_INTEGRATED} -p ${PORT} -s ${STATUS} --tun ${TUN} --subnet ${SUBNET} ${UDP_ARG} ${QUIC_ARG}
Restart=on-failure
RestartSec=5
User=root
WorkingDirectory=/opt/mpro
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable proxy-integrated.service 2>/dev/null
    systemctl start proxy-integrated.service 2>/dev/null
    sleep 2
    echo "Servidor protocolo iniciado com sucesso!"
    read -p "Pressione Enter para continuar..."
}

multiprotocol_flag_for_port() {
    printf '%s/multiprotocol-%s.enabled' "$BYPASS_DIR" "$1"
}

hcr_flag_for_port() {
    printf '%s/hcr-%s.enabled' "$BYPASS_DIR" "$1"
}

is_managed_numeric_port_service() {
    local SERVICE_FILE="$1"
    local SERVICE_NAME PORT
    SERVICE_NAME=$(basename "$SERVICE_FILE")
    PORT=${SERVICE_NAME#proxy-}
    PORT=${PORT%.service}
    [[ "$PORT" =~ ^[0-9]+$ ]] || return 1
    grep -Fq "ExecStart=${LKPROXY} " "$SERVICE_FILE"
}

toggle_port_multiprotocol() {
    local PORT="$1" SERVICE="proxy-${1}.service" FLAG CONFIRM="" PREVIOUS=false
    FLAG=$(multiprotocol_flag_for_port "$PORT")
    systemctl is-active --quiet "$SERVICE" 2>/dev/null || {
        echo -e "${RED}A porta ${PORT} não está mais ativa.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    }

    read -r -p "A porta ${PORT} será reiniciada e as conexões cairão. Continuar? (s/N): " CONFIRM
    is_yes "$CONFIRM" || return 0

    if ! mkdir -p "$BYPASS_DIR"; then
        echo -e "${RED}Não foi possível acessar ${BYPASS_DIR}.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi

    if [[ -f "$FLAG" ]]; then
        PREVIOUS=true
        rm -f -- "$FLAG" || return 1
    else
        touch "$FLAG" || {
            echo -e "${RED}Não foi possível ativar o multiprotocolo na porta ${PORT}.${NC}"
            read -r -p "Enter para continuar..." _
            return 1
        }
    fi

    if systemctl restart "$SERVICE" 2>/dev/null; then
        if [[ "$PREVIOUS" == true ]]; then
            echo -e "${YELLOW}Multiprotocolo desativado na porta ${PORT}.${NC}"
        else
            echo -e "${GREEN}Multiprotocolo ativado na porta ${PORT}; status HTTP configurado preservado.${NC}"
        fi
    else
        if [[ "$PREVIOUS" == true ]]; then
            touch "$FLAG"
        else
            rm -f -- "$FLAG"
        fi
        systemctl restart "$SERVICE" >/dev/null 2>&1 || true
        echo -e "${RED}Falha ao reiniciar ${SERVICE}; configuração anterior restaurada.${NC}"
    fi
    read -r -p "Enter para continuar..." _
}

toggle_port_hcr() {
    local PORT="$1" SERVICE="proxy-${1}.service" FLAG PREVIOUS_HCR=false CONFIRM=""
    FLAG=$(hcr_flag_for_port "$PORT")
    systemctl is-active --quiet "$SERVICE" 2>/dev/null || {
        echo -e "${RED}A porta ${PORT} não está mais ativa.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    }

    read -r -p "Ativar/desativar HCR na porta ${PORT}? O serviço será reiniciado e as conexões atuais cairão. (s/N): " CONFIRM
    is_yes "$CONFIRM" || return 0
    mkdir -p "$BYPASS_DIR" || return 1

    [[ -f "$FLAG" ]] && PREVIOUS_HCR=true
    if [[ "$PREVIOUS_HCR" == true ]]; then
        rm -f -- "$FLAG" || return 1
    else
        if ! systemctl is-active --quiet "$HCR_SERVICE" 2>/dev/null; then
            echo -e "${RED}O servidor HCR oficial (${HCR_SERVICE}, porta ${HCR_PORT}) precisa estar ativo.${NC}"
            read -r -p "Enter para continuar..." _
            return 1
        fi
        if ! touch "$FLAG"; then
            echo -e "${RED}Não foi possível gravar a configuração HCR da porta ${PORT}.${NC}"
            return 1
        fi
    fi

    if systemctl restart "$SERVICE" 2>/dev/null; then
        if [[ "$PREVIOUS_HCR" == true ]]; then
            echo -e "${YELLOW}HCR desativado na porta ${PORT}.${NC}"
        else
            echo -e "${GREEN}Suporte HCR marcado ON na porta ${PORT}; o estado do multiprotocolo foi preservado.${NC}"
        fi
    else
        if [[ "$PREVIOUS_HCR" == true ]]; then
            touch "$FLAG"
        else
            rm -f -- "$FLAG"
        fi
        systemctl restart "$SERVICE" >/dev/null 2>&1 || true
        echo -e "${RED}Falha ao reiniciar ${SERVICE}; configuração anterior restaurada.${NC}"
    fi
    read -r -p "Enter para continuar..." _
}

manage_hcr_support() {
    local ACTION SERVICE_FILE SERVICE_NAME PORT FLAG INDEX
    local -a ACTIVE_PORTS=()
    while true; do
        ACTIVE_PORTS=()
        for SERVICE_FILE in "${SYSTEMD_DIR}"/proxy-*.service; do
            [[ -f "$SERVICE_FILE" ]] || continue
            is_managed_numeric_port_service "$SERVICE_FILE" || continue
            SERVICE_NAME=$(basename "$SERVICE_FILE")
            systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null || continue
            PORT=${SERVICE_NAME#proxy-}
            PORT=${PORT%.service}
            ACTIVE_PORTS+=("$PORT")
        done
        if ((${#ACTIVE_PORTS[@]} > 0)); then
            mapfile -t ACTIVE_PORTS < <(printf '%s\n' "${ACTIVE_PORTS[@]}" | sort -n)
        fi

        clear
        show_banner
        echo ""
        box_top
        box_line "${WHITE}${BOLD}SUPORTE MULTIPROTOCOLO HCR${NC}"
        box_mid
        box_line "HCR só funciona com multiprotocolo ON na mesma porta."
        box_line "Esta opção não altera o estado do multiprotocolo."
        if ((${#ACTIVE_PORTS[@]} == 0)); then
            box_line "${YELLOW}Nenhuma porta Azpro ativa.${NC}"
        else
            for ((INDEX=0; INDEX<${#ACTIVE_PORTS[@]}; INDEX++)); do
                PORT=${ACTIVE_PORTS[$INDEX]}
                FLAG=$(hcr_flag_for_port "$PORT")
                printf -v ACTION '%02d' "$((INDEX + 1))"
                if [[ -f "$FLAG" ]]; then
                    box_line "${WHITE}[${ACTION}]${NC} ${PORT} - ATIVAR HCR: ${GREEN}ON${NC}"
                else
                    box_line "${WHITE}[${ACTION}]${NC} ${PORT} - ATIVAR HCR: ${YELLOW}OFF${NC}"
                fi
            done
        fi
        box_mid
        box_line "${WHITE}[00]${NC} - VOLTAR"
        box_bottom
        echo ""
        read -r -p "Escolha a porta para alternar HCR (00 para voltar): " ACTION
        [[ "$ACTION" == "00" || "$ACTION" == "0" || -z "$ACTION" ]] && return
        if [[ "$ACTION" =~ ^[0-9]+$ ]] && ((10#$ACTION >= 1 && 10#$ACTION <= ${#ACTIVE_PORTS[@]})); then
            PORT=${ACTIVE_PORTS[$((10#$ACTION - 1))]}
            toggle_port_hcr "$PORT"
        fi
    done
}

manage_multiprotocol() {
    local ACTION SERVICE_FILE SERVICE_NAME PORT FLAG INDEX LANGUAGE
    local -a ACTIVE_PORTS=()
    while true; do
        ACTIVE_PORTS=()
        for SERVICE_FILE in "${SYSTEMD_DIR}"/proxy-*.service; do
            [[ -f "$SERVICE_FILE" ]] || continue
            is_managed_numeric_port_service "$SERVICE_FILE" || continue
            SERVICE_NAME=$(basename "$SERVICE_FILE")
            systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null || continue
            PORT=${SERVICE_NAME#proxy-}
            PORT=${PORT%.service}
            ACTIVE_PORTS+=("$PORT")
        done
        if ((${#ACTIVE_PORTS[@]} > 0)); then
            mapfile -t ACTIVE_PORTS < <(printf '%s\n' "${ACTIVE_PORTS[@]}" | sort -n)
        fi

        clear
        LANGUAGE="$(get_language)"
        show_banner
        echo ""
        box_top
        box_line "${WHITE}${BOLD}$(language_text status "$LANGUAGE")${NC}"
        box_mid
        if ((${#ACTIVE_PORTS[@]} == 0)); then
            box_line "${YELLOW}$(language_text no_active "$LANGUAGE")${NC}"
        else
            for ((INDEX=0; INDEX<${#ACTIVE_PORTS[@]}; INDEX++)); do
                PORT=${ACTIVE_PORTS[$INDEX]}
                FLAG=$(multiprotocol_flag_for_port "$PORT")
                printf -v ACTION '%02d' "$((INDEX + 1))"
                if [[ -f "$FLAG" ]]; then
                    box_line "${WHITE}[${ACTION}]${NC} ${PORT} - $(language_text multiprotocol "$LANGUAGE") ${GREEN}$(language_text active "$LANGUAGE")${NC}"
                else
                    box_line "${WHITE}[${ACTION}]${NC} ${PORT} - $(language_text multiprotocol "$LANGUAGE") ${YELLOW}OFF${NC}"
                fi
            done
        fi
        box_mid
        box_line "${WHITE}[H]${NC} - ATIVAR SUPORTE AO HCR"
        box_line "${WHITE}[00]${NC} - $(language_text back "$LANGUAGE")"
        box_bottom
        echo ""
        read -r -p "$(language_text select_port "$LANGUAGE") " ACTION
        [[ "$ACTION" == "00" || "$ACTION" == "0" || -z "$ACTION" ]] && return

        if [[ "$ACTION" == "h" || "$ACTION" == "H" ]]; then
            manage_hcr_support
            continue
        fi

        if [[ "$ACTION" =~ ^[0-9]+$ ]] && ((10#$ACTION >= 1 && 10#$ACTION <= ${#ACTIVE_PORTS[@]})); then
            PORT=${ACTIVE_PORTS[$((10#$ACTION - 1))]}
            toggle_port_multiprotocol "$PORT"
        fi
    done
}

restart_port() {
    local SERVICE_FILE SERVICE NAME LABEL CHOICE INDEX=0 SELECTED="" LANGUAGE
    local -a ACTIVE_SERVICES=() ACTIVE_LABELS=()

    while true; do
        ACTIVE_SERVICES=()
        ACTIVE_LABELS=()
        for SERVICE_FILE in "${SYSTEMD_DIR}"/proxy-*.service; do
            [[ -f "$SERVICE_FILE" ]] || continue
            SERVICE=$(basename "$SERVICE_FILE")
            systemctl is-active --quiet "$SERVICE" 2>/dev/null || continue
            NAME=${SERVICE#proxy-}
            NAME=${NAME%.service}
            case "$NAME" in
                integrated) LABEL="INTEGRADO" ;;
                443) LABEL="XHTTP (443)" ;;
                *) LABEL="PORTA ${NAME}" ;;
            esac
            ACTIVE_SERVICES+=("$SERVICE")
            ACTIVE_LABELS+=("$LABEL")
        done
        if systemctl is-active --quiet "$HCR_SERVICE" 2>/dev/null; then
            ACTIVE_SERVICES+=("$HCR_SERVICE")
            ACTIVE_LABELS+=("HCR (${HCR_PORT})")
        fi

        clear
        LANGUAGE="$(get_language)"
        show_banner
        echo ""
        box_top
        box_line "${WHITE}${BOLD}$(language_text restart_title "$LANGUAGE")${NC}"
        box_mid
        if ((${#ACTIVE_SERVICES[@]} == 0)); then
            box_line "${YELLOW}$(language_text no_active "$LANGUAGE")${NC}"
        else
            for ((INDEX=0; INDEX<${#ACTIVE_SERVICES[@]}; INDEX++)); do
                printf -v CHOICE '%02d' "$((INDEX + 1))"
                box_line "${WHITE}[${CHOICE}]${NC} - ${ACTIVE_LABELS[$INDEX]}"
            done
        fi
        box_mid
        box_line "${WHITE}[00]${NC} - $(language_text back "$LANGUAGE")"
        box_bottom
        echo ""
        read -r -p "$(language_text choose_port_restart "$LANGUAGE") " CHOICE
        [[ "$CHOICE" == "00" || "$CHOICE" == "0" || -z "$CHOICE" ]] && return

        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && ((10#$CHOICE >= 1 && 10#$CHOICE <= ${#ACTIVE_SERVICES[@]})); then
            SELECTED=${ACTIVE_SERVICES[$((10#$CHOICE - 1))]}
            if systemctl restart "$SELECTED" 2>/dev/null; then
                echo -e "${GREEN}${ACTIVE_LABELS[$((10#$CHOICE - 1))]} reiniciado!${NC}"
            else
                echo -e "${RED}Não foi possível reiniciar ${SELECTED}.${NC}"
            fi
            read -r -p "Enter para continuar..." _
        else
            echo -e "${RED}Opção inválida.${NC}"
            sleep 1
        fi
    done
}

close_service() {
    local SERVICE="$1"
    local SERVICE_FILE="${SYSTEMD_DIR}/${SERVICE}"
    if ! systemctl stop "$SERVICE" 2>/dev/null; then
        echo -e "${RED}Não foi possível parar ${SERVICE}; arquivo mantido.${NC}"
        read -r -p "Enter para continuar..." _
        return 1
    fi
    systemctl disable "$SERVICE" 2>/dev/null || true
    rm -f "$SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${GREEN}${SERVICE} fechado!${NC}"
    read -r -p "Enter para continuar..." _
}

close_port() {
    local SERVICE_FILE SERVICE NAME LABEL CHOICE INDEX=0 SELECTED="" LANGUAGE
    local -a ACTIVE_SERVICES=() ACTIVE_LABELS=()

    while true; do
        ACTIVE_SERVICES=()
        ACTIVE_LABELS=()
        for SERVICE_FILE in "${SYSTEMD_DIR}"/proxy-*.service; do
            [[ -f "$SERVICE_FILE" ]] || continue
            SERVICE=$(basename "$SERVICE_FILE")
            systemctl is-active --quiet "$SERVICE" 2>/dev/null || continue
            NAME=${SERVICE#proxy-}
            NAME=${NAME%.service}
            case "$NAME" in
                integrated) LABEL="INTEGRADO" ;;
                443) LABEL="XHTTP (443)" ;;
                *) LABEL="PORTA ${NAME}" ;;
            esac
            ACTIVE_SERVICES+=("$SERVICE")
            ACTIVE_LABELS+=("$LABEL")
        done
        if systemctl is-active --quiet "$HCR_SERVICE" 2>/dev/null; then
            ACTIVE_SERVICES+=("$HCR_SERVICE")
            ACTIVE_LABELS+=("HCR (${HCR_PORT})")
        fi

        clear
        LANGUAGE="$(get_language)"
        show_banner
        echo ""
        box_top
        box_line "${WHITE}${BOLD}$(language_text close_title "$LANGUAGE")${NC}"
        box_mid
        if ((${#ACTIVE_SERVICES[@]} == 0)); then
            box_line "${YELLOW}$(language_text no_active "$LANGUAGE")${NC}"
        else
            for ((INDEX=0; INDEX<${#ACTIVE_SERVICES[@]}; INDEX++)); do
                printf -v CHOICE '%02d' "$((INDEX + 1))"
                box_line "${WHITE}[${CHOICE}]${NC} - ${ACTIVE_LABELS[$INDEX]}"
            done
        fi
        box_mid
        box_line "${WHITE}[00]${NC} - $(language_text back "$LANGUAGE")"
        box_bottom
        echo ""
        read -r -p "$(language_text choose_port_close "$LANGUAGE") " CHOICE
        [[ "$CHOICE" == "00" || "$CHOICE" == "0" || -z "$CHOICE" ]] && return
        if [[ "$CHOICE" =~ ^[0-9]+$ ]] && ((10#$CHOICE >= 1 && 10#$CHOICE <= ${#ACTIVE_SERVICES[@]})); then
            SELECTED=${ACTIVE_SERVICES[$((10#$CHOICE - 1))]}
            close_service "$SELECTED"
        else
            echo -e "${RED}Opção inválida.${NC}"
            sleep 1
        fi
    done
}

manage_special_service() {
    local TITLE="$1"
    local SERVICE="$2"
    local OPEN_FUNCTION="$3"
    local ACTION

    while true; do
        clear
        show_banner
        echo ""
        box_top
        box_line "${WHITE}${BOLD}${TITLE}${NC}"
        box_mid
        box_line "${WHITE}[01]${NC} - ABRIR / CONFIGURAR"
        box_line "${YELLOW}[02]${NC} - REINICIAR PORTA"
        box_line "${RED}[03]${NC} - FECHAR PORTA"
        box_mid
        box_line "${WHITE}[00]${NC} - VOLTAR"
        box_bottom
        echo ""
        read -r -p "Escolha uma opção: " ACTION

        case "$ACTION" in
            01|1)
                "$OPEN_FUNCTION"
                ;;
            02|2)
                if systemctl restart "$SERVICE" 2>/dev/null; then
                    echo -e "${GREEN}${TITLE} reiniciado!${NC}"
                else
                    echo -e "${RED}Não foi possível reiniciar ${SERVICE}.${NC}"
                fi
                read -r -p "Enter para continuar..." _
                ;;
            03|3)
                systemctl stop "$SERVICE" 2>/dev/null
                systemctl disable "$SERVICE" 2>/dev/null
                rm -f "${SYSTEMD_DIR}/${SERVICE}"
                systemctl daemon-reload
                echo -e "${GREEN}${TITLE} fechado!${NC}"
                read -r -p "Enter para continuar..." _
                ;;
            00|0)
                return
                ;;
            *)
                ;;
        esac
    done
}

run_update_step() {
    local LABEL="$1"; shift
    local LOG_FILE PID RESULT FRAME=0
    local -a FRAMES=('|' '/' '-' '\\')
    LOG_FILE=$(mktemp /tmp/azpro-update-step.XXXXXX.log) || return 1

    "$@" >"$LOG_FILE" 2>&1 &
    PID=$!
    while kill -0 "$PID" 2>/dev/null; do
        printf '\r\033[2K  %s [%s]' "$LABEL" "${FRAMES[$FRAME]}"
        FRAME=$(((FRAME + 1) % ${#FRAMES[@]}))
        sleep 0.15
    done
    wait "$PID"
    RESULT=$?
    if [[ "$RESULT" -eq 0 ]]; then
        printf '\r\033[2K  %s [✔]\n' "$LABEL"
    else
        printf '\r\033[2K  %s [✘]\n' "$LABEL"
        sed -n '1,80p' "$LOG_FILE"
    fi
    rm -f "$LOG_FILE"
    return "$RESULT"
}

language_menu() {
    local CURRENT="pt-BR" CHOICE NEW_LANGUAGE LANGUAGE
    [[ -f "$LANGUAGE_FILE" ]] && CURRENT=$(cat "$LANGUAGE_FILE")

    while true; do
        clear
        LANGUAGE="$(get_language)"
        show_banner
        echo ""
        box_top
        box_line "${CYAN}${BOLD}MUDAR IDIOMA / CHANGE LANGUAGE${NC}"
        box_mid
        if [[ "$CURRENT" == "pt-BR" ]]; then
            box_line "${WHITE}1 • Português (Brasil)${NC} ${LIGHT_GREEN}(atual)${NC}"
        else
            box_line "${WHITE}1 • Português (Brasil)${NC}"
        fi
        if [[ "$CURRENT" == "en" ]]; then
            box_line "${WHITE}2 • English${NC} ${LIGHT_GREEN}(current)${NC}"
        else
            box_line "${WHITE}2 • English${NC}"
        fi
        if [[ "$CURRENT" == "es" ]]; then
            box_line "${WHITE}3 • Español${NC} ${LIGHT_GREEN}(actual)${NC}"
        else
            box_line "${WHITE}3 • Español${NC}"
        fi
        box_mid
        if [[ "$LANGUAGE" == "en" ]]; then
            box_line "${RED}0 • Back${NC}"
        elif [[ "$LANGUAGE" == "es" ]]; then
            box_line "${RED}0 • Volver${NC}"
        else
            box_line "${RED}0 • Voltar${NC}"
        fi
        box_bottom
        echo ""
        if [[ "$LANGUAGE" == "en" ]]; then
            read -r -p "Choose an option [0-3]: " CHOICE
        elif [[ "$LANGUAGE" == "es" ]]; then
            read -r -p "Seleccione una opción [0-3]: " CHOICE
        else
            read -r -p "Selecione uma opção [0-3]: " CHOICE
        fi

        case "$CHOICE" in
            1) NEW_LANGUAGE="pt-BR" ;;
            2) NEW_LANGUAGE="en" ;;
            3) NEW_LANGUAGE="es" ;;
            0|"") return ;;
            *) continue ;;
        esac

        mkdir -p "$BYPASS_DIR"
        printf '%s\n' "$NEW_LANGUAGE" > "$LANGUAGE_FILE"
        CURRENT="$NEW_LANGUAGE"
    done
}

update_from_github() {
    local CONFIRM="" UPDATE_SCRIPT="" UPDATE_RESULT=0 LANGUAGE="$(get_language)"
    clear
    show_banner
    echo ""
    box_top
    box_line "${WHITE}${BOLD}$(language_text update_title "$LANGUAGE")${NC}"
    box_mid
    box_line "$(language_text update_rebuild "$LANGUAGE")"
    box_line "$(language_text update_restart "$LANGUAGE")"
    box_line "$(language_text update_reload "$LANGUAGE")"
    box_bottom
    echo ""
    read -r -p "$(language_text update_confirm "$LANGUAGE") " CONFIRM
    is_yes "$CONFIRM" || return

    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Execute o menu como root para atualizar.${NC}"
        read -r -p "Enter para continuar..." _
        return
    fi
    if ! command -v curl >/dev/null 2>&1; then
        echo -e "${RED}curl não está instalado; não foi possível buscar a atualização.${NC}"
        read -r -p "Enter para continuar..." _
        return
    fi

    UPDATE_SCRIPT=$(mktemp /tmp/azpro-update.XXXXXX.sh) || {
        echo -e "${RED}Não foi possível criar arquivo temporário.${NC}"
        read -r -p "Enter para continuar..." _
        return
    }
    if ! run_update_step "Baixando instalador do GitHub" curl -fsSL --connect-timeout 15 --max-time 60 \
        "https://raw.githubusercontent.com/Lacasx1/Azpro/main/install.sh" \
        -o "$UPDATE_SCRIPT"; then
        rm -f "$UPDATE_SCRIPT"
        echo -e "${RED}Falha ao baixar o instalador. Nada foi atualizado.${NC}"
        read -r -p "Enter para continuar..." _
        return
    fi

    if ! run_update_step "Validando fonte do instalador" grep -q 'REPO_URL="https://github.com/Lacasx1/Azpro.git"' "$UPDATE_SCRIPT"; then
        rm -f "$UPDATE_SCRIPT"
        echo -e "${RED}O arquivo baixado não passou na validação do repositório.${NC}"
        read -r -p "Enter para continuar..." _
        return
    fi

    run_update_step "Atualizando binários e serviços" bash "$UPDATE_SCRIPT"
    UPDATE_RESULT=$?
    rm -f "$UPDATE_SCRIPT"
    if [[ $UPDATE_RESULT -eq 0 ]]; then
        echo -e "${AQUA}Atualização concluída.${NC}"
    else
        echo -e "${RED}A atualização falhou; confira as mensagens acima.${NC}"
    fi
    read -r -p "Enter para voltar ao menu..." _
    if [[ $UPDATE_RESULT -eq 0 && -x /opt/mpro/menu ]]; then
        exec bash /opt/mpro/menu
    fi
}

remove_owned_link() {
    local LINK="$1"
    local TARGET="$2"
    local CURRENT
    [[ -L "$LINK" ]] || return 0
    CURRENT=$(readlink -- "$LINK") || return 0
    [[ "$CURRENT" == "$TARGET" ]] && rm -f -- "$LINK"
}

uninstall_proxy() {
    local CONFIRM SERVICE_FILE SERVICE STATE BIN FAILED=0 LANGUAGE="$(get_language)"
    local -a OWNED_SERVICES=()
    local -a BINARIES=("$LKPROXY" "$LKPROXY_XHTTP" "$LKPROXY_INTEGRATED" "/opt/mpro/proxy-websocket")

    clear
    show_banner
    echo ""
    box_top
    box_line "${RED}${BOLD}$(language_text uninstall_title "$LANGUAGE")${NC}"
    box_mid
    box_line "$(language_text uninstall_desc1 "$LANGUAGE")"
    box_line "$(language_text uninstall_desc2 "$LANGUAGE")"
    box_line "$(language_text uninstall_desc3 "$LANGUAGE")"
    box_mid
    echo ""

    if [[ "$EUID" -ne 0 ]]; then
        echo -e "${RED}Execute azpro como root para desinstalar.${NC}"
        read -r -p "Enter para voltar..." _
        return 1
    fi
    if ! command -v systemctl >/dev/null 2>&1; then
        echo -e "${RED}systemctl não encontrado; nada foi removido.${NC}"
        read -r -p "Enter para voltar..." _
        return 1
    fi

    echo -e "${YELLOW}Para desinstalar o proxy, digite: s${NC}"
    echo -e "${YELLOW}Para cancelar a desinstalação, digite: n${NC}"
    read -r -p "Escolha (s/n): " CONFIRM
    if ! is_yes "$CONFIRM"; then
        echo -e "${YELLOW}Desinstalação cancelada.${NC}"
        read -r -p "Enter para voltar..." _
        return 0
    fi

    for SERVICE_FILE in "${SYSTEMD_DIR}"/proxy-*.service; do
        [[ -f "$SERVICE_FILE" ]] || continue
        if grep -Eq '^[[:space:]]*ExecStart=.*/opt/mpro/(proxy|proxy-xhttp|proxy-integrated|proxy-websocket)([[:space:]]|$)' "$SERVICE_FILE"; then
            OWNED_SERVICES+=("$(basename "$SERVICE_FILE")")
        fi
    done
    for SERVICE_FILE in "${SYSTEMD_DIR}"/hcr-*.service; do
        [[ -f "$SERVICE_FILE" ]] || continue
        if grep -Eq '^[[:space:]]*ExecStart=.*/opt/mpro/hcr-server([[:space:]]|$)' "$SERVICE_FILE"; then
            OWNED_SERVICES+=("$(basename "$SERVICE_FILE")")
        fi
    done

    for SERVICE in "${OWNED_SERVICES[@]}"; do
        systemctl stop "$SERVICE" >/dev/null 2>&1 || true
        STATE=$(systemctl show --property=ActiveState --value "$SERVICE" 2>/dev/null) || STATE="unknown"
        case "$STATE" in
            inactive|failed) ;;
            *)
                echo -e "${RED}${SERVICE} não parou com segurança (estado: ${STATE}); binários mantidos.${NC}"
                FAILED=1
                ;;
        esac
    done
    if [[ "$FAILED" -ne 0 ]]; then
        read -r -p "Resolva os serviços ativos e tente novamente. Enter para voltar..." _
        return 1
    fi

    for SERVICE in "${OWNED_SERVICES[@]}"; do
        if ! systemctl disable "$SERVICE" >/dev/null 2>&1; then
            echo -e "${RED}Falha ao desabilitar ${SERVICE}; arquivos do proxy foram mantidos.${NC}"
            read -r -p "Enter para voltar..." _
            return 1
        fi
    done
    for SERVICE in "${OWNED_SERVICES[@]}"; do
        rm -f -- "${SYSTEMD_DIR}/${SERVICE}"
    done
    if ! systemctl daemon-reload; then
        echo -e "${RED}Falha ao recarregar systemd; arquivos do proxy foram mantidos.${NC}"
        read -r -p "Enter para voltar..." _
        return 1
    fi

    for BIN in "${BINARIES[@]}"; do
        pkill -f "^${BIN}([[:space:]]|$)" >/dev/null 2>&1 || true
    done
    sleep 1
    for BIN in "${BINARIES[@]}"; do
        if pgrep -f "^${BIN}([[:space:]]|$)" >/dev/null 2>&1; then
            echo -e "${RED}Ainda há um processo ${BIN} ativo; arquivos do proxy foram mantidos.${NC}"
            read -r -p "Enter para voltar..." _
            return 1
        fi
    done

    remove_owned_link "/usr/local/bin/azpro" "/opt/mpro/menu"
    remove_owned_link "/usr/local/bin/wzpro" "/opt/mpro/menu"
    remove_owned_link "/usr/local/bin/wspro" "/opt/mpro/menu"
    remove_owned_link "/usr/local/bin/mpro" "/opt/mpro/menu"
    remove_owned_link "/usr/local/bin/mpro-xhttp" "$LKPROXY_XHTTP"
    remove_owned_link "/usr/local/bin/mpro-integrated" "$LKPROXY_INTEGRATED"
    rm -f -- "${BYPASS_DIR}"/bypass-http-ssh-*.enabled \
        "${BYPASS_DIR}"/multiprotocol-*.enabled \
        "${BYPASS_DIR}"/hcr-*.enabled
    if ! rm -f -- "$LKPROXY" "$LKPROXY_XHTTP" "$LKPROXY_INTEGRATED" \
        "/opt/mpro/proxy-websocket" "/opt/mpro/menu" "/opt/mpro/cert.pem" \
        "/opt/mpro/key.pem" "$LEGACY_MULTIPROTOCOL_FLAG" "${BYPASS_DIR}/hcr-server"; then
        echo -e "${RED}Falha ao remover alguns arquivos; revise /opt/mpro.${NC}"
        read -r -p "Enter para voltar..." _
        return 1
    fi
    rm -rf -- "/var/cache/azpro/cargo-target" "/var/cache/wzpro/cargo-target"
    rmdir /var/cache/azpro /var/cache/wzpro 2>/dev/null || true
    rmdir /opt/mpro 2>/dev/null || true

    echo -e "${GREEN}Azpro desinstalado. SSH e dependências do sistema foram preservados.${NC}"
    echo -e "${YELLOW}Arquivos não reconhecidos em /opt/mpro, se houver, foram preservados.${NC}"
    sleep 3
    exit 0
}

show_menu() {
    local LANGUAGE="$(get_language)"
    clear
    show_banner
    echo ""
    box_top
    show_execution_status
    box_mid
    show_active_ports
    box_mid
    box_line "${WHITE}[01]${NC} ${GREEN}- $(language_text open_port "$LANGUAGE")${NC}"
    box_line "${WHITE}[02]${NC} ${GREEN}- $(language_text close_port "$LANGUAGE")${NC}"
    box_line "${WHITE}[03]${NC} ${GREEN}- $(language_text restart_port "$LANGUAGE")${NC}"
    box_line "${WHITE}[04]${NC} ${GREEN}- $(language_text xhttp "$LANGUAGE")${NC}"
    box_line "${WHITE}[05]${NC} ${GREEN}- $(language_text integrated "$LANGUAGE")${NC}"
    box_line "${WHITE}[06]${NC} ${GREEN}- $(language_text update "$LANGUAGE")${NC}"
    box_line "${WHITE}[07]${NC} ${GREEN}- $(language_text status "$LANGUAGE")${NC}"
    box_line "${RED}[08]${NC} ${GREEN}- $(language_text uninstall "$LANGUAGE")${NC}"
    box_line "${WHITE}[09]${NC} ${GREEN}- $(language_text language "$LANGUAGE")${NC}"
    box_line ""
    box_line "${WHITE}[00]${NC} - $(language_text exit "$LANGUAGE")"
    box_bottom
    echo ""
    echo -n "$(language_text choose "$LANGUAGE") "
}

while true; do
    show_menu
    read OPTION
    case $OPTION in
        01|1) configure_ports ;;
        02|2) close_port ;;
        03|3) restart_port ;;
        04|4) manage_special_service "XHTTP + SSL TUNNEL" "proxy-443.service" open_xhttp ;;
        05|5) manage_special_service "PROTOCOLO INTEGRADO" "proxy-integrated.service" open_integrated ;;
        06|6) update_from_github ;;
        07|7) manage_multiprotocol ;;
        08|8) uninstall_proxy ;;
        09|9) language_menu ;;
        00|0) echo "👋 Saindo..."; exit 0 ;;
        *) sleep 1 ;;
    esac
done
