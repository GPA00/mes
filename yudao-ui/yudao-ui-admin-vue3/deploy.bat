@echo off
chcp 65001 >nul
echo =======================================
echo 1. 姝ｅ湪缂栬瘧鎵撳寘 Vue 椤圭洰...
echo =======================================
call pnpm install
call pnpm run build:prod

echo.
echo =======================================
echo 2. 姝ｅ湪鍋滄骞跺垹闄ゆ棫鐨?Docker 瀹瑰櫒...
echo =======================================
docker stop yudao-ui-admin >nul 2>nul
docker rm yudao-ui-admin >nul 2>nul

echo.
echo =======================================
echo 3. 姝ｅ湪鏋勫缓鏂扮殑 Docker 闀滃儚...
echo =======================================
docker build -t yudao-ui-admin:latest .

echo.
echo =======================================
echo 4. 姝ｅ湪杩愯鏂扮殑 Docker 瀹瑰櫒...
echo =======================================
docker run -d -p 80:80 --name yudao-ui-admin yudao-ui-admin:latest

echo.
echo =======================================
echo 閮ㄧ讲瀹屾垚锛佽鍦ㄦ祻瑙堝櫒璁块棶 http://localhost
echo =======================================
pause