# pinentry-context

Passphrase popups for GPG and SSH keys don't say *what* is asking. If a
background process or a coding agent triggers one, you either type your
passphrase blind or cancel something legitimate.

`pinentry-context` adds the requesting process chain to the popup:

```
Please enter the passphrase to unlock the OpenPGP secret key: ...

Requested from: ~/projects/some-repo
[kitty]
  └ bash  (4711)
    └ claude  (479022)
      └ git commit -m "fix typo"  (481964)
        └ gpg --status-fd=2 -bsau 0123ABCD…  (481970)
```

It is one Python file with no dependencies. It does not replace your pinentry
or askpass program; it only adds text to the prompt and hands over to them.

## Requirements

- Linux (reads `/proc`)
- Python 3
- An existing pinentry (GPG) and/or ssh-askpass program (SSH)

## Install

```sh
make install          # copies to ~/.local/bin; use PREFIX=... to change
```

This installs `pinentry-context` and a symlink to it, `ssh-askpass-context`.

### GPG

```sh
echo "pinentry-program $HOME/.local/bin/pinentry-context" >> ~/.gnupg/gpg-agent.conf
gpgconf --reload gpg-agent
```

Test (the reload above also clears cached passphrases):

```sh
echo test | gpg --clearsign >/dev/null
```

### SSH

Set `SSH_ASKPASS` where your sessions pick it up, e.g. in `~/.bashrc`:

```sh
export SSH_ASKPASS="$HOME/.local/bin/ssh-askpass-context"
```

Processes that are already running keep the old value until restarted.

Test from a new terminal, with the key not yet loaded in your agent:

```sh
setsid -w ssh -T git@github.com </dev/null
```

ssh only uses askpass when it has no terminal, which is exactly the
background/agent case. In an interactive terminal it still prompts inline.

## Configuration

Optional, in `~/.config/pinentry-context/config`:

```ini
# Real programs to hand over to. Auto-detected from common paths if unset.
pinentry = /usr/bin/pinentry-qt
askpass  = /usr/bin/ksshaskpass

# Command for "touch your security key" notices (SSH_ASKPASS_PROMPT=none).
# The message is appended as the last argument. Unset: use the askpass program.
notify = swaynag -t warning -m

# Extra process names (comma separated) where the chain should stop.
stop = myterminal
```

The chain stops at the first known terminal, multiplexer or session process, so
it shows what happened inside the terminal rather than your whole login
session.

## How it works

- **GPG:** gpg-agent starts the configured pinentry and tells it the PID of the
  client that needs the key (`OPTION owner=PID/UID host`). `pinentry-context`
  sits in front of the real pinentry, walks that PID's parents in `/proc`, and
  appends the result to the `SETDESC` line. Replies from the real pinentry go
  straight back to gpg-agent; the passphrase never passes through this script.
- **SSH:** ssh runs `$SSH_ASKPASS` as its own child, so the requester is simply
  the parent process. The wrapper appends the chain to the prompt and execs the
  real askpass.

If anything goes wrong while building the context, the prompt is passed through
unchanged.

## Limitations

- Linux only; macOS has no `/proc`.
- The PID is only meaningful on the same machine: no context for forwarded
  agents, and processes in containers or other PID namespaces show up as
  unknown or truncated.
- SSH agents with their own dialogs (gnome-keyring, KDE Wallet, 1Password) never
  call `SSH_ASKPASS`.
- The context is informational, not a security boundary: a malicious local
  process running as you can choose its own command line.

## Uninstall

Remove the `pinentry-program` line from `gpg-agent.conf`, run
`gpgconf --reload gpg-agent`, unset `SSH_ASKPASS`, then `make uninstall`.

## License

MIT
