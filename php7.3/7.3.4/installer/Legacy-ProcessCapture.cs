// Deliberately uses only C# 2 and .NET 2.0 APIs for Windows PowerShell 2.0.
using System;
using System.Diagnostics;
using System.Text;
using System.Threading;

public sealed class Php734LegacyProcessResult
{
    public int ExitCode;
    public string Output;
    public string Error;
}

public static class Php734LegacyProcessCapture
{
    public static void ReplaceReceipt(string temporary, string destination)
    {
        // Pass a real CLR null; old PowerShell otherwise binds $null to an
        // empty string for File.Replace's string backupFileName parameter.
        System.IO.File.Replace(temporary, destination, null);
    }

    public static Php734LegacyProcessResult Run(string exe, string arguments, string cwd, int timeout)
    {
        Process process = new Process();
        StringBuilder output = new StringBuilder();
        StringBuilder error = new StringBuilder();
        ManualResetEvent outputEnd = new ManualResetEvent(false);
        ManualResetEvent errorEnd = new ManualResetEvent(false);
        process.StartInfo.FileName = exe;
        process.StartInfo.Arguments = arguments;
        process.StartInfo.WorkingDirectory = cwd;
        process.StartInfo.UseShellExecute = false;
        process.StartInfo.CreateNoWindow = true;
        process.StartInfo.RedirectStandardOutput = true;
        process.StartInfo.RedirectStandardError = true;
        process.OutputDataReceived += delegate(object sender, DataReceivedEventArgs e) {
            if (e.Data == null) { outputEnd.Set(); }
            else { lock (output) { output.AppendLine(e.Data); } }
        };
        process.ErrorDataReceived += delegate(object sender, DataReceivedEventArgs e) {
            if (e.Data == null) { errorEnd.Set(); }
            else { lock (error) { error.AppendLine(e.Data); } }
        };
        try
        {
            if (!process.Start()) { throw new InvalidOperationException("Unable to start PHP"); }
            process.BeginOutputReadLine();
            process.BeginErrorReadLine();
            if (!process.WaitForExit(timeout))
            {
                process.Kill();
                process.WaitForExit();
                outputEnd.WaitOne(5000, false);
                errorEnd.WaitOne(5000, false);
                throw new TimeoutException("PHP startup check exceeded its timeout; only this test process was stopped");
            }
            if (!outputEnd.WaitOne(5000, false) || !errorEnd.WaitOne(5000, false))
            {
                throw new TimeoutException("PHP output capture did not finish");
            }
            Php734LegacyProcessResult result = new Php734LegacyProcessResult();
            result.ExitCode = process.ExitCode;
            result.Output = output.ToString();
            result.Error = error.ToString();
            return result;
        }
        finally
        {
            process.Dispose();
            outputEnd.Close();
            errorEnd.Close();
        }
    }
}
