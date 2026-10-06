using System;
using System.Threading;
using System.Windows.Forms;

namespace LenovoBatteryToggle
{
    internal static class Program
    {
        // Exit codes of --prepare, read by the installer
        private const int Ok = 0;
        private const int Failed = 1;
        private const int DriverMissing = 2;

        /// <summary>
        /// No arguments: toggle thresholds and show the result.
        /// --prepare: check the driver, write default settings, download the Lenovo tool; no UI, no toggle.
        /// --off: switch thresholds off silently (used by the uninstaller).
        /// </summary>
        [STAThread]
        private static int Main(string[] args)
        {
            var mode = args.Length > 0 ? args[0].ToLowerInvariant() : "";
            if (mode == "--prepare") return Prepare();
            if (mode == "--off") return TurnOffQuietly();

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // A second key press while the first toggle is still running would flip the state back
            using (var mutex = new Mutex(true, @"Local\LenovoBatteryToggle", out bool isFirst))
            {
                if (!isFirst) return Ok;
                try
                {
                    Notification.Show(Toggle(), isError: false);
                    return Ok;
                }
                catch (Exception ex)
                {
                    Notification.Show(Text.Error + ex.Message, isError: true);
                    return Failed;
                }
            }
        }

        private static string Toggle()
        {
            if (!PowerDriver.IsInstalled()) throw new InvalidOperationException(Text.DriverMissing);
            var settings = Settings.Load();
            var tool = ChargeThresholdTool.Ensure();

            var before = tool.Status();
            if (before.IsOff) tool.TurnOn(settings.Stop, settings.Start);
            else tool.TurnOff();

            // The message reflects the state read back after the change, not the intent
            var after = tool.Status();
            if (after.IsOff) return Text.TurnedOff;
            return Text.TurnedOn(after.Start, after.Stop);
        }

        private static int Prepare()
        {
            if (!PowerDriver.IsInstalled()) return DriverMissing;
            try
            {
                Settings.Load();
                ChargeThresholdTool.Ensure();
                return Ok;
            }
            catch (Exception)
            {
                // The first toggle retries and reports the reason
                return Failed;
            }
        }

        private static int TurnOffQuietly()
        {
            // Leaves the battery at its factory behaviour; never downloads anything
            try
            {
                var tool = ChargeThresholdTool.Existing();
                if (tool != null && PowerDriver.IsInstalled() && !tool.Status().IsOff) tool.TurnOff();
            }
            catch (Exception)
            {
                // Uninstall must go on even if the driver is gone
            }
            return Ok;
        }
    }
}
