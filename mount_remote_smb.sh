sudo mount -t cifs -o credentials=~/config/samba_creds //192.168.1.90/backups/GalagoPro5 /home/linuxg33k/remote_backup/
if [ $?  -eq 0 ]; then
   echo "Remote SAMBA share connected successfully"
else
   echo "Remote SAMBA share connection FAILED!"
fi
