using System;
using Logging;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace LoggingTest
{
    [TestClass]
    public class LoggingUnitTest
    {
        [TestMethod]
        public void TestLoggerInfo()
        {
            Logger.Info("Test of the Info method");
        }

        [TestMethod]
        public void TestLoggerTrace()
        {
            Logger.Trace("Test of the Trace method");
        }

        [TestMethod]
        public void TestLoggerDebug()
        {
            Logger.Debug("Test of the Debug methind");
        }

        [TestMethod]
        public void TestLoggerWarn()
        {
            Logger.Warn("Test of the Warn method");
        }

        [TestMethod]
        public void TestLoggerError()
        {
            Logger.Error("Test of the Error methind");
        }

        [TestMethod]
        public void TestLoggerFatal()
        {
            Logger.Fatal("Test of the Fatal method");
        }
    }
}
