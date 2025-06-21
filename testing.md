# Script Testing Guide

## On the Host (Windows/macOS/Linux)

Start a local HTTP server to serve your script directory:

```bash
python -m http.server 8080
```

This serves the current folder over `http://<your-ip>:8080/`

## On the Arch Live ISO (VM)

Run the installer script directly from the host:

```bash
curl http://<host-ip>:8080/install.sh | bash -s -- --url http://<host-ip>:8080
```

> Replace `<host-ip>` with the IP address of your host machine
> Example: `192.168.1.45`
