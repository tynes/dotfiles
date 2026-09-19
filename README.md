# My Dotfiles

These are my personal dotfiles for setting up a consistent development environment across different machines. They are opinionated and tailored to my workflow, but feel free to use them as a reference or starting point for your own setup.

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/tynes/dotfiles.git ~/dotfiles
   ```
2. Run the setup script:
   ```bash
   cd ~/dotfiles
   ./setup.sh
   ```

The setup script will back up your existing dotfiles to `/tmp/dotfile_backup` and then create symlinks to the files in this repository.

## Installing packages

`setup.sh` only creates symlinks; it assumes the tools already exist. To install
them, run:

```bash
./install.sh
```

It detects macOS (Homebrew) or Debian/Ubuntu (apt) and installs the same set of
tools on either, falling back to GitHub releases or official install scripts for
anything the package manager ships too old. It is idempotent -- re-run it to pick
up newly added tools.

## Remote access

Plain `ssh` is configured in `config/ssh/config` (symlinked to `~/.ssh/config`),
which hardens the defaults and pulls in per-machine host entries from
`~/.ssh/config.d/*.conf` -- that directory is untracked on purpose, so host names
and addresses stay out of git. A host entry there is all mosh needs too, since
it shells out to `ssh` for the handshake:

```
# ~/.ssh/config.d/myserver.conf
Host myserver
    HostName 203.0.113.10
    User tynes
    IdentityFile ~/.ssh/id_ed25519
```

For anything longer than a quick command, use [mosh](https://mosh.org) instead.
It survives roaming between networks, a closed laptop lid, and links bad enough
to make ssh unusable, and it echoes your keystrokes locally so typing does not
lag on a high-latency connection.

```bash
moshx myserver           # connect, attaching tmux session "main"
moshx myserver scratch   # ... or a session named "scratch"
```

`moshx` (defined in `.bash/init.sh`) wraps `mosh` with the UDP port range from
`$MOSH_PORTS` and drops you into `tmux new-session -A`. The tmux part matters:
mosh keeps no scrollback of its own, and a `mosh-server` that dies takes the
session with it. Host names tab-complete from `~/.ssh/config` and the tailnet.

### Setting up a server

There is no mosh daemon to configure. The `mosh` client sshs in, runs
`mosh-server` for that one session, and then talks to it directly over UDP --
so authentication is just your existing ssh setup. Two things are needed on the
server:

1. **The package**: `./install.sh` (or `sudo apt install -y mosh`). The one
   package provides both the client and `mosh-server`.
2. **An open UDP port**, one per concurrent session. `bin/firewall-setup`
   installs a small ufw ruleset for this -- ssh, http, the mosh range, and
   Tailscale's direct-connection port:

   ```bash
   firewall-setup            # install/reconcile rules, leave ufw as-is
   firewall-setup --enable   # ... and turn the firewall on
   ```

   Run `--enable` only with a second ssh session open as a lifeline. If the
   server sits behind a cloud firewall (Hetzner, security groups), that is a
   separate layer and needs the same UDP range opened there too -- the symptom
   is an ssh handshake that succeeds followed by a session that never starts.

Keep `$MOSH_PORTS` in `.bash/init.sh` and `MOSH_PORT_RANGE` in
`bin/firewall-setup` in sync; they are two halves of the same decision.

### What mosh will not do

Mosh only does interactive shells. It has no port forwarding, no agent
forwarding, no X11 forwarding, and no `scp`/`sftp`. Keep using `ssh` for those.

## Compatibility

These dotfiles are tested and known to work on macOS (using `homebrew`)
and sort of debian. arch linux support planned for the future.
Apple silicon is just too good unfortunately.
