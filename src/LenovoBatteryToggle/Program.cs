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
        private const int ToolUnavailable = 3;

        /// <summary>
        /// No arguments: toggle thresholds and show the result.
        /// --prepare [start stop]: check the driver, write the given (or default) settings,
        ///   download the Lenovo tool; no UI, no toggle. Exit 0 OK, 1 failed, 2 driver missing,
        ///   3 ChargeThreshold.exe not obtained.
        /// --install-tool: download ChargeThreshold.exe next to the app (used by an elevated
        ///   all-users setup). Exit 0 OK, 1 failed, 3 not obtained.
        /// --off: switch thresholds off silently (used by the uninstaller).
        /// --settings: window for the start/stop values (used by the settings shortcut).
        /// </summary>
        [STAThread]
        private static int Main(string[] args)
        {
            var mode = args.Length > 0 ? args[0].ToLowerInvariant() : "";
            if (mode == "--prepare") return Prepare(args);
            if (mode == "--install-tool") return InstallTool();
            if (mode == "--off") return TurnOffQuietly();

            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            if (mode == "--settings")
            {
                // Modal, so the Cancel button and Esc close it through DialogResult
                using (var form = new SettingsForm(Settings.LoadOrDefault())) form.ShowDialog();
                return Ok;
            }

            // A second key press while the first toggle is still running would flip the state back
            using (var mutex = new Mutex(true, @"Local\LenovoBatteryToggle", out bool isFirst))
            {
                if (!isFirst) return Ok;
                try
                {
                    var message = Toggle(out var seconds);
                    Notification.Show(message, isError: false, seconds);
                    return Ok;
                }
                catch (ToolUnavailableException ex)
                {
                    // Needs action (a manual download), so a dialog that stays and can be copied
                    // with Ctrl+C, not a notification that closes before the URL can be read
                    MessageBox.Show(ex.Message, "Lenovo Battery Toggle", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return Failed;
                }
                catch (Exception ex)
                {
                    Notification.Show(Text.Error + ex.Message, isError: true);
                    return Failed;
                }
            }
        }

        private static string Toggle(out int seconds)
        {
            if (!PowerDriver.IsInstalled()) throw new InvalidOperationException(Text.DriverMissing);
            var settings = Settings.Load();
            seconds = settings.NotificationSeconds;
            var tool = ChargeThresholdTool.Ensure();

            var before = tool.Status();
            if (before.IsOff) tool.TurnOn(settings.Stop, settings.Start);
            else tool.TurnOff();

            // The message reflects the state read back after the change, not the intent
            var after = tool.Status();
            if (after.IsOff) return Text.TurnedOff;
            return Text.TurnedOn(after.Start, after.Stop);
        }

        private static int Prepare(string[] args)
        {
            // The installer passes the wizard values; it runs this as the signed-in user, so the
            // settings land in that user's profile even when setup itself is elevated
            try
            {
                if (args.Length >= 3) Settings.Save(int.Parse(args[1]), int.Parse(args[2]));
            }
            catch (Exception)
            {
                return Failed;
            }

            if (!PowerDriver.IsInstalled()) return DriverMissing;
            try
            {
                Settings.Load();
                ChargeThresholdTool.Ensure();
                return Ok;
            }
            catch (ToolUnavailableException)
            {
                // The installer explains how to get the file by hand
                return ToolUnavailable;
            }
            catch (Exception)
            {
                // The first toggle retries and reports the reason
                return Failed;
            }
        }

        private static int InstallTool()
        {
            // Setup goes on either way; without this copy --prepare falls back to the user's copy
            try
            {
                ChargeThresholdTool.InstallProtected();
                return Ok;
            }
            catch (ToolUnavailableException)
            {
                return ToolUnavailable;
            }
            catch (Exception)
            {
                return Failed;
            }
        }

        private static int TurnOffQuietly()
        {
            // Leaves the battery at its factory behaviour; never downloads anything. An elevated
            // (all-users) uninstaller gets only the protected copy next to the app
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
