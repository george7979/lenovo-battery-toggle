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

        public static string BadSignature => Pick(
            "Pobrany ChargeThreshold.exe nie ma ważnego podpisu Lenovo i został usunięty.",
            "The downloaded ChargeThreshold.exe has no valid Lenovo signature and was deleted.");

        public static string DownloadFailed(string reason) => Pick(
            $"Nie udało się pobrać ChargeThreshold.exe od Lenovo: {reason}",
            $"Could not download ChargeThreshold.exe from Lenovo: {reason}");

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
