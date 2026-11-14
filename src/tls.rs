use anyhow::Result;
use log::info;
use std::sync::Arc;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;
use tokio::sync::Mutex;
use tokio::time::{timeout, Duration};

const HCR_BACKEND_CONNECT_TIMEOUT: Duration = Duration::from_secs(3);
const HCR_BACKEND_ADDR: &str = "127.0.0.1:8880";

/// Handle TLS connections - passthrough to backend.
pub async fn handle_tls(socket: TcpStream) -> Result<()> {
    info!("TLS detectado - passthrough para backend...");
    socket.set_nodelay(true)?;

    // Tentar SSH primeiro (Porta 22).
    match TcpStream::connect("127.0.0.1:22").await {
        Ok(remote) => {
            remote.set_nodelay(true)?;
            info!("TLS -> SSH:22 conectado");
            let (cr, cw) = socket.into_split();
            let (sr, sw) = remote.into_split();
            let cr = Arc::new(Mutex::new(cr));
            let cw = Arc::new(Mutex::new(cw));
            let sr = Arc::new(Mutex::new(sr));
            let sw = Arc::new(Mutex::new(sw));
            tokio::try_join!(transfer_data(cr, sw), transfer_data(sr, cw))?;
            Ok(())
        }
        Err(_) => {
            // Se SSH falhar, tentar VPN (Porta 1194).
            match TcpStream::connect("127.0.0.1:1194").await {
                Ok(remote) => {
                    remote.set_nodelay(true)?;
                    info!("TLS -> VPN:1194 conectado");
                    let (cr, cw) = socket.into_split();
                    let (sr, sw) = remote.into_split();
                    let cr = Arc::new(Mutex::new(cr));
                    let cw = Arc::new(Mutex::new(cw));
                    let sr = Arc::new(Mutex::new(sr));
                    let sw = Arc::new(Mutex::new(sw));
                    tokio::try_join!(transfer_data(cr, sw), transfer_data(sr, cw))?;
                    Ok(())
                }
                Err(e) => {
                    info!("Falha no passthrough TLS: {}", e);
                    Err(e.into())
                }
            }
        }
    }
}

/// Encaminha o fluxo HCR intacto ao servidor oficial HCR em transporte plain.
pub async fn handle_hcr(mut socket: TcpStream) -> Result<()> {
    crate::relay::tune_tcp_stream(&socket);
    let mut hcr = timeout(
        HCR_BACKEND_CONNECT_TIMEOUT,
        TcpStream::connect(HCR_BACKEND_ADDR),
    )
    .await
    .map_err(|_| anyhow::anyhow!("timeout conectando ao servidor HCR em {HCR_BACKEND_ADDR}"))??;
    crate::relay::tune_tcp_stream(&hcr);
    info!("HCR multiprotocolo -> servidor oficial {HCR_BACKEND_ADDR}");
    crate::relay::copy_bidirectional(&mut socket, &mut hcr).await?;
    Ok(())
}

async fn transfer_data(
    read_stream: Arc<Mutex<tokio::net::tcp::OwnedReadHalf>>,
    write_stream: Arc<Mutex<tokio::net::tcp::OwnedWriteHalf>>,
) -> Result<()> {
    let mut buffer = [0; 32768];
    loop {
        let bytes_read = {
            let mut read_guard = read_stream.lock().await;
            read_guard.read(&mut buffer).await?
        };
        if bytes_read == 0 {
            break;
        }
        let mut write_guard = write_stream.lock().await;
        write_guard.write_all(&buffer[..bytes_read]).await?;
    }
    Ok(())
}
