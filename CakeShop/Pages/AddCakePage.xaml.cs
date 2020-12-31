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
using System.Windows.Navigation;
using System.Windows.Shapes;
using CakeShop.Utilities;

namespace CakeShop.Pages
{
	/// <summary>
	/// Interaction logic for AddCakePage.xaml
	/// </summary>
	public partial class AddCakePage : Page
	{
		private bool isUpdate = false;

		private DatabaseUtilities _databaseUtilities = DatabaseUtilities.GetDatabaseInstance();
		private Cake _cake = new Cake();

		public AddCakePage()
		{
			InitializeComponent();
			updateTextBlock.Visibility = Visibility.Collapsed;
			this.isUpdate = false;
		}

		public AddCakePage(int cakeID)
		{
			InitializeComponent();

			updateTextBlock.Visibility = Visibility.Visible;
			this.isUpdate = true;

			_cake = _databaseUtilities.getCakeById(cakeID);

			DataContext = this._cake;
		}

		private void addCakeImagesOption1Button_Click(object sender, RoutedEventArgs e)
		{

		}

		private void addCakeImagesButton_Click(object sender, RoutedEventArgs e)
		{
			addCakeImagesOption1Button.Visibility = Visibility.Collapsed;
			addCakeImagesOption2Button.Visibility = Visibility.Visible;
			cakeImageListView.Visibility = Visibility.Visible;
		}
	}
}
