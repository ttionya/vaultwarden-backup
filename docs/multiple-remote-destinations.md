# Multiple remote destinations

Some users want to upload their backups to multiple remote destinations.

You can achieve this by setting the following environment variables.

<br>



## Usage

> **Don't forget to add the new Rclone remote before running with the new environment variables.**
> 
> Find more information on how to configure Rclone [here](https://github.com/ttionya/vaultwarden-backup#configure-rclone-%EF%B8%8F-must-read-%EF%B8%8F).

To set additional remote destinations, use the environment variables `RCLONE_REMOTE_NAME_N` and `RCLONE_REMOTE_DIR_N`, where:

- `N` is a serial number, starting from 1 and increasing consecutively for each additional destination
- `RCLONE_REMOTE_NAME_N` and `RCLONE_REMOTE_DIR_N` cannot be empty

Note that if the serial number is not consecutive or the value is empty, the script will break parsing the environment variables for remote destinations.

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

With the above example, both remote destinations are available: `BitwardenBackup:/BitwardenBackup/` and `extraRemoteName1:extraRemoteDir1`.

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

With the above example, all 5 remote destinations are available.

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

With the above example, only the remote destinations before `RCLONE_REMOTE_DIR_2` are available: `remoteName:remoteDir` and `extraRemoteName1:extraRemoteDir1`.

<br>



## Notification

- success: **all** remote destinations were uploaded successfully
- failure: **any** of the remote destinations failed to upload
