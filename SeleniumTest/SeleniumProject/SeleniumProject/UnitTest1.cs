using System;
using System.Threading;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using OpenQA.Selenium;
using OpenQA.Selenium.Chrome;
using OpenQA.Selenium.IE;
using OpenQA.Selenium.Firefox;
using OpenQA.Selenium.Safari;
using OpenQA.Selenium.Edge;
//using OpenQA.Selenium.PhantomJS;

namespace SeleniumProject
{
	[TestClass]
	public class UnitTest1
	{
		[TestMethod]
		public void TestChrome()
		{
			IWebDriver driver = null;
			try
			{
				driver = new ChromeDriver(@"C:\tools");
				driver.Url = "http://www.softpost.org";
				driver.Manage().Window.Maximize();
				driver.Navigate();
			}
			catch (Exception ex)
			{
				Console.Write("Exception..." + ex.ToString());
			}
			finally
			{
				Thread.Sleep(2000);
				driver.Close();
				driver.Quit();
			}
		}

		[TestMethod]
		public void TestIE()
		{
			IWebDriver driver = null;
			//InternetExplorerOptions op = new InternetExplorerOptions();
			try
			{
				driver = new InternetExplorerDriver(@"C:\tools");
				driver.Url = "http://www.softpost.org";
				driver.Manage().Window.Maximize();
				driver.Navigate();
			}
			catch (Exception ex)
			{
				Console.Write("Exception..." + ex.ToString());
			}
			finally
			{
				Thread.Sleep(2000);
				driver.Close();
				driver.Quit();
			}
		}

		[TestMethod]
		public void TestFireFox()
		{
			IWebDriver driver = null;
			FirefoxDriverService service = FirefoxDriverService.CreateDefaultService(@"C:\tools");
			service.FirefoxBinaryPath = @"C:\Program Files\Mozilla Firefox\firefox.exe";
			service.HideCommandPromptWindow = true;
			service.SuppressInitialDiagnosticInformation = true;
			driver = new FirefoxDriver(service);

			try
			{
				//driver = new FirefoxDriver();
				driver.Url = "http://www.softpost.org";
				driver.Manage().Window.Maximize();
				driver.Navigate();
			}
			catch (Exception ex)
			{
				Console.Write("Exception..." + ex.ToString());
			}
			finally
			{
				Thread.Sleep(2000);
				driver.Close();
				driver.Quit();
			}
		}
	}
}
