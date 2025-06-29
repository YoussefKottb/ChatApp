using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using Microsoft.AspNetCore.SignalR.Client;
using System.Threading.Tasks;

namespace WPFClient
{
    public partial class MainWindow : Window
    {
        HubConnection connection;
        string? url;

        public MainWindow()
        {
            InitializeComponent();
            if (connection is not null)
            {
                #region ConnectionStates
                connection.Reconnecting += (sender) =>
                {
                    this.Dispatcher.Invoke(() =>
                    {
                        var newMessage = "Attempting to reconnect...";
                        messages.Items.Add(newMessage);
                    });

                    return Task.CompletedTask;
                };

                connection.Reconnected += (sender) =>
                {
                    this.Dispatcher.Invoke(() =>
                    {
                        var newMessage = "Reconnected to the server";
                        messages.Items.Clear();
                        messages.Items.Add(newMessage);
                    });

                    return Task.CompletedTask;
                };

                connection.Closed += (sender) =>
                {
                    this.Dispatcher.Invoke(() =>
                    {
                        var newMessage = "Connection Closed";
                        messages.Items.Add(newMessage);
                        connect.IsEnabled = true;
                        sendMessage.IsEnabled = false;
                    });

                    return Task.CompletedTask;
                };
                #endregion
            }
        }

        private async void connect_Click(object sender, RoutedEventArgs e)
        {
            url = serverUrl.Text;

            connection = new HubConnectionBuilder()
                .WithUrl(url)
                .WithAutomaticReconnect()
                .Build();

            connection.On<string, string>("ReceiveMessage", (user, message) =>
            {
                this.Dispatcher.Invoke(() =>
                {
                    var newMessage = $"{user}: {message}";
                    messages.Items.Add(newMessage);
                });
            });

            try
            {
                await connection.StartAsync();
                messages.Items.Add("Connection Startted");
                connect.IsEnabled = false;
                sendMessage.IsEnabled = true;
                messages.Items.Clear();
            }
            catch (Exception ex)
            {
                messages.Items.Add(ex.Message);
            }
        }

        private async void sendMessage_Click(object sender, RoutedEventArgs e)
        {
            try
            {
                await connection.InvokeAsync("SendMessage", userInput.Text, messageInput.Text);
                messageInput.Clear();
            }
            catch (Exception ex)
            {
                messages.Items.Add(ex.Message);
            }
        }

        private async void disconnect_Click(object sender, RoutedEventArgs e)
        {
            await connection.StopAsync();
            connect.IsEnabled = true;
            sendMessage.IsEnabled = false;
        }
    }
}