﻿using System;
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
            //List<String> userNameList = readCSV(server);
            //userNameList.ForEach(i => Console.WriteLine("{0}\t", i));
            List<String> userNameList = new List<String> { "ahase","thase","welcome","whoknows"};
            userLeftLoaded = false;
            userRightLoaded = false;
        }
        string server { get; set; }

        bool userLeftLoaded { get; set; }
        bool userRightLoaded { get; set; }
        ItemCollection rightItems { get; set; }
        ItemCollection leftItems { get; set; }

        public void domain_Check(object sender, RoutedEventArgs e)
        {
            RadioButton check = sender as RadioButton;
            if (check.IsChecked.Value)
            {
                server = check.Name;
            }

        }
        public void bothUsersLoaded()
        {
            if(userLeftLoaded && userRightLoaded)
            {
                TransLR.Visibility = 0; 
                TransRL.Visibility = 0; 
                Compare.Visibility = 0;
                Console.WriteLine("Do Stuf Now");
            }
            else
            {
                //DO TO, As below no work! :(
                //TransLR.Visibility = Hidden;
                //TransRL.Visibility(0);
                //Compare.Visibility = 1;
            }
        }

        //Roll through the CSV
        public static List<String> readCSV(string cvsServer)
        {
            Console.WriteLine("I am started°");
            string[] a = { "string" };
            var endPath = "\\aviovaManagementApp\\usrData\\" + cvsServer + ".csv";
            var path = System.IO.Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData) + endPath);
            List<string> listOfUserNames = new List<string>();
            using (TextFieldParser parser = new TextFieldParser(@path))
            {

                parser.TextFieldType = FieldType.Delimited;
                parser.SetDelimiters("\",");
                parser.HasFieldsEnclosedInQuotes = false;

                while (!parser.EndOfData)
                {
                    //Processing row
                    string[] fields = parser.ReadFields();
                    listOfUserNames.Add(fields[0]);
                }
            }return listOfUserNames;

        }



        private void loadLeft_Click(object sender, RoutedEventArgs e)
        {
            //GroupListLeft.Items.Clear();
            var leftUser = UsrLeft.Text;
            if (leftUser == "")
            {
                MessageBox.Show("No User Entered");
                GroupListLeft.Items.Add("");
                var fail = GroupListLeft.Items;

                return;
            }

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
            catch (Exception err)
            {
                MessageBox.Show(err.Message);
            }
            //Set Load State
            userLeftLoaded = true;
            bothUsersLoaded();
            leftItems = GroupListLeft.Items;

            

        }


        private void loadRight_Click(object sender, RoutedEventArgs e)
        {
            //GroupListRight.Items.Clear();
            var rightUser = UsrRight.Text;
            if (rightUser == "")
            {
                MessageBox.Show("No User Entered");
                GroupListLeft.Items.Add("");
                var fail = GroupListLeft.Items;

                return;
            }
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
            //Set Loaded State
            userRightLoaded = true;
            bothUsersLoaded();
            rightItems = GroupListRight.Items;
            

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

        private void click_compare(object sender, RoutedEventArgs e)
        {
            var localRight = rightItems;
            var localLeft = leftItems;
            Console.WriteLine("Click");
           
            for(int i=0; i<localLeft.Count; i++)
            {
                for (int j = 0; j < localRight.Count; j++)
                {
                    if (localLeft[i].ToString() == localRight[j].ToString())
                    {
                        //Highlight List Boxes
                        //GroupListLeft.Items.Add((Colors.Green));
                        //GroupListRight.Items.Add((Colors.Green));
                    }
                        
                }
            }

        }

        //Stackoverflow
        public class MyListBoxItem
        {
            public MyListBoxItem(Color c, string m)
            {
                ItemColor = c;
                Message = m;
            }
            public Color ItemColor { get; set; }
            public string Message { get; set; }
        }

    }
 }
