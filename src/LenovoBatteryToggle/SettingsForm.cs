using System;
using System.Drawing;
using System.Windows.Forms;
using Msg = LenovoBatteryToggle.Text;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Window for the two threshold values, opened with --settings. Number fields only accept
    /// numbers, and Save stays disabled until start is lower than stop, so the settings file
    /// cannot be broken from here.
    /// </summary>
    internal sealed class SettingsForm : Form
    {
        private readonly NumericUpDown _start = NewField();
        private readonly NumericUpDown _stop = NewField();
        private readonly Label _hint = new Label { AutoSize = true, ForeColor = SystemColors.GrayText };
        private readonly Button _save = new Button { Text = Msg.Save, AutoSize = true, DialogResult = DialogResult.None };

        public SettingsForm(Settings settings)
        {
            Text = Msg.SettingsTitle;
            Icon = Icon.ExtractAssociatedIcon(Application.ExecutablePath);
            Font = new Font("Segoe UI", 9.75f);
            AutoScaleMode = AutoScaleMode.Dpi;
            FormBorderStyle = FormBorderStyle.FixedDialog;
            MaximizeBox = false;
            MinimizeBox = false;
            StartPosition = FormStartPosition.CenterScreen;
            AutoSize = true;
            AutoSizeMode = AutoSizeMode.GrowAndShrink;

            _start.Value = settings.Start;
            _stop.Value = settings.Stop;
            _start.ValueChanged += (sender, args) => UpdateState();
            _stop.ValueChanged += (sender, args) => UpdateState();

            var cancel = new Button { Text = Msg.Cancel, AutoSize = true, DialogResult = DialogResult.Cancel };
            _save.Click += (sender, args) => SaveAndClose();
            AcceptButton = _save;
            CancelButton = cancel;

            var layout = new TableLayoutPanel
            {
                AutoSize = true,
                AutoSizeMode = AutoSizeMode.GrowAndShrink,
                ColumnCount = 2,
                Padding = new Padding(16),
            };
            layout.Controls.Add(new Label { Text = Msg.SettingsIntro, AutoSize = true, MaximumSize = new Size(380, 0), Margin = new Padding(3, 3, 3, 12) }, 0, 0);
            layout.SetColumnSpan(layout.GetControlFromPosition(0, 0), 2);
            layout.Controls.Add(FieldLabel(Msg.StartLabel), 0, 1);
            layout.Controls.Add(_start, 1, 1);
            layout.Controls.Add(FieldLabel(Msg.StopLabel), 0, 2);
            layout.Controls.Add(_stop, 1, 2);
            layout.Controls.Add(_hint, 0, 3);
            layout.SetColumnSpan(_hint, 2);

            var buttons = new FlowLayoutPanel
            {
                AutoSize = true,
                FlowDirection = FlowDirection.RightToLeft,
                Dock = DockStyle.Fill,
                Margin = new Padding(0, 12, 0, 0),
            };
            buttons.Controls.Add(cancel);
            buttons.Controls.Add(_save);
            layout.Controls.Add(buttons, 0, 4);
            layout.SetColumnSpan(buttons, 2);

            Controls.Add(layout);
            UpdateState();
        }

        private static NumericUpDown NewField() =>
            new NumericUpDown { Minimum = 0, Maximum = 100, Width = 70, TextAlign = HorizontalAlignment.Right };

        private static Label FieldLabel(string text) =>
            new Label { Text = text, AutoSize = true, Anchor = AnchorStyles.Left, Margin = new Padding(3, 6, 12, 6) };

        private void UpdateState()
        {
            var valid = _start.Value < _stop.Value;
            _save.Enabled = valid;
            _hint.Text = valid ? Msg.SettingsApplyNow : Msg.StartBelowStop;
            _hint.ForeColor = valid ? SystemColors.GrayText : Color.FromArgb(180, 30, 30);
        }

        private void SaveAndClose()
        {
            var start = (int)_start.Value;
            var stop = (int)_stop.Value;
            Settings.Save(start, stop);

            // When thresholds are on now, apply the new values right away
            try
            {
                var tool = ChargeThresholdTool.Existing();
                if (tool != null && PowerDriver.IsInstalled() && !tool.Status().IsOff) tool.TurnOn(stop, start);
            }
            catch (Exception ex)
            {
                MessageBox.Show(this, Msg.SavedNotApplied + ex.Message, Msg.SettingsTitle, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            }
            DialogResult = DialogResult.OK;
            Close();
        }
    }
}
