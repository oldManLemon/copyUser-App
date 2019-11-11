using System.Windows;
using System.Management.Automation;
using System.Collections.ObjectModel;
using System.Management.Automation.Runspaces;
using System.Text;


namespace poshScripts
{
    /// <summary>
    /// Interaction logic for copyUsr.xaml
    /// </summary>
    public partial class copyUsr : Window
    {
        public copyUsr()
        {
            InitializeComponent();
        }
        string userToCopy;
        string newUserName;
        public void copyUserButton(object sender, RoutedEventArgs e)
        {
            userToCopy = templateUser.Text;
            newUserName = newUsr.Text;

            //string cmd = ".\\scritps\\copyUsrCli.ps1 " + '"' +userToCopy + '"' + " " + '"' + newUserName+ '"';
            //string path = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            //string script = path + "\\scritps\\copyUsrCli.ps1";
            //This will need to be changed when the program lives on the server. For now it is local
            string script = "C:\\Users\\ahase\\source\\repos\\poshScripts\\scritps\\copyUsrCli.ps1";
            // As this begins with = not += it will wipe the old output to begin new output
            resultsBox.Text = script;
            resultsBox.Text += "\n";
            //Initalise
            //https://docs.microsoft.com/en-us/dotnet/api/system.management.automation?view=pscore-6.2.0
            //https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.powershell?view=pscore-6.2.0
            //https://docs.microsoft.com/en-us/dotnet/api/system.management.automation.runspaces.runspace?view=pscore-6.2.0
            InitialSessionState iss = InitialSessionState.CreateDefault2();
            var shell = PowerShell.Create(iss);
            //Commands and args, running as AddScript fails. 
            shell.Commands.AddCommand(script);
            shell.Commands.AddArgument(userToCopy);
            shell.Commands.AddArgument(newUserName);
            //Debug outputs
            resultsBox.Text += script;
            resultsBox.Text += "\n***********************************\n";
            resultsBox.Text += "Launching Powershell Application\n";
            resultsBox.Text += "***********************************\n";
            resultsBox.Text += "\n";
            try
            {
                //resultsBox.Text += "Inside of try";
                //resultsBox.Text += "\n";
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
                    resultsBox.Text += "\n";
                    resultsBox.Text += builder.ToString();
                }
                //resultsBox.Text += "Outside of loop";
            }
            catch (RuntimeException Err)
            {
                resultsBox.Text += "***********************************\n";
                resultsBox.Text += "Error: ";
                resultsBox.Text += Err.Message;
                resultsBox.Text += "***********************************\n";
                resultsBox.Text += "\n";
            }
            //resultsBox.Text += "Here End";
        }



    }

}
