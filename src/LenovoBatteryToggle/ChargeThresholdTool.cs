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

        /// <summary>The user's copy, in the profile.</summary>
        public static readonly string ToolPath = Path.Combine(Settings.DataDirectory, "ChargeThreshold.exe");

        /// <summary>
        /// The copy next to the app, made only by an all-users setup (--install-tool), so it sits
        /// in Program Files where only administrators can write. It is the only copy an elevated
        /// process may run: the user's copy can be changed by the user's unelevated processes.
        /// </summary>
        public static readonly string ProtectedPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "ChargeThreshold.exe");

        private readonly string _path;

        private ChargeThresholdTool(string path) { _path = path; }

        /// <summary>
        /// Uses the protected copy, else the user's copy (downloaded earlier or saved there by
        /// hand), else downloads it from Lenovo. The file is Lenovo's, so releases do not bundle it.
        /// </summary>
        public static ChargeThresholdTool Ensure()
        {
            var protectedCopy = Protected();
            if (protectedCopy != null) return protectedCopy;
            if (Elevation.IsElevated) throw new InvalidOperationException(Text.Elevated);

            var path = ToolPath;
            if (!File.Exists(path))
            {
                Directory.CreateDirectory(Settings.DataDirectory);
                Download(path);
            }
            if (!Signature.IsSignedByLenovo(path))
            {
                File.Delete(path);
                throw new ToolUnavailableException(Text.BadSignature(DownloadUrl, path));
            }
            return new ChargeThresholdTool(path);
        }

        /// <summary>
        /// A copy that is already there, never downloads; null when there is none. An elevated
        /// process gets only the protected copy.
        /// </summary>
        public static ChargeThresholdTool Existing()
        {
            var protectedCopy = Protected();
            if (protectedCopy != null || Elevation.IsElevated) return protectedCopy;
            return File.Exists(ToolPath) && Signature.IsSignedByLenovo(ToolPath) ? new ChargeThresholdTool(ToolPath) : null;
        }

        /// <summary>
        /// Downloads the protected copy next to the app (--install-tool, run by an elevated
        /// all-users setup). The signature is checked on the file in its final place.
        /// </summary>
        public static void InstallProtected()
        {
            if (Protected() != null) return;
            Download(ProtectedPath);
            if (!Signature.IsSignedByLenovo(ProtectedPath))
            {
                File.Delete(ProtectedPath);
                throw new ToolUnavailableException(Text.BadSignature(DownloadUrl, ProtectedPath));
            }
        }

        // A protected copy that fails the check is ignored, not deleted: an unelevated process
        // is not allowed to delete it
        private static ChargeThresholdTool Protected() =>
            File.Exists(ProtectedPath) && Signature.IsSignedByLenovo(ProtectedPath) ? new ChargeThresholdTool(ProtectedPath) : null;

        private static void Download(string path)
        {
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
            if (File.Exists(path)) File.Delete(path);
            File.Move(temp, path);
        }

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
