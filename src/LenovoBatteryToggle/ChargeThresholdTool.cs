using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Text.RegularExpressions;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Wraps Lenovo's ChargeThreshold.exe. The tool sends the threshold to the
    /// Lenovo Power and Battery driver (PowerMgr), the same way Vantage does.
    /// </summary>
    internal sealed class ChargeThresholdTool
    {
        public const string DownloadUrl =
            "https://download.lenovo.com/pccbbs//thinkvantage_en/metroapps/Vantage/ChargeThreshold/ChargeThreshold.exe";

        public static readonly string ToolPath = Path.Combine(Settings.DataDirectory, "ChargeThreshold.exe");

        private readonly string _path;

        private ChargeThresholdTool(string path) { _path = path; }

        /// <summary>
        /// Uses the cached copy (downloaded earlier or saved there by hand), or downloads it
        /// from Lenovo. The file is Lenovo's, so releases do not bundle it.
        /// </summary>
        public static ChargeThresholdTool Ensure()
        {
            var path = ToolPath;
            if (!File.Exists(path))
            {
                Directory.CreateDirectory(Settings.DataDirectory);
                var temp = path + ".download";
                ServicePointManager.SecurityProtocol |= SecurityProtocolType.Tls12;
                try
                {
                    using (var client = new WebClient()) client.DownloadFile(DownloadUrl, temp);
                }
                catch (WebException ex)
                {
                    File.Delete(temp);
                    throw new ToolUnavailableException(Text.DownloadFailed(ex.Message, DownloadUrl, path), ex);
                }
                File.Move(temp, path);
            }

            if (!Signature.IsSignedByLenovo(path))
            {
                File.Delete(path);
                throw new ToolUnavailableException(Text.BadSignature(DownloadUrl, path));
            }
            return new ChargeThresholdTool(path);
        }

        /// <summary>The cached copy, or null when the app never downloaded it.</summary>
        public static ChargeThresholdTool Existing() =>
            File.Exists(ToolPath) && Signature.IsSignedByLenovo(ToolPath) ? new ChargeThresholdTool(ToolPath) : null;

        public ThresholdState Status() => ThresholdState.Parse(Run("status"));

        public void TurnOn(int stop, int start) => Run("on", stop.ToString(), start.ToString());

        public void TurnOff() => Run("off");

        private string Run(params string[] arguments)
        {
            var info = new ProcessStartInfo(_path, string.Join(" ", arguments))
            {
                UseShellExecute = false,
                CreateNoWindow = true,
                RedirectStandardOutput = true,
                RedirectStandardError = true,
            };
            using (var process = Process.Start(info))
            {
                var output = process.StandardOutput.ReadToEnd() + process.StandardError.ReadToEnd();
                process.WaitForExit();
                if (process.ExitCode != 0)
                    throw new InvalidOperationException(Text.ToolFailed(string.Join(" ", arguments), process.ExitCode, output.Trim()));
                return output.Trim();
            }
        }
    }

    /// <summary>ChargeThreshold.exe could not be obtained: download failed or the file is not Lenovo's.</summary>
    internal sealed class ToolUnavailableException : InvalidOperationException
    {
        public ToolUnavailableException(string message, Exception inner = null) : base(message, inner) { }
    }

    /// <summary>State parsed from "ChargeThreshold.exe status". The tool prints English text in every Windows language.</summary>
    internal sealed class ThresholdState
    {
        public bool IsOff { get; private set; }
        public int Start { get; private set; }
        public int Stop { get; private set; }

        public static ThresholdState Parse(string output)
        {
            // "Charge threshold for Battery #1: OFF."
            if (Regex.IsMatch(output, @":\s*OFF\.")) return new ThresholdState { IsOff = true };

            // "Charge threshold for Battery #1: Start at 75%, Stop at 80%."
            var match = Regex.Match(output, @"Start at (\d+)%, Stop at (\d+)%");
            if (match.Success)
                return new ThresholdState { Start = int.Parse(match.Groups[1].Value), Stop = int.Parse(match.Groups[2].Value) };

            throw new InvalidOperationException(Text.UnknownState(output));
        }
    }
}
