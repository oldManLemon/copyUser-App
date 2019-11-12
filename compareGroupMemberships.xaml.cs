using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Shapes;
using System.Management.Automation;
using System.Collections.ObjectModel;
using System.Management.Automation.Runspaces;
using LumenWorks.Framework.IO.Csv;
using System.IO;
using System.Data;
using Microsoft.VisualBasic.FileIO;

namespace poshScripts
{
    /// <summary>
    /// Interaction logic for compareGroupMemberships.xaml
    /// </summary>
    public partial class compareGroupMemberships : Window
    {
        public compareGroupMemberships()
        {
            InitializeComponent();
        }
        string server { get; set; }
        public void domain_Check(object sender, RoutedEventArgs e)
        {
            RadioButton check = sender as RadioButton;
            if (check.IsChecked.Value)
            {
                server = check.Name;
            }
            
        }

     

        private void loadLeft_Click(object sender, RoutedEventArgs e)

        {
            var path = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"\\aviovaManagementApp\\usrData\\"+server+".csv");
            var leftUser = UsrLeft.Text;
            DataTable dt = new DataTable();
            using(TextFieldParser parser = new TextFieldParser(path))
            {
                // set the parser variables
                parser.TextFieldType = FieldType.Delimited;
                parser.SetDelimiters(",");
            }
            //using(CsvReader csv = new CsvReader(
            //    new StreamReader(path), true))
            //{
            //    csv.ToLookup("ahase");
            //}
            //Initialise Powershell
            InitialSessionState iss = InitialSessionState.CreateDefault2();
            var shell = PowerShell.Create(iss);
            var script = "C:\\Users\\ahase\\source\\repos\\poshScripts\\scritps\\getUsrGroup.ps1";
            shell.Commands.AddCommand(script);
            shell.Commands.AddArgument(leftUser);
            shell.Commands.AddArgument(server);
            try
            {
                var res = shell.Invoke();
                if (res.Count > 0)
                {
                    //var builder = new StringBuilder();
                    foreach (var psObject in res)
                    {
                        GroupListLeft.Items.Add(psObject.BaseObject.ToString());
                    }
                }
                TotalLeft.Content = res.Count;
            }
            catch(Exception err)
            {
                MessageBox.Show(err.Message);
            }
        }

        private void reloadUsers(object sender, RoutedEventArgs e)
        {
            var script = "C:\\Users\\ahase\\source\\repos\\poshScripts\\scritps\\getUsrLists.ps1";
            //Initialise Powershell
            InitialSessionState iss = InitialSessionState.CreateDefault2();
            var shell = PowerShell.Create(iss);

            shell.Commands.AddCommand(script);
            shell.Commands.AddArgument(server);

            try
            {
                //GroupListLeft
                var res = shell.Invoke();
            }
            catch (Exception Err)
            {
                MessageBox.Show(Err.Message);
            }
        }

        private void loadRight_Click(object sender, RoutedEventArgs e)
        {
            var rightUser = UsrRight.Text;
            //Initialise Powershell
            InitialSessionState iss = InitialSessionState.CreateDefault2();
            var shell = PowerShell.Create(iss);
            var script = "C:\\Users\\ahase\\source\\repos\\poshScripts\\scritps\\getUsrGroup.ps1";
            shell.Commands.AddCommand(script);
            shell.Commands.AddArgument(rightUser);
            shell.Commands.AddArgument(server);
            try
            {
                var res = shell.Invoke();
                if (res.Count > 0)
                {
                    //var builder = new StringBuilder();
                    foreach (var psObject in res)
                    {
                        GroupListRight.Items.Add(psObject.BaseObject.ToString());
                    }
                }
                TotalRight.Content = res.Count;
            }
            catch (Exception err)
            {
                MessageBox.Show(err.Message);
            }
        }
    }
}
