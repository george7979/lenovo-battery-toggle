using System;
using System.Runtime.InteropServices;
using System.Security.Principal;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Tells whether the process runs on the elevated half of a split UAC token. The Lenovo tool
    /// lives in the user's profile, which the same user's unelevated processes can write to, so
    /// starting it from an elevated process would hand them administrator rights.
    /// Without UAC (or for the built-in Administrator) there is no such boundary to protect.
    /// </summary>
    internal static class Elevation
    {
        public static bool IsElevated
        {
            get
            {
                using (var identity = WindowsIdentity.GetCurrent())
                {
                    var size = Marshal.SizeOf(typeof(int));
                    var buffer = Marshal.AllocHGlobal(size);
                    try
                    {
                        // When the token cannot be read, assume the worst
                        if (!GetTokenInformation(identity.Token, TokenElevationType, buffer, size, out _)) return true;
                        return Marshal.ReadInt32(buffer) == TokenElevationTypeFull;
                    }
                    finally
                    {
                        Marshal.FreeHGlobal(buffer);
                    }
                }
            }
        }

        private const int TokenElevationType = 18;
        private const int TokenElevationTypeFull = 2;

        [DllImport("advapi32.dll", SetLastError = true)]
        private static extern bool GetTokenInformation(IntPtr token, int infoClass, IntPtr info, int length, out int returnLength);
    }
}
