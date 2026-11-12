# Mpro - Changelog

## v3.8.5 - HCR: buffer do relay e pacing BBR

### Otimizações
- HCR TLS no modo multiprotocolo agora usa o relay compartilhado com buffers de 128 KiB por direção e os ajustes TCP do Azpro, em vez do buffer padrão pequeno do Tokio.
- Quando BBR estiver disponível, o perfil HCR define `fq` como qdisc padrão do host; isso não força a troca do qdisc já ativo na interface, que pode continuar sob controle da VPS. O HCR plain da porta 8880 continua usando o binário oficial e se beneficia apenas dos ajustes do kernel.

### Observação
- Essas alterações podem melhorar o throughput e reduzir fila criada no servidor, mas não reduzem o RTT físico da rede móvel; o resultado depende do kernel, da VPS, do cliente e da rota da operadora.

## v3.8.4 - HCR: throughput e latência do kernel

### Otimizações
- A abertura do HCR agora instala `/etc/sysctl.d/99-azpro-hcr.conf` com janelas TCP adaptativas de até 16 MiB, `tcp_slow_start_after_idle=0`, MTU probing e keep-alive persistente.
- Quando a VPS oferece BBR, o Azpro seleciona `net.ipv4.tcp_congestion_control=bbr` para melhorar throughput em redes com perda/RTT alto.
- Unit HCR passa a usar `LimitNOFILE=65535` e `LimitNPROC=65535`.

### Observação
- BBR e janelas maiores melhoram o uso da rota, mas não reduzem o ping físico nem corrigem uma rota ruim da operadora. O ganho real depende do kernel, da VPS e do cliente HCR.

## v3.8.3 - Throughput xHTTP

### Otimizações
- Caminhos xHTTP raw, TLS e integrado deixaram de usar `tokio::io::copy` com buffer padrão pequeno e passaram a usar o relay otimizado de 128 KiB por direção.
- A mesma melhoria foi aplicada aos binários `mpro`, `mpro-xhttp` e `mpro-integrated`, evitando que o resultado dependesse de qual modo do menu foi utilizado.
- Mantidos `TCP_NODELAY`, buffers de socket e TCP keep-alive nas conexões cliente/backend.

## v3.8.2 - Conexões persistentes e keep-alive

### Corrigido
- Ativado `SO_KEEPALIVE` com probes TCP a cada 20 segundos, intervalo de 10 segundos e até 6 tentativas para manter conexões ociosas detectáveis e reduzir quedas silenciosas em redes móveis/NAT.
- Sessões xHTTP agora podem permanecer ativas por até 24 horas em vez de serem encerradas após 10 minutos sem leitura do backend.
- Uploads xHTTP em redes móveis ganharam tolerância de 120 segundos por bloco, evitando reconexões causadas por pausas curtas durante o envio.

### Observação
- Keep-alive evita encerramento silencioso quando a rota continua disponível, mas não pode impedir um cliente, CDN, operadora ou NAT de impor seu próprio limite de 120 segundos. Nesses casos o cliente precisa enviar seus próprios keep-alives de SSH/xHTTP.

## v3.8.1 - Correção do atraso no início do túnel

### Corrigido
- O fluxo HTTP legado descartava o primeiro pacote recebido e depois fazia um `peek` com timeout de até 1 segundo para selecionar SSH/VPN. Agora o pacote é preservado, usado para selecionar o backend e encaminhado imediatamente.
- O primeiro buffer do túnel legado foi ampliado para 16 KiB, evitando perda de dados quando o cliente envia o início do payload junto.

## v3.8.0 - Throughput e latência de túnel

### Otimizações
- Relay TCP com buffers de 128 KiB por direção, reduzindo syscalls em downloads e uploads longos sem criar buffers gigantes por conexão.
- Tuning TCP centralizado: `TCP_NODELAY`, buffers de socket de até 512 KiB e `TCP_QUICKACK` no Linux, aplicado ao cliente e ao backend SSH/VPN.
- WebSocket e xHTTP passaram a usar buffers de leitura maiores para downloads e menos operações de escrita desnecessárias.
- Removidos `flush()` redundantes do fluxo de chunks xHTTP; `write_all()` já entrega os dados ao socket TCP.
- Janela de espera do preâmbulo HTTP fragmentado reduzida de 750 ms para 200 ms, preservando tolerância a redes móveis e reduzindo latência de início do túnel.

### Observação
- Essas mudanças reduzem atraso introduzido pelo servidor e melhoram throughput. O ping mínimo entre aparelho e VPS continua limitado pela distância, rota e qualidade da operadora; nenhum ajuste de código consegue eliminar essa latência física.

## v3.7.0 - HCR com instalação automática

### Novo
- **HCR INSTALAR / ATUALIZAR SERVIDOR** (opção 03 do submenu CONFIGURAR PORTAS): baixa o `hcr-server` oficial (Linux amd64), valida o ELF64 x86-64 antes de instalar, guarda backup do binário anterior em `/opt/mpro/hcr-server.bak.<data>` e reinicia o `hcr-8880.service` quando ele está ativo.
- Origem do binário configurável pela variável `HCR_SOURCE_URL`.

### Corrigido
- **HCR ABRIR PORTA** não para mais no aviso "Servidor HCR oficial não instalado": o menu oferece baixar e instalar o binário na hora e, se a instalação for recusada, apenas mostra onde colocá-lo.
- Argumentos do serviço: o menu detecta se o binário usa `-listen :8880 -target 127.0.0.1:22 -transport plain` ou `--port 8880 --transport plain` e tenta o formato alternativo se a porta não subir.
- A abertura da porta agora confirma que a 8880 está realmente escutando e desfaz a unit se o serviço falhar, em vez de apenas habilitar o serviço.
- Unit `hcr-8880.service` existente e parada: o menu pergunta se deve iniciá-la em vez de abortar.
- Serviço HCR incluído nas listas de **REINICIAR PORTA** e **FECHAR PORTA**, no status ONLINE/OFFLINE e na desinstalação (unit e binário do Azpro).

## v3.6.0 - Latency Optimized for Low Latency Networks

### Otimizações de Latência

#### Fator 1 – Múltiplas requisições POST/GET:
- **Keep-Alive** adicionado nos headers (timeout=30, max=100) — o cliente reutiliza a mesma conexão TCP pra enviar POSTs, não precisa abrir nova conexão a cada envio
- **Canal GET/POST ampliado** de 4096 para **16384** — menos backpressure em redes lentas
- Buffer de leitura HTTP raw ampliado de 8192 para **16384**

#### Fator 2 – HTTP/1.1 sem multiplexação:
- **TCP_QUICKACK ativado** — ACK imediato sem delay, funciona como uma forma de "multiplexação" via TCP
- **POST read_exact sem timeout** — lê o corpo completo do POST sem esperar, mais rápido em redes lentas

#### Fator 3 – Redes restritas/ADSL com alta latência:
- **TCP_QUICKACK** (ACK imediato, elimina o delay do Nagle)
- **Peek timeout reduzido para 200ms** (detecção ultra rápida)
- **TLS read timeout reduzido para 1.5s**
- **SSH connect timeout reduzido para 3s** (resposta 200 já foi enviada antes)

### Para aplicar no servidor:
```bash
cd /root/Mxpro && git pull && ./install.sh
systemctl restart proxy-443
```

---

## v2.4.1 - xHTTP SplitHTTP (DTUNNEL Fix)

### Novo
- **Correção SplitHTTP** — suporte completo ao protocolo SplitHTTP usado no DTUNNEL
- **Persistência HTTP/1.1** — headers `Connection: keep-alive` obrigatórios para manter o canal GET aberto
- **ALPN http/1.1** — forçando ALPN http/1.1 no TLS para evitar falhas de handshake no DTUNNEL
- **Path Parsing** — suporte a paths com sequence numbers (ex: `/ssh/session/0`)
- **Headers de Streaming** — inclusão de headers `Cache-Control`, `Pragma` e `Expires` para evitar cache de proxy intermediário (CDN)


## v0.3.0 - Multi-Protocolo (TCP + UDP + QUIC)

### Novo

- **Suporte UDP** — listener UDP na mesma porta TCP, encaminhamento de datagramas
- **Suporte QUIC** — servidor QUIC completo com `quinn` crate, streams bidirecionais
- **Certificado auto-assinado** — geração automática de cert.pem e key.pem via `rcgen`
- **Ativação automática** — ao usar `-p 443 -t`, UDP e QUIC são ativados automaticamente
- **Flags novas:**
  - `-u` / `--udp` — ativar UDP na porta TCP
  - `-q` / `--quic` — ativar QUIC (porta separada via `--quic-port` ou mesma)

### Flags de Uso

```bash
# Multi-protocolo completo (TCP + UDP + QUIC) na 443
./mpro -p 443 -t -ssh

# Apenas TCP + UDP
./mpro -p 443 -t -u -ssh

# Apenas TCP + QUIC
./mpro -p 443 -t -q -ssh

# QUIC em porta separada
./mpro -p 443 -t -q --quic-port 8001 -ssh
```

### Configuração do menu.sh

Ao abrir a porta 443 com HTTPS habilitado, o proxy agora inicia automaticamente:
- TCP:443 (xHTTP, Proto, WebSocket, TLS, SSH)
- UDP:443 (proxy UDP para xHTTP/Proto)
- QUIC:8001 (proxy QUIC com certificado auto-assinado)

### Certificados

Os certificados QUIC são gerados automaticamente em `/opt/mpro/cert.pem` e `/opt/mpro/key.pem` na primeira execução com QUIC ativo.

### Arquitetura

```
Cliente → [TCP:443] → Mpro → SSH:22 / VPN:1194
Cliente → [UDP:443] → Mpro → SSH:22 / VPN:1194
Cliente → [QUIC:8001] → Mpro → SSH:22 / VPN:1194
```

---

## v0.2.0 - xHTTP/Proto + TLS

### Novo
- Handler xHTTP com handshake HTTP/101 + 200 e headers customizados
- Handler Proto para conexões TCP raw/binary
- TLS com passthrough e terminação (flags -t e -ssh)
- Detecção aprimorada de protocolos (TLS, xHTTP, Proto, SOCKS5)
- Integração de todos os handlers existentes
- WebSocket com suporte a Sec-WebSocket-Accept (SHA-1 + Base64)
- Fallback automático SSH↔VPN em todos os handlers
