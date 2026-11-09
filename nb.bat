@echo off
setlocal EnableExtensions EnableDelayedExpansion
chcp 65001 >nul
for /f %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "GREEN=%ESC%[92m"
set "YELLOW=%ESC%[93m"
set "RED=%ESC%[91m"
set "CYAN=%ESC%[96m"
set "GRAY=%ESC%[90m"
set "RESET=%ESC%[0m"
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
echo               %GREEN%NETBOOST CMD BY BAGUS
echo       Optimasi dan Diagnostik Jaringan Windows%RESET%
echo ======================================================
echo.
echo  %CYAN%[1]%RESET% Lihat status jaringan dan adapter
echo  %CYAN%[2]%RESET% Bersihkan DNS cache
echo  %CYAN%[3]%RESET% Ganti DNS ke Cloudflare (1.1.1.1 / 1.0.0.1)
echo  %CYAN%[4]%RESET% Kembalikan DNS ke otomatis (DHCP)
echo  %CYAN%[5]%RESET% Renew IP (putus koneksi sementara)
echo  %CYAN%[6]%RESET% Optimasi TCP Windows (autotuning normal)
echo  %CYAN%[7]%RESET% Reset Winsock dan TCP/IP (perlu restart)
echo  %CYAN%[8]%RESET% Tes koneksi internet dan latency
echo  %CYAN%[9]%RESET% Lihat nama adapter jaringan
echo  %CYAN%[10]%RESET% Melihat status IP yang sedang aktif (Ping Sweep)
echo  %CYAN%[0]%RESET% Keluar
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
if "%choice%"=="10" goto SCAN
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

:SCAN
cls
echo %CYAN%=== SCAN PERANGKAT AKTIF ^(PING SWEEP^) ===%RESET%
echo.
set "prefix="
set /p "prefix=Tiga angka pertama IP (Enter = 192.168.88): "
if not defined prefix set "prefix=192.168.88"
echo.
echo Memindai %prefix%.1 sampai %prefix%.254, mohon tunggu...
echo.
for /L %%i in (1,1,254) do @ping -n 1 -w 100 %prefix%.%%i | find "TTL="
echo.
echo %GREEN%Scan selesai.%RESET%
echo %YELLOW%Catatan: perangkat dengan firewall yang memblokir ping tidak akan muncul.%RESET%
pause
goto MENU
