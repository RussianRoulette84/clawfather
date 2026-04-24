- do 'clawfather' build
- 'node user' with fourplayers needed: When you select this image, Root Mode is **auto-enabled** and **hidden** from the Security checklist (the image requires root for its entrypoint). You see one fewer security toggle.
- I think Sandbox mode is not working :)
- SSH?
- TLS / HTTPS?
- dont set default values again for gateway (port, etc)
- test all docker images [tested: 2/5]
  - fix commands for fourplayers/openclaw, test more
- test on Linux (should work)
- Start Docker -> No -> Continue setup next time
- now that pairing works -> maybe we dont need the allowInsecure + reboot hack?
- test other options in wizzard (remote gateway, tailsafe, loopback, etc)
- auto security check skills as post install step
- remove the bundled skills that comes with openclaw!!! Heard of Twitter incident?
- NEW: allow to select/deselect my selected skills to install inside wizzard
- move 'ywizz' library to a separate repo
- add 'docs' reader inside wizzard. Or Deepwiki?
- build openclaw from source option using Dockerfile?

enable this at "applying config stage"
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "boot-md": {
          "enabled": true
        },
        "bootstrap-extra-files": {
          "enabled": true
        },
        "command-logger": {
          "enabled": true
        },
        "session-memory": {
          "enabled": true
        }
      }
    }
  },