# Multiple remote destinations

Some users want to upload to multiple remote destinations when backing up.

You can do this by setting the following environment variables.

<br>



## Usage

> **Don't forget to add the new Rclone remote before running with the new environment variables.**
> 
> Document [here](https://github.com/ttionya/vaultwarden-backup#configure-rclone-%EF%B8%8F-must-read-%EF%B8%8F).

Set additional remote destinations via environment variables `RCLONE_REMOTE_NAME_N` and `RCLONE_REMOTE_DIR_N`.

Note:

- `N` is the serial number, which is a number
- `N` starts from 1 and is consecutive, e.g. 1 2 3 4 5 ...
- `RCLONE_REMOTE_NAME_N` and `RCLONE_REMOTE_DIR_N` cannot be empty

The script will break parsing of environment variables for remote destinations where the serial number is not consecutive or the value is empty.

<br>



#### Example

```yml
...
environment:
  # they have default values
  # RCLONE_REMOTE_NAME: BitwardenBackup
  # RCLONE_REMOTE_DIR: /BitwardenBackup/
  RCLONE_REMOTE_NAME_1: extraRemoteName1
  RCLONE_REMOTE_DIR_1: extraRemoteDir1
...
```

Both remote destinations are available, they are `BitwardenBackup:/BitwardenBackup/` and `extraRemoteName1:extraRemoteDir1`.

<br>

```yml
...
environment:
  RCLONE_REMOTE_NAME: remoteName
  RCLONE_REMOTE_DIR: remoteDir
  RCLONE_REMOTE_NAME_1: extraRemoteName1
  RCLONE_REMOTE_DIR_1: extraRemoteDir1
  RCLONE_REMOTE_NAME_2: extraRemoteName2
  RCLONE_REMOTE_DIR_2: extraRemoteDir2
  RCLONE_REMOTE_NAME_3: extraRemoteName3
  RCLONE_REMOTE_DIR_3: extraRemoteDir3
  RCLONE_REMOTE_NAME_4: extraRemoteName4
  RCLONE_REMOTE_DIR_4: extraRemoteDir4
...
```

All 5 remote destinations are available.

<br>

```yml
...
environment:
  RCLONE_REMOTE_NAME: remoteName
  RCLONE_REMOTE_DIR: remoteDir
  RCLONE_REMOTE_NAME_1: extraRemoteName1
  RCLONE_REMOTE_DIR_1: extraRemoteDir1
  RCLONE_REMOTE_NAME_2: extraRemoteName2
  # RCLONE_REMOTE_DIR_2: extraRemoteDir2
  RCLONE_REMOTE_NAME_3: extraRemoteName3
  RCLONE_REMOTE_DIR_3: extraRemoteDir3
  RCLONE_REMOTE_NAME_4: extraRemoteName4
  RCLONE_REMOTE_DIR_4: extraRemoteDir4
...
```

`RCLONE_REMOTE_DIR_2` is not defined, so only the remote destination before it is available. They are `remoteName:remoteDir` and `extraRemoteName1:extraRemoteDir1`.

<br>



## Notification

- success: **all** remote destinations were uploaded successfully
- failure: **any** of the remote destinations failed to upload
