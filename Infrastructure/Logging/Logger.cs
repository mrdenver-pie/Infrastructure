using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;
using NLog;
using NLog.Config;

namespace Logging
{
    public static class Logger
    {
        // A Logger dispenser for the current assembly 
        public static readonly LogFactory Instance = new LogFactory(new XmlLoggingConfiguration(GetNLogConfigFilePath()));
        
        // 
        // Use a config file located next to our current assembly dll 
        // eg, if the running assembly is c:\path\to\MyComponent.dll 
        // the config filepath will be c:\path\to\MyComponent.nlog 
        // 
        // WARNING: This will not be appropriate for assemblies in the GAC 
        // 
        private static string GetNLogConfigFilePath()
        {
            // Use name of current assembly to construct NLog config filename 

            Assembly thisAssembly = Assembly.GetExecutingAssembly();

            return Path.ChangeExtension(thisAssembly.Location, ".nlog");
        }

        /// <summary>
        /// Gets or sets the enabled status of the logger.
        /// </summary>
        public static bool Enabled
        {
            get { return LogManager.IsLoggingEnabled(); }
            set
            {
                if (value)
                {
                    while (!Enabled) LogManager.EnableLogging();
                }
                else
                {
                    while (Enabled) LogManager.DisableLogging();
                }
            }
        }

        /// <summary>
        /// Writes the diagnostic message at the Trace level.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        public static void Trace(string message, Exception exception = null,
            [CallerFilePath] string callerPath = "",
            [CallerMemberName] string callerMember = "",
            [CallerLineNumber] int callerLine = 0)
        {
            Log(LogLevel.Trace, message, exception, callerPath, callerMember, callerLine);
        }

        /// <summary>
        /// Writes the diagnostic message at the Debug level.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        public static void Debug(string message, Exception exception = null,
            [CallerFilePathAttribute] string callerPath = "",
            [CallerMemberName] string callerMember = "",
            [CallerLineNumber] int callerLine = 0)
        {
            Log(LogLevel.Debug, message, exception, callerPath, callerMember, callerLine);
            Log(LogLevel.Debug, message, exception, callerPath, callerMember, callerLine);
        }

        /// <summary>
        /// Writes the diagnostic message at the Info level.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        public static void Info(string message, Exception exception = null,
            [CallerFilePathAttribute] string callerPath = "",
            [CallerMemberName] string callerMember = "",
            [CallerLineNumber] int callerLine = 0)
        {
            Log(LogLevel.Info, message, exception, callerPath, callerMember, callerLine);
        }

        /// <summary>
        /// Writes the diagnostic message at the Warn level.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        public static void Warn(string message, Exception exception = null,
            [CallerFilePathAttribute] string callerPath = "",
            [CallerMemberName] string callerMember = "",
            [CallerLineNumber] int callerLine = 0)
        {
            Log(LogLevel.Warn, message, exception, callerPath, callerMember, callerLine);
        }

        /// <summary>
        /// Writes the diagnostic message at the Error level.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        public static void Error(string message, Exception exception = null,
            [CallerFilePathAttribute] string callerPath = "",
            [CallerMemberName] string callerMember = "",
            [CallerLineNumber] int callerLine = 0)
        {
            Log(LogLevel.Error, message, exception, callerPath, callerMember, callerLine);
        }

        /// <summary>
        /// Writes the diagnostic message at the Fatal level.
        /// </summary>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        public static void Fatal(string message, Exception exception = null,
            [CallerFilePathAttribute] string callerPath = "",
            [CallerMemberName] string callerMember = "",
            [CallerLineNumber] int callerLine = 0)
        {
            Log(LogLevel.Fatal, message, exception, callerPath, callerMember, callerLine);
        }

        /// <summary>
        /// Writes the specified diagnostic message.
        /// </summary>
        /// <param name="level"></param>
        /// <param name="message"></param>
        /// <param name="exception"></param>
        /// <param name="callerPath"></param>
        /// <param name="callerMember"></param>
        /// <param name="callerLine"></param>
        private static void Log(LogLevel level, string message, Exception exception = null, string callerPath = "", string callerMember = "", int callerLine = 0)
        {
            // get the source-file-specific logger
            var logger = LogManager.GetLogger(callerPath);

            // quit processing any further if not enabled for the requested logging level
            if (!logger.IsEnabled(level)) return;

            // log the event with caller information bound to it
            var logEvent = new LogEventInfo(level, callerPath, message) { Exception = exception };
            logEvent.Properties.Add("callerpath", callerPath);
            logEvent.Properties.Add("callermember", callerMember);
            logEvent.Properties.Add("callerline", callerLine);
            logger.Log(logEvent);
        }
    }

}
