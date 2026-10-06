using System;
using System.Management;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Detects the Lenovo Power and Battery driver (PowerMgr), which ChargeThreshold.exe needs.
    /// Windows Update installs it on ThinkPads; Lenovo Vantage is not required.
    /// </summary>
    internal static class PowerDriver
    {
        public static bool IsInstalled()
        {
            try
            {
                using (var searcher = new ManagementObjectSearcher(
                    "SELECT Status FROM Win32_PnPEntity WHERE DeviceID LIKE '%POWERMGR_COMPONENT%'"))
                {
                    foreach (ManagementObject device in searcher.Get())
                        using (device)
                            if ((string)device["Status"] == "OK") return true;
                }
            }
            catch (ManagementException)
            {
                // WMI unavailable: let ChargeThreshold.exe report the problem
                return true;
            }
            return false;
        }
    }
}
