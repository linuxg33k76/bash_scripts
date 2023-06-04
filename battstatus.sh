#!/usr/bin/env bash

# Get battery status

echo
echo "********************"
echo "RTC Battery status: "
echo "********************"
echo
cat /proc/driver/rtc | grep --regexp='rtc_' --regexp='batt_status'
echo
echo "*********************"
echo "ACPI Battery status: "
echo "*********************"
echo
acpi -V | grep --regexp="Battery" --regex="Thermal"
echo
echo "*********************"
echo
exit