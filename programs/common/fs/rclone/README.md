## Usages

- [rclone configure](https://rclone.org/docs/#configure)
- [rclone bisync](https://rclone.org/bisync)

```sh
rclone listremotes
rclone lsd gdrive:
rclone lsd gdrive:Sync/Config/Darwin
rclone lsl gdrive:Sync/Config/Darwin/path/to/dir

# `--resync` is important, have add it when first run this command, otherwise it will throw error
rclone bisync ${local_path} ${remote_path} --filter-from ${filter_path} --create-empty-src-dirs --compare size,modtime,checksum --slow-hash-sync-only --drive-skip-gdocs --fix-case --log-file /tmp/rclone.log --resync
```
