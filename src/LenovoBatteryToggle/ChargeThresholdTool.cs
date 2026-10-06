using System;
using System.Diagnostics;
using System.IO;
using System.Net;
using System.Security.Cryptography;
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
        /// The copy next to the app, made only by an elevated process (an all-users setup, or the
        /// all-users uninstaller), so it sits in Program Files where only administrators can write.
        /// It is the only copy an elevated process may run: the user's copy can be changed by the
        /// user's unelevated processes.
        /// </summary>
        public static readonly string ProtectedPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "ChargeThreshold.exe");

        /// <summary>
        /// SHA-256 of the one build a user's copy may be promoted from: ChargeThreshold.exe
        /// v1.0.0.2 (OriginalFilename ChargeTh.exe), as served at <see cref="DownloadUrl"/>. The
        /// signature alone would accept any Lenovo-signed program put in the profile under that name.
        /// </summary>
        private const string PromotableSha256 = "C919EE2FAEA907169FE0222BD8B1BD07E03E6A8E106DFEA7EE0A9A9CE5EE8380";

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
            if (Elevation.IsElevated) return Promote() ?? throw new InvalidOperationException(Text.Elevated);

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
        /// process gets only the protected copy, promoted from the user's copy if needed.
        /// </summary>
        public static ChargeThresholdTool Existing()
        {
            var protectedCopy = Protected();
            if (protectedCopy != null) return protectedCopy;
            if (Elevation.IsElevated) return Promote();
            return File.Exists(ToolPath) && Signature.IsSignedByLenovo(ToolPath) ? new ChargeThresholdTool(ToolPath) : null;
        }

        /// <summary>
        /// Downloads the protected copy next to the app (--install-tool, run by an elevated
        /// all-users setup), or promotes the user's copy when the download fails. The signature
        /// is checked on the file in its final place.
        /// </summary>
        public static void InstallProtected()
        {
            if (Protected() != null) return;
            try
            {
                Download(ProtectedPath);
            }
            catch (ToolUnavailableException)
            {
                if (Promote() != null) return;
                throw;
            }
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

        /// <summary>
        /// Copies the user's copy next to the app and checks the copy there, where unelevated
        /// processes cannot change it any more; the source is never checked or run. Lets an
        /// all-users install whose download failed at setup still switch thresholds off on
        /// uninstall, without network. Null when there is nothing valid to promote.
        /// </summary>
        private static ChargeThresholdTool Promote()
        {
            var temp = ProtectedPath + ".promote";
            try
            {
                if (!File.Exists(ToolPath)) return null;
                File.Copy(ToolPath, temp, true);
                if (!Signature.IsSignedByLenovo(temp) || !HasSha256(temp, PromotableSha256))
                {
                    File.Delete(temp);
                    return null;
                }
                if (File.Exists(ProtectedPath)) File.Delete(ProtectedPath);
                File.Move(temp, ProtectedPath);
                return new ChargeThresholdTool(ProtectedPath);
            }
            catch (Exception)
            {
                try { File.Delete(temp); } catch (Exception) { }
                return null;
            }
        }

        private static bool HasSha256(string path, string expected)
        {
            using (var sha = SHA256.Create())
            using (var stream = File.OpenRead(path))
                return BitConverter.ToString(sha.ComputeHash(stream)).Replace("-", "") == expected;
        }

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
