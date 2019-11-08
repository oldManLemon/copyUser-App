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
            string path = System.IO.Path.GetDirectoryName(System.Reflection.Assembly.GetExecutingAssembly().Location);
            string script = path + "\\scritps\\copyUsrCli.ps1";
           // string script = "C:\\Users\\ahase\\source\\repos\\poshScripts\\scritps\\copyUsrCli.ps1";
           // string script = "..\\scritps\\copyUsrCli.ps1";
            resultsBox.Text = script;
            resultsBox.Text += "\n";
            InitialSessionState iss = InitialSessionState.CreateDefault2();
            var shell = PowerShell.Create(iss);
            shell.Commands.AddCommand(script).AddArgument('"'+userToCopy+'"').AddArgument('"'+newUserName+'"');
            resultsBox.Text += "here we go";
            resultsBox.Text += "\n";

            try
            {
                var res = shell.Invoke();
                if(res.Count > 0)
                {
                    var builder = new StringBuilder();
                    foreach (var psObject in res)
                    {
                        builder.Append(psObject.BaseObject.ToString() + "\r\n");
                    }
                    resultsBox.Text += "\n";
                    resultsBox.Text += builder.ToString();
                }
                resultsBox.Text = "Outside of loop";
            }
            catch (RuntimeException Err)
            {
                resultsBox.Text += Err.Message;
                resultsBox.Text += "\n";
            }
        }



    }

}
//namespace powershell
//{


//    class Program
//    {
//        static void Main(string[] args)
//        {
//            using (PowerShell PowerShellInstance = PowerShell.Create())
//            {
//                string cmd = ".\\scritps\\copyUsrCli.ps1 {} {}";
//                string tempUsr = "Andrew Hase";
//                string newUsr = "Tim Burton";
//                string fullCmd = string.Format(cmd, tempUsr, newUsr);


//                PowerShellInstance.AddCommand(fullCmd);
//            }
//        }
//    }
//}