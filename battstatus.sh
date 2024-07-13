#!/usr/bin/env bash
# Author: Ben Calvert - 04 June 2023

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
# if command acpi is not found, echo message and exit
if ! command -v acpi &> /dev/null
then
    echo "acpi is not installed. Please install acpi and try again."
    exit
else
    acpi -V | grep --regexp="Battery" --regex="Thermal"
fi
echo
echo "*********************"
echo
exit