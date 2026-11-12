# 手動觸發備份

有時需要手動觸發備份操作。

當你使用其他程式來定時排程任務，或想驗證環境變數是否正確設定時，這個功能會很有用。

如果你的容器已經運行（容器名為 `vaultwarden_backup`），並且你想執行一次臨時備份，可以使用指令 `docker exec vaultwarden_backup bash /app/backup.sh`。

<br>



## 使用方法

以前執行一次立即備份需要覆寫映像的 entrypoint。現在有了新的方式，你可以直接使用一個無參數的指令來執行備份。

```shell
docker run \
  --rm \
  --name vaultwarden_backup \
  --volumes-from=vaultwarden \
  --mount type=volume,source=vaultwarden-rclone-data,target=/config/ \
  -e ... \
  ttionya/vaultwarden-backup:latest backup
```

你同樣需要掛載 rclone 設定檔並設定環境變數。

唯一的差別是環境變數 `CRON` 不會生效，因為它不會啟動 CRON 程式，而是在備份完成後結束容器。

<br>



## 重要

**手動觸發備份只能驗證環境變數是否設定正確，不能驗證 CRON 是否正常運作。這是一個 CRON 在 ARM 裝置上可能無法正常運作的 [issue](https://github.com/ttionya/vaultwarden-backup/issues/53)。**
