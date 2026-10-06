using System;
using System.IO;
using System.Runtime.Serialization;
using System.Runtime.Serialization.Json;
using System.Text;

namespace LenovoBatteryToggle
{
    /// <summary>
    /// Threshold values used when the toggle switches thresholds on.
    /// Everything the app writes lives in one folder, %LOCALAPPDATA%\LenovoBatteryToggle,
    /// so the uninstaller can remove it in one step.
    /// </summary>
    [DataContract]
    internal sealed class Settings
    {
        public static readonly string DataDirectory =
            Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "LenovoBatteryToggle");

        public static readonly string ConfigPath = Path.Combine(DataDirectory, "config.json");

        private const int DefaultStart = 75;
        private const int DefaultStop = 80;

        [DataMember(Name = "start")] public int Start { get; private set; } = DefaultStart;
        [DataMember(Name = "stop")] public int Stop { get; private set; } = DefaultStop;

        public static Settings Load()
        {
            // Write the defaults on first run, so there is a file to edit
            if (!File.Exists(ConfigPath))
            {
                Directory.CreateDirectory(DataDirectory);
                File.WriteAllText(ConfigPath,
                    "{\r\n  \"start\": " + DefaultStart + ",\r\n  \"stop\": " + DefaultStop + "\r\n}\r\n",
                    new UTF8Encoding(false));
            }

            var settings = Read(ConfigPath);
            if (!(settings.Start >= 0 && settings.Stop <= 100 && settings.Start < settings.Stop))
                throw new InvalidOperationException(Text.InvalidConfig(ConfigPath, settings.Start, settings.Stop));
            return settings;
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

        // DataContractJsonSerializer skips constructors and field initializers, so set the defaults here
        [OnDeserializing]
        private void SetDefaults(StreamingContext context)
        {
            Start = DefaultStart;
            Stop = DefaultStop;
        }
    }
}
