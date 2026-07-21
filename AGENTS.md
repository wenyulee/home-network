# AGENTS.md

## Cursor Cloud specific instructions

### What this repo is (and is NOT)
This is a **configuration/documentation backup** for a dual-router home network (Clash / OpenClash / Mihomo customizations). See `README.md`, `docs/topology.md`, and each router's `README.md`. There is **no application to build, serve, or long-running service to start** — nothing listens on a port in this environment. The shell scripts and YAML fragments are deployed manually onto physical routers over SSH; the IPs/ports in the docs (`192.168.50.1`, `:9999`, `:7890`, `192.168.8.1`, `:9090`) are on-device, not reachable from the VM.

### Tooling used for dev-time validation
- `dash` — POSIX syntax check of shell scripts.
- `shellcheck` — lint (use `-s dash` since scripts target BusyBox `ash`/`sh`).
- `ruby` — required to run the Router B OpenClash overwrite (`router-b-gl-mt3000/custom/openclash_custom_overwrite.sh`), whose core is an embedded `ruby -ryaml` block.
- `python3` + `pyyaml` (preinstalled) — validate YAML fragments.

`ruby` and `shellcheck` are installed by the update script; the rest are preinstalled.

### Lint / validate commands
- Syntax: `dash -n <script>` (all three scripts pass).
- Lint: `shellcheck -s dash router-a-asus-merlin/custom/post_sub_clean.sh router-a-asus-merlin/custom/wan-start router-b-gl-mt3000/custom/openclash_custom_overwrite.sh` — reports only pre-existing info/style notes, no errors.
- YAML: `python3 -c "import sys,yaml; yaml.safe_load(open(sys.argv[1]))" <file>`.

### Running the scripts locally (gotchas)
- `openclash_custom_overwrite.sh` sources OpenClash system files that don't exist on the VM: `/usr/share/openclash/log.sh`, `/usr/share/openclash/ruby.sh`, `/lib/functions.sh`. To run it unmodified, create minimal stubs at those paths first (only `LOG_TIP()` is actually needed). Then invoke it with a config path as `$1`; it transforms the file in place (strips fake `Expire:`/`Traffic:` nodes, injects the `via-RouterA` socks5 proxy, adds the `gmail-out` fallback group, hardens DNS, pins Firstrade hosts, and prepends Firstrade-DIRECT / Gmail-SMTP rules). Always run it on a **throwaway copy** outside the repo.
- `post_sub_clean.sh` (Router A) cannot fully run on the VM: it calls the Mihomo `CrashCore -t` binary and reads on-device paths (`/jffs/...`, `/tmp/mnt/sda1`). Its awk/sed transforms can be inspected, but a full end-to-end run requires the mihomo core.
- `wan-start` sets Asuswrt `nvram` and writes `/tmp/resolv.*`; **do not run it on the VM** — it is only meaningful on the router.

### Secrets
Committed files contain the placeholder `REDACTED_MIXED_AUTH` (and `secrets.example` has `change-me`); real mixed-port auth lives only on the routers. No secrets are needed for local lint/validate/transform demos.
