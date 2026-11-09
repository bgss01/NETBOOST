@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
title NETBOOST CMD - Network Optimizer

:: Cek hak Administrator, kalau belum maka minta naik hak otomatis
net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo.
    echo [!] Program perlu hak Administrator. Menampilkan permintaan izin...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:MENU
cls
echo ======================================================
echo               NETBOOST CMD BY BAGUS
echo       Optimasi dan Diagnostik Jaringan Windows
echo ======================================================
echo.
echo  [1] Lihat status jaringan dan adapter
echo  [2] Bersihkan DNS cache
echo  [3] Ganti DNS ke Cloudflare (1.1.1.1 / 1.0.0.1)
echo  [4] Kembalikan DNS ke otomatis (DHCP)
echo  [5] Renew IP (putus koneksi sementara)
echo  [6] Optimasi TCP Windows (autotuning normal)
echo  [7] Reset Winsock dan TCP/IP (perlu restart)
echo  [8] Tes koneksi internet dan latency
echo  [9] Lihat nama adapter jaringan
echo  [0] Keluar
echo.
set "choice="
set /p "choice=Pilih menu: "
if "%choice%"=="1" goto STATUS
if "%choice%"=="2" goto FLUSHDNS
if "%choice%"=="3" goto SETDNS
if "%choice%"=="4" goto AUTODNS
if "%choice%"=="5" goto RENEW
if "%choice%"=="6" goto TCP
if "%choice%"=="7" goto RESET
if "%choice%"=="8" goto TEST
if "%choice%"=="9" goto ADAPTER
if "%choice%"=="0" exit /b
echo Pilihan tidak valid.
timeout /t 2 >nul
goto MENU

:STATUS
cls
echo === STATUS IP DAN ADAPTER ===
ipconfig /all
echo.
netsh interface show interface
echo.
pause
goto MENU

:FLUSHDNS
cls
echo Membersihkan cache DNS...
ipconfig /flushdns
echo.
echo Selesai. Ini dapat membantu jika DNS menyimpan alamat lama.
pause
goto MENU

:SETDNS
cls
echo === DAFTAR ADAPTER ===
netsh interface show interface
echo.
echo Masukkan nama adapter persis seperti yang tampil, misalnya Wi-Fi atau Ethernet.
set "adapter="
set /p "adapter=Nama adapter: "
if not defined adapter goto MENU
echo.
echo Mengatur DNS Cloudflare untuk "%adapter%"...
netsh interface ipv4 set dnsservers name="%adapter%" static 1.1.1.1 primary
if errorlevel 1 goto DNSFAIL
netsh interface ipv4 add dnsservers name="%adapter%" 1.0.0.1 index=2
if errorlevel 1 goto DNSFAIL
ipconfig /flushdns
echo.
echo DNS Cloudflare berhasil diterapkan pada adapter "%adapter%".
echo Catatan: DNS dapat mempercepat pencarian alamat situs, bukan menambah bandwidth.
pause
goto MENU

:DNSFAIL
echo.
echo Gagal mengatur DNS. Periksa nama adapter dan pastikan adapter tersedia.
pause
goto MENU

:AUTODNS
cls
echo === DAFTAR ADAPTER ===
netsh interface show interface
echo.
echo Masukkan nama adapter persis seperti yang tampil, misalnya Wi-Fi atau Ethernet.
set "adapter="
set /p "adapter=Nama adapter: "
if not defined adapter goto MENU
netsh interface ipv4 set dnsservers name="%adapter%" source=dhcp
if errorlevel 1 (
    echo Gagal. Periksa nama adapter.
) else (
    echo DNS adapter "%adapter%" dikembalikan ke otomatis ^(DHCP^).
)
pause
goto MENU

:RENEW
cls
echo Perhatian: koneksi akan terputus sementara saat IP diperbarui.
set "confirm="
set /p "confirm=Lanjutkan? (Y/N): "
if /i not "%confirm%"=="Y" goto MENU
ipconfig /release
ipconfig /renew
echo.
echo Proses selesai.
pause
goto MENU

:TCP
cls
echo Mengatur TCP Receive Window Auto-Tuning ke normal...
netsh interface tcp set global autotuninglevel=normal
echo.
echo Selesai. Pengaturan ini mengembalikan fitur TCP Windows ke nilai normal.
pause
goto MENU

:RESET
cls
echo PERINGATAN: reset dapat menghapus konfigurasi jaringan tertentu.
echo Restart Windows diperlukan setelah proses ini.
set "confirm="
set /p "confirm=Ketik YES untuk melanjutkan: "
if not "%confirm%"=="YES" goto MENU
netsh winsock reset
netsh int ip reset
echo.
echo Reset selesai. Restart komputer agar perubahan diterapkan.
pause
goto MENU

:TEST
cls
set "gateway="
for /f %%G in ('powershell -NoProfile -Command "(Get-NetRoute -DestinationPrefix 0.0.0.0/0 | Sort-Object RouteMetric | Select-Object -First 1).NextHop"') do set "gateway=%%G"
echo === TES GATEWAY DEFAULT ===
if defined gateway (
    echo Gateway: !gateway!
    ping -n 4 !gateway!
) else (
    echo Gateway tidak ditemukan. Periksa koneksi adapter.
)
echo.
echo === TES INTERNET (1.1.1.1) ===
ping -n 4 1.1.1.1
echo.
echo === TES DNS (cloudflare.com) ===
ping -n 4 cloudflare.com
echo.
echo Catatan: ping diblokir oleh sebagian jaringan atau server. Hasil Request timed out tidak selalu berarti internet mati.
pause
goto MENU

:ADAPTER
cls
echo === NAMA ADAPTER JARINGAN ===
netsh interface show interface
echo.
echo Gunakan nama pada kolom Interface Name saat memilih DNS.
pause
goto MENU
