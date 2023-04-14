# Improvements to PureVPN Linux CLI installation script

* custom base dir via `PUREVPN_BASE_DIR` env var
* centralize file installation under `$PUREVPN_BASE_DIR/pure-linux`
* separate bin/log dirs
* stop pured service before disabling/removing systemd file
* output proper PATH modification help

## Limitations

* Currently something (either CLI or daemon app probably) hard codes the paths for `atom-update-resolve-conf` and `atom-update-resolve-conf-wg`, so those files need to be copied back to the original `/tmp` directory location until that issue is corrected.
