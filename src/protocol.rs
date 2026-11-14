use base64::{engine::general_purpose::STANDARD, Engine as _};
use std::io;
use tokio::net::TcpStream;
use tokio::time::{sleep, timeout, Duration};

const MAX_PEEK: usize = 16 * 1024;
const DETECT_TIMEOUT: Duration = Duration::from_millis(800);
const HCR_HEADER_SIZE: usize = 62;
const HCR_MAX_PAYLOAD: u32 = 262_144;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Protocol {
    Socks4,
    Socks5,
    Hcr,
    Tls,
    WebSocket,
    Security,
    Http,
    SshDirect,
    Unknown,
}

/// Classifica somente handshakes reconhecidos. Nenhum byte é consumido.
pub fn detect_protocol(data: &[u8]) -> Option<Protocol> {
    if data.is_empty() {
        return None;
    }

    match sniff_hcr_frame(data) {
        Some(true) => return Some(Protocol::Hcr),
        None => return None,
        _ => {}
    }

    if data[0] == 0x04 {
        return Some(Protocol::Socks4);
    }
    if data[0] == 0x05 {
        return Some(Protocol::Socks5);
    }
    if data[0] == 0x16 {
        return Some(Protocol::Tls);
    }
    if starts_with_ascii_case_insensitive(data, b"SECURITY")
        || starts_with_ascii_case_insensitive(data, b"AUTH")
    {
        return Some(Protocol::Security);
    }
    if data.starts_with(b"SSH-") {
        return Some(Protocol::SshDirect);
    }

    if is_http_method_prefix(data) {
        let request = String::from_utf8_lossy(data);
        let Some(header_end) = request.find("\r\n\r\n") else {
            return None;
        };
        let headers = &request[..header_end];
        let security_upgrade = header_value(headers, "Upgrade").is_some_and(|value| {
            value
                .split(',')
                .any(|token| token.trim().eq_ignore_ascii_case("security"))
        });
        let security_protocol = header_value(headers, "X-Protocol")
            .is_some_and(|value| value.eq_ignore_ascii_case("security"));
        if security_upgrade || security_protocol {
            return Some(Protocol::Security);
        }
        if is_valid_websocket_upgrade(headers) {
            return Some(Protocol::WebSocket);
        }
        return Some(Protocol::Http);
    }

    None
}

/// Reconhece Expect: 100-continue e variantes usadas por payloads customizados.
pub fn has_expect_continue(data: &[u8]) -> bool {
    String::from_utf8_lossy(data).lines().any(|line| {
        let Some((name, value)) = line.split_once(':') else {
            return false;
        };
        name.trim().eq_ignore_ascii_case("expect")
            && value.to_ascii_lowercase().contains("continue")
    })
}

/// Aguarda um prefixo suficiente para classificação, usando peek para preservar
/// o handshake para o respectivo handler. Conexões silenciosas são classificadas
/// como SSH_DIRECT para que o dispatcher aplique a política da porta.
pub async fn detect_from_stream(stream: &TcpStream) -> io::Result<Protocol> {
    let mut buffer = vec![0u8; MAX_PEEK];
    let mut bytes_peeked = 0usize;

    let result = timeout(DETECT_TIMEOUT, async {
        loop {
            bytes_peeked = stream.peek(&mut buffer).await?;
            if bytes_peeked == 0 {
                return Ok(Protocol::SshDirect);
            }

            if let Some(protocol) = detect_protocol(&buffer[..bytes_peeked]) {
                return Ok(protocol);
            }

            if bytes_peeked >= MAX_PEEK {
                return Ok(if is_incomplete_http_message(&buffer[..bytes_peeked]) {
                    Protocol::Http
                } else {
                    Protocol::Unknown
                });
            }

            if is_http_method_prefix(&buffer[..bytes_peeked]) {
                sleep(Duration::from_millis(10)).await;
                continue;
            }
            if !may_be_incomplete_known_prefix(&buffer[..bytes_peeked]) {
                return Ok(Protocol::Unknown);
            }
            sleep(Duration::from_millis(10)).await;
        }
    })
    .await;

    match result {
        Ok(classification) => classification,
        Err(_) if bytes_peeked == 0 => Ok(Protocol::SshDirect),
        Err(_) => {
            let data = &buffer[..bytes_peeked];
            if let Some(protocol) = classify_after_protocol_timeout(data) {
                Ok(protocol)
            } else if is_incomplete_http_message(data) {
                Ok(Protocol::Http)
            } else {
                Ok(Protocol::Unknown)
            }
        }
    }
}

fn is_http_method_prefix(data: &[u8]) -> bool {
    const RESPONSE_PREFIX: &[u8] = b"HTTP/";
    if data.len() <= RESPONSE_PREFIX.len()
        && RESPONSE_PREFIX[..data.len()].eq_ignore_ascii_case(data)
    {
        return true;
    }
    if data.len() > RESPONSE_PREFIX.len()
        && data[..RESPONSE_PREFIX.len()].eq_ignore_ascii_case(RESPONSE_PREFIX)
    {
        return true;
    }

    let method_end = data
        .iter()
        .position(|byte| *byte == b' ')
        .unwrap_or(data.len());
    let method = &data[..method_end];
    if method.is_empty() || method.len() > 32 || !method.iter().all(|byte| is_http_token(*byte)) {
        return false;
    }

    // Antes do espaço, pode ser um método dividido entre pacotes; depois dele,
    // a linha continua sendo tratada como HTTP até a detecção dos headers.
    true
}

fn is_incomplete_http_message(data: &[u8]) -> bool {
    if data.starts_with(b"HTTP/") {
        return true;
    }
    let Some(space) = data.iter().position(|byte| *byte == b' ') else {
        return false;
    };
    let method = &data[..space];
    let target = &data[space + 1..];
    !method.is_empty()
        && method.len() <= 32
        && method.iter().all(|byte| is_http_token(*byte))
        && target.iter().any(|byte| !byte.is_ascii_whitespace())
}

fn is_http_token(byte: u8) -> bool {
    byte.is_ascii_alphanumeric() || b"!#$%&'*+-.^_`|~".contains(&byte)
}

/// `Some(true)` is a valid HCR header, `Some(false)` cannot be HCR, and `None`
/// means the bytes still match an HCR prefix and more are needed. Any of the six
/// HCR request opcodes may arrive on a separate TCP connection, so inspect all
/// of them before SOCKS4/SOCKS5, whose first bytes overlap with HCR opcodes 4/5.
fn sniff_hcr_frame(data: &[u8]) -> Option<bool> {
    if data.is_empty() {
        return None;
    }
    if !(1..=6).contains(&data[0]) {
        return Some(false);
    }
    if data.len() < 2 {
        return None;
    }
    if data[1] != 0x01 {
        return Some(false);
    }
    if data.len() < HCR_HEADER_SIZE {
        return None;
    }
    let payload_len = u32::from_be_bytes([data[58], data[59], data[60], data[61]]);
    Some(payload_len <= HCR_MAX_PAYLOAD)
}

fn is_socks4_prefix(data: &[u8]) -> bool {
    data.len() >= 2 && data[0] == 0x04 && matches!(data[1], 0x01 | 0x02)
}

fn is_complete_socks4_request(data: &[u8]) -> bool {
    is_socks4_prefix(data) && data.len() >= 9 && data[8..].contains(&0)
}

fn is_complete_socks5_greeting(data: &[u8]) -> bool {
    data.len() >= 2
        && data[0] == 0x05
        && data[1] > 0
        && data.len() >= 2 + usize::from(data[1])
}

fn classify_after_protocol_timeout(data: &[u8]) -> Option<Protocol> {
    if is_complete_socks4_request(data) {
        Some(Protocol::Socks4)
    } else if is_complete_socks5_greeting(data) {
        Some(Protocol::Socks5)
    } else {
        None
    }
}

fn header_value<'a>(headers: &'a str, name: &str) -> Option<&'a str> {
    headers.lines().skip(1).find_map(|line| {
        let (key, value) = line.split_once(':')?;
        key.trim().eq_ignore_ascii_case(name).then(|| value.trim())
    })
}

fn header_has_token(headers: &str, name: &str, token: &str) -> bool {
    headers.lines().skip(1).any(|line| {
        let Some((key, value)) = line.split_once(':') else {
            return false;
        };
        key.trim().eq_ignore_ascii_case(name)
            && value
                .split(',')
                .any(|part| part.trim().eq_ignore_ascii_case(token))
    })
}

fn is_valid_websocket_upgrade(headers: &str) -> bool {
    let mut lines = headers.lines();
    let Some(start_line) = lines.next() else {
        return false;
    };
    let fields: Vec<_> = start_line.split_ascii_whitespace().collect();
    if fields.len() != 3 || fields[0] != "GET" || fields[2] != "HTTP/1.1" {
        return false;
    }
    if !header_has_token(headers, "Upgrade", "websocket")
        || !header_has_token(headers, "Connection", "upgrade")
        || header_value(headers, "Sec-WebSocket-Version") != Some("13")
    {
        return false;
    }
    header_value(headers, "Sec-WebSocket-Key")
        .and_then(|key| STANDARD.decode(key).ok())
        .is_some_and(|decoded| decoded.len() == 16)
}

fn may_be_incomplete_known_prefix(data: &[u8]) -> bool {
    if sniff_hcr_frame(data).is_none() {
        return true;
    }
    const PREFIXES: [&[u8]; 13] = [
        b"SSH-",
        b"SECURITY",
        b"AUTH",
        b"GET ",
        b"POST ",
        b"PUT ",
        b"DELETE ",
        b"PATCH ",
        b"HEAD ",
        b"CONNECT ",
        b"OPTIONS ",
        b"TRACE ",
        b"HTTP/",
    ];
    PREFIXES
        .iter()
        .any(|prefix| data.len() < prefix.len() && prefix[..data.len()].eq_ignore_ascii_case(data))
}

fn starts_with_ascii_case_insensitive(data: &[u8], prefix: &[u8]) -> bool {
    data.len() >= prefix.len() && prefix.eq_ignore_ascii_case(&data[..prefix.len()])
}

#[cfg(test)]
mod tests {
    use super::{
        classify_after_protocol_timeout, detect_protocol, has_expect_continue,
        is_incomplete_http_message, Protocol, HCR_HEADER_SIZE, HCR_MAX_PAYLOAD,
    };

    #[test]
    fn detects_binary_and_raw_protocol_signatures() {
        let socks4 = b"\x04\x01\x00\x50\x7f\x00\x00\x01user\x00";
        let socks5 = b"\x05\x01\x00";
        assert_eq!(detect_protocol(socks4), None);
        assert_eq!(detect_protocol(socks5), None);
        assert_eq!(classify_after_protocol_timeout(socks4), Some(Protocol::Socks4));
        assert_eq!(classify_after_protocol_timeout(socks5), Some(Protocol::Socks5));
        assert_eq!(detect_protocol(&[0x16, 0x03, 0x01]), Some(Protocol::Tls));
        assert_eq!(
            detect_protocol(b"SSH-2.0-client\r\n"),
            Some(Protocol::SshDirect)
        );
        assert_eq!(detect_protocol(b"SECURITY /\r\n"), Some(Protocol::Security));
        assert_eq!(detect_protocol(b"AUTH payload"), Some(Protocol::Security));
    }

    #[test]
    fn detects_all_complete_hcr_opcodes_before_overlapping_protocols() {
        let mut hcr = [0u8; HCR_HEADER_SIZE];
        hcr[1] = 1; // HCR protocol version
        for opcode in 1..=6 {
            hcr[0] = opcode;
            assert_eq!(detect_protocol(&hcr), Some(Protocol::Hcr));
        }
        hcr[0] = 1;
        assert_eq!(detect_protocol(&hcr[..2]), None);

        hcr[58..62].copy_from_slice(&(HCR_MAX_PAYLOAD + 1).to_be_bytes());
        assert_eq!(detect_protocol(&hcr), None);
    }

    #[test]
    fn distinguishes_websocket_security_and_http_after_complete_headers() {
        let websocket = b"GET / HTTP/1.1\r\nUpgrade: websocket\r\nConnection: keep-alive, Upgrade\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n";
        let security = b"GET / HTTP/1.1\r\nUpgrade: security\r\nConnection: Upgrade\r\n\r\n";
        let http = b"CONNECT host:22 HTTP/1.1\r\nHost: host:22\r\n\r\n";
        assert_eq!(detect_protocol(websocket), Some(Protocol::WebSocket));
        assert_eq!(detect_protocol(security), Some(Protocol::Security));
        assert_eq!(detect_protocol(http), Some(Protocol::Http));
    }

    #[test]
    fn does_not_misclassify_http_when_security_text_appears_in_an_unrelated_header() {
        let http = b"GET / HTTP/1.1\r\nHost: example\r\nUser-Agent: note Upgrade: security\r\n\r\n";
        assert_eq!(detect_protocol(http), Some(Protocol::Http));
    }

    #[test]
    fn only_first_http_header_block_controls_dispatch() {
        let pipelined = b"GET / HTTP/1.1\r\nHost: example\r\n\r\nGET /ws HTTP/1.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Version: 13\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\n\r\n";
        let incomplete_upgrade =
            b"GET / HTTP/1.1\r\nHost: example\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n\r\n";
        assert_eq!(detect_protocol(pipelined), Some(Protocol::Http));
        assert_eq!(detect_protocol(incomplete_upgrade), Some(Protocol::Http));
    }

    #[test]
    fn waits_for_partial_http_headers() {
        assert_eq!(detect_protocol(b"GET / HTTP/1.1\r\nHost: ex"), None);
    }

    #[test]
    fn detects_extension_http_methods_but_rejects_non_token_lines() {
        let propfind = b"PROPFIND /dav HTTP/1.1\r\nHost: example\r\n\r\n";
        let m_search = b"M-SEARCH * HTTP/1.1\r\nHost: example\r\n\r\n";
        assert_eq!(detect_protocol(propfind), Some(Protocol::Http));
        assert_eq!(detect_protocol(m_search), Some(Protocol::Http));
        assert_eq!(detect_protocol(b"?? / HTTP/1.1\r\n\r\n"), None);
    }

    #[test]
    fn incomplete_http_fallback_rejects_arbitrary_unknown_text() {
        assert!(!is_incomplete_http_message(b"xyz"));
        assert!(!is_incomplete_http_message(b"SSH-2.0-test"));
        assert!(is_incomplete_http_message(b"GET /"));
        assert!(is_incomplete_http_message(b"UPDATE [host]"));
        assert!(is_incomplete_http_message(b"HTTP/1.1 200"));
    }

    #[test]
    fn detects_continue_expect_header_case_insensitively() {
        assert!(has_expect_continue(
            b"GET / HTTP/1.1\r\nExpect: 101-continue\r\n\r\n"
        ));
        assert!(has_expect_continue(
            b"POST / HTTP/1.1\nexpect: 100-Continue\n\n"
        ));
        assert!(!has_expect_continue(
            b"GET / HTTP/1.1\r\nHost: example\r\n\r\n"
        ));
    }
}
