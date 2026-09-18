$log = "d:\mes\mes\docker\backend\logs\yudao-server.log"
Select-String -Path $log -Pattern "tenant/simple-list" | Select-Object -Last 10
Select-String -Path $log -Pattern "tenant/get-by-website" | Select-Object -Last 10
