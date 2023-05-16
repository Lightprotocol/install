# install

Script for installing Solana and Light Protocol toolchain.

Basic usage:

```bash
curl -s https://raw.githubusercontent.com/Lightprotocol/install/main/light-protocol-install.sh | bash -s
```

If you don't want any prompts:

```bash
curl -s https://raw.githubusercontent.com/Lightprotocol/install/main/light-protocol-install.sh | bash -s -- --no-prompt
```

If you want to specify your own prefix directory where binaries should be
installed:

```bash
curl -s https://raw.githubusercontent.com/Lightprotocol/install/main/light-protocol-install.sh | bash -s -- --prefix [PREFIX]
```
