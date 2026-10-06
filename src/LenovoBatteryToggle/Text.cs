using System.Globalization;

namespace LenovoBatteryToggle
{
    /// <summary>User-facing messages: Polish on a Polish Windows, English everywhere else.</summary>
    internal static class Text
    {
        private static readonly bool Polish = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName == "pl";

        private static string Pick(string pl, string en) => Polish ? pl : en;

        public static string TurnedOff => Pick(
            "Progi WYŁĄCZONE: bateria ładuje się do 100 %.",
            "Charge thresholds OFF: the battery charges to 100%.");

        public static string TurnedOn(int start, int stop) => Pick(
            $"Progi WŁĄCZONE: ładowanie od {start} %, stop przy {stop} %.",
            $"Charge thresholds ON: charging starts below {start}%, stops at {stop}%.");

        public static string Error => Pick("Błąd: ", "Error: ");

        public static string SettingsTitle => "Lenovo Battery Toggle Settings";

        public static string SettingsIntro => Pick(
            "Progi używane, gdy przełącznik włącza ograniczenie ładowania. Bateria zaczyna się ładować poniżej wartości start i przestaje przy wartości stop.",
            "Thresholds used when the toggle switches charge limiting on. The battery starts charging below the start value and stops at the stop value.");

        public static string StartLabel => Pick("Ładuj, gdy poziom spadnie poniżej (%):", "Start charging below (%):");

        public static string StopLabel => Pick("Przestań ładować przy (%):", "Stop charging at (%):");

        public static string SecondsLabel => Pick("Czas wyświetlania powiadomienia (s):", "Show the notification for (s):");

        public static string Save => Pick("Zapisz", "Save");

        public static string Cancel => Pick("Anuluj", "Cancel");

        public static string SettingsApplyNow => Pick(
            "Jeśli progi są włączone, nowe wartości zadziałają od razu.",
            "If thresholds are on, the new values apply right away.");

        public static string StateNow => Pick("Teraz: ", "Now: ");

        public static string StateReading => Pick("odczytuję stan progów…", "reading the threshold state…");

        public static string StateUnknown(string reason) => Pick(
            $"nie udało się odczytać stanu progów. {reason}",
            $"the threshold state could not be read. {reason}");

        public static string ToolNotYetDownloaded => Pick(
            "ChargeThreshold.exe nie jest jeszcze pobrany; aplikacja pobierze go przy pierwszym przełączeniu.",
            "ChargeThreshold.exe is not downloaded yet; the app downloads it on the first toggle.");

        public static string StartBelowStop => Pick(
            "Wartość start musi być mniejsza niż stop.",
            "The start value must be lower than the stop value.");

        public static string SavedNotApplied => Pick(
            "Ustawienia zapisane, ale nie udało się ich teraz zastosować: ",
            "Settings saved, but they could not be applied now: ");

        public static string DriverMissing => Pick(
            "Brak sterownika Lenovo Power and Battery. Uruchom Windows Update albo zainstaluj paczkę DS541411 ze strony wsparcia Lenovo.",
            "The Lenovo Power and Battery driver is missing. Run Windows Update or install package DS541411 from Lenovo Support.");

        public static string Elevated => Pick(
            "Aplikację uruchomiono jako administrator, a ta instalacja nie ma własnej kopii ChargeThreshold.exe w folderze programu. Uruchom ją zwykłym skrótem albo klawiszem.",
            "The app was started as administrator, and this installation has no copy of ChargeThreshold.exe in the program folder. Start it normally, from its shortcut or key.");

        public static string BadSignature(string url, string path) => Pick(
            $"ChargeThreshold.exe nie ma ważnego podpisu Lenovo i został usunięty. Pobierz go ręcznie z\n{url}\ni zapisz jako\n{path}",
            $"ChargeThreshold.exe has no valid Lenovo signature and was deleted. Download it manually from\n{url}\nand save it as\n{path}");

        public static string DownloadFailed(string reason, string url, string path) => Pick(
            $"Nie udało się pobrać ChargeThreshold.exe od Lenovo ({reason}). Pobierz go ręcznie z\n{url}\ni zapisz jako\n{path}",
            $"Could not download ChargeThreshold.exe from Lenovo ({reason}). Download it manually from\n{url}\nand save it as\n{path}");

        public static string ToolFailed(string arguments, int code, string output) => Pick(
            $"ChargeThreshold.exe {arguments} zwrócił kod {code}. Czy sterownik Lenovo Power and Battery jest zainstalowany?\n{output}",
            $"ChargeThreshold.exe {arguments} returned code {code}. Is the Lenovo Power and Battery driver installed?\n{output}");

        public static string UnknownState(string output) => Pick(
            $"Nieznany stan progów:\n{output}",
            $"Unknown threshold state:\n{output}");

        public static string InvalidConfig(string path, int start, int stop) => Pick(
            $"Błędne progi w {path}: start={start}, stop={stop}. Wymagane 0 <= start < stop <= 100.",
            $"Invalid thresholds in {path}: start={start}, stop={stop}. Required 0 <= start < stop <= 100.");

        public static string UnreadableConfig(string path, string reason) => Pick(
            $"Nie można odczytać {path}: {reason}",
            $"Cannot read {path}: {reason}");
    }
}
