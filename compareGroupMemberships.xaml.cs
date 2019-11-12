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
            var leftUser = UsrLeft.Text;
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
                //resultsBox.Text += res.Count;
                //resultsBox.Text += res.ToString();
                // resultsBox.Text += "\n";
                if (res.Count > 0)
                {
                    var builder = new StringBuilder();
                    foreach (var psObject in res)
                    {
                        try
                        {
                            builder.Append(psObject.BaseObject.ToString() + "\r\n");
                        }
                        catch { builder.Append("ObjNull\r\n"); }
                    }
                
                    GroupListLeft.Items.Add(builder.ToString());
                }

            }
            catch (Exception Err)
            {
                MessageBox.Show(Err.Message);
            }
        }
    }
}
