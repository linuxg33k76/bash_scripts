sudo umount ~/remote_backup
if [ $? -eq 0 ]; then
   echo "Remote SAMBA share Successfully unmounted!"
else
   echo "Remote SAMBA share FAILED to unmount!"
fi

