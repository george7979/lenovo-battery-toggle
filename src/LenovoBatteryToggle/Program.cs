using System;
using System.Threading;
using System.Windows.Forms;

namespace LenovoBatteryToggle
{
    internal static class Program
    {
        [STAThread]
        private static int Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);

            // A second key press while the first toggle is still running would flip the state back
            using (var mutex = new Mutex(true, @"Local\LenovoBatteryToggle", out bool isFirst))
            {
                if (!isFirst) return 0;
                try
                {
                    Notification.Show(Toggle(), isError: false);
                    return 0;
                }
                catch (Exception ex)
                {
                    Notification.Show(Text.Error + ex.Message, isError: true);
                    return 1;
                }
            }
        }

        private static string Toggle()
        {
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
    }
}
