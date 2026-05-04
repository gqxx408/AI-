using System;
using System.IO;
using System.Windows;

namespace AIStockTrader.WPF
{
    public partial class App : Application
    {
        protected override void OnStartup(StartupEventArgs e)
        {
            base.OnStartup(e);
            
            try
            {
                var exePath = System.Reflection.Assembly.GetExecutingAssembly().Location;
                var exeDir = Path.GetDirectoryName(exePath);
                if (!string.IsNullOrEmpty(exeDir))
                {
                    Directory.SetCurrentDirectory(exeDir);
                }
            }
            catch { }
        }
    }
}
