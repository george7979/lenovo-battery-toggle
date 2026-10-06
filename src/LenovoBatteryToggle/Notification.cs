using System.Drawing;
using System.Windows.Forms;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Borderless message in the bottom-right corner, closed by a timer, not by the user.
    /// It never takes focus, so the key press does not interrupt the active window.
    /// </summary>
    internal sealed class Notification : Form
    {
        private const int ScreenMargin = 24;

        private Notification(string text, bool isError)
        {
            FormBorderStyle = FormBorderStyle.None;
            StartPosition = FormStartPosition.Manual;
            TopMost = true;
            ShowInTaskbar = false;
            AutoSize = true;
            AutoSizeMode = AutoSizeMode.GrowAndShrink;
            BackColor = isError ? Color.FromArgb(160, 30, 30) : Color.FromArgb(32, 32, 32);

            Controls.Add(new Label
            {
                Text = text,
                ForeColor = Color.White,
                Font = new Font("Segoe UI", 12f),
                AutoSize = true,
                MaximumSize = new Size(520, 0),
                Padding = new Padding(18, 14, 18, 14),
            });

            var timer = new Timer { Interval = isError ? 6000 : 4000 };
            timer.Tick += (sender, args) => { timer.Stop(); Close(); };
            Load += (sender, args) =>
            {
                var area = Screen.PrimaryScreen.WorkingArea;
                Location = new Point(area.Right - Width - ScreenMargin, area.Bottom - Height - ScreenMargin);
                timer.Start();
            };
        }

        protected override bool ShowWithoutActivation => true;

        protected override CreateParams CreateParams
        {
            get
            {
                const int WS_EX_TOOLWINDOW = 0x80;
                const int WS_EX_NOACTIVATE = 0x08000000;
                var parameters = base.CreateParams;
                parameters.ExStyle |= WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
                return parameters;
            }
        }

        public static void Show(string text, bool isError) => Application.Run(new Notification(text, isError));
    }
}
