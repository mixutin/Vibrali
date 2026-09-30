# Persistent USB

Vibrali targets Debian Live persistence.

A typical USB contains the live image and a second ext4 partition labeled
`persistence`. At the root of that partition create `persistence.conf` containing:

```text
/ union
```

This requests a persistent overlay for the live filesystem.

## Safety

Partitioning or flashing the wrong block device can permanently destroy data. Verify the
target device by model, size and serial number before changing it.

## Encryption

Encrypted persistence is planned but is not enabled by the starter configuration yet.
Treat an unencrypted persistent USB as sensitive.

## Recovery

If persistence is damaged, boot without the `persistence` kernel option. The underlying
live image should remain usable.
