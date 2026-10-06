using System;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Threshold values used when the toggle switches thresholds on, and how long the
    /// notification stays on screen. Everything the app writes lives in one folder,
    /// %LOCALAPPDATA%\LenovoBatteryToggle, so the uninstaller can remove it in one step.
    /// </summary>
    [DataContract]
    internal sealed class Settings
    {
        public static readonly string DataDirectory =
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LenovoBatteryToggle");

        public static readonly string ConfigPath = Path.Combine(DataDirectory, "config.json");

        private const int DefaultStart = 75;
        private const int DefaultStop = 80;
        public const int DefaultSeconds = 4;
        public const int MinSeconds = 2;
        public const int MaxSeconds = 10;

        [DataMember(Name = "start")] public int Start { get; private set; } = DefaultStart;
        [DataMember(Name = "stop")] public int Stop { get; private set; } = DefaultStop;
        [DataMember(Name = "notificationSeconds")] private int _seconds = DefaultSeconds;

        /// <summary>
        /// Notification time; a hand-edited value outside 2-10 is pulled into range rather than
        /// reported, because it is cosmetic and must not block the toggle.
        /// </summary>
        public int NotificationSeconds => Math.Max(MinSeconds, Math.Min(MaxSeconds, _seconds));

        public static Settings Load()
        {
            // Write the defaults on first run, so there is a file to edit
            if (!File.Exists(ConfigPath)) Save(DefaultStart, DefaultStop);

            var settings = Read(ConfigPath);
            if (!(settings.Start >= 0 && settings.Stop <= 100 && settings.Start < settings.Stop))
                throw new InvalidOperationException(Text.InvalidConfig(ConfigPath, settings.Start, settings.Stop));
            return settings;
        }

        /// <summary>Current values for the settings window; defaults when the file is missing or broken.</summary>
        public static Settings LoadOrDefault()
        {
            try { return Load(); }
            catch (Exception) { return new Settings(); }
        }

        /// <summary>
        /// Writes the values chosen in the installer or the settings window (validated first).
        /// Without <paramref name="seconds"/> (the installer asks only for thresholds) the
        /// current notification time is kept.
        /// </summary>
        public static void Save(int start, int stop, int? seconds = null)
        {
            if (!(start >= 0 && stop <= 100 && start < stop))
                throw new InvalidOperationException(Text.InvalidConfig(ConfigPath, start, stop));
            var value = Math.Max(MinSeconds, Math.Min(MaxSeconds, seconds ?? CurrentSeconds()));
            Directory.CreateDirectory(DataDirectory);
            File.WriteAllText(ConfigPath,
                "{\r\n  \"start\": " + start + ",\r\n  \"stop\": " + stop + ",\r\n  \"notificationSeconds\": " + value + "\r\n}\r\n",
                new UTF8Encoding(false));
        }

        private static int CurrentSeconds()
        {
            try { return File.Exists(ConfigPath) ? Read(ConfigPath).NotificationSeconds : DefaultSeconds; }
            catch (InvalidOperationException) { return DefaultSeconds; }
        }

        private static Settings Read(string path)
        {
            try
            {
                using (var stream = File.OpenRead(path))
                    return (Settings)new DataContractJsonSerializer(typeof(Settings)).ReadObject(stream);
            }
            catch (SerializationException ex)
            {
                throw new InvalidOperationException(Text.UnreadableConfig(path, ex.Message), ex);
            }
        }

        // DataContractJsonSerializer skips constructors and field initializers, so set the defaults
        // here; a file written by an older version has no notificationSeconds and keeps the default
        [OnDeserializing]
        private void SetDefaults(StreamingContext context)
        {
            Start = DefaultStart;
            Stop = DefaultStop;
            _seconds = DefaultSeconds;
        }
    }
}
