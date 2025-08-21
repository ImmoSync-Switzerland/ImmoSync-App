import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('fr'),
    Locale('it')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ImmoLink'**
  String get appTitle;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @properties.
  ///
  /// In en, this message translates to:
  /// **'Properties'**
  String get properties;

  /// No description provided for @tenants.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenants;

  /// No description provided for @services.
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// No description provided for @messages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @italian.
  ///
  /// In en, this message translates to:
  /// **'Italian'**
  String get italian;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get selectLanguage;

  /// No description provided for @selectTheme.
  ///
  /// In en, this message translates to:
  /// **'Select Theme'**
  String get selectTheme;

  /// No description provided for @selectCurrency.
  ///
  /// In en, this message translates to:
  /// **'Select Currency'**
  String get selectCurrency;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @languageChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChangedTo(Object language);

  /// No description provided for @themeChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Theme changed to {theme}'**
  String themeChangedTo(Object theme);

  /// No description provided for @currencyChangedTo.
  ///
  /// In en, this message translates to:
  /// **'Currency changed to {currency}'**
  String currencyChangedTo(Object currency);

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @totalProperties.
  ///
  /// In en, this message translates to:
  /// **'Total Properties'**
  String get totalProperties;

  /// No description provided for @monthlyRevenue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Revenue'**
  String get monthlyRevenue;

  /// No description provided for @occupancyRate.
  ///
  /// In en, this message translates to:
  /// **'Occupancy Rate'**
  String get occupancyRate;

  /// No description provided for @maintenanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Requests'**
  String get maintenanceRequests;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @searchConversations.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversations;

  /// No description provided for @searchProperties.
  ///
  /// In en, this message translates to:
  /// **'Search properties...'**
  String get searchProperties;

  /// No description provided for @noConversations.
  ///
  /// In en, this message translates to:
  /// **'No conversations found'**
  String get noConversations;

  /// No description provided for @noProperties.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noProperties;

  /// No description provided for @propertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Property Details'**
  String get propertyDetails;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @occupied.
  ///
  /// In en, this message translates to:
  /// **'Occupied'**
  String get occupied;

  /// No description provided for @maintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get maintenance;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @mapNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Map not available'**
  String get mapNotAvailable;

  /// No description provided for @contactLandlord.
  ///
  /// In en, this message translates to:
  /// **'Contact Landlord'**
  String get contactLandlord;

  /// No description provided for @statusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get statusAvailable;

  /// No description provided for @statusRented.
  ///
  /// In en, this message translates to:
  /// **'Rented'**
  String get statusRented;

  /// No description provided for @statusMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get statusMaintenance;

  /// No description provided for @newMessage.
  ///
  /// In en, this message translates to:
  /// **'New Message'**
  String get newMessage;

  /// No description provided for @typeMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @revenueReport.
  ///
  /// In en, this message translates to:
  /// **'Revenue Report'**
  String get revenueReport;

  /// No description provided for @occupancyReport.
  ///
  /// In en, this message translates to:
  /// **'Occupancy Report'**
  String get occupancyReport;

  /// No description provided for @maintenanceReport.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Report'**
  String get maintenanceReport;

  /// No description provided for @generateReport.
  ///
  /// In en, this message translates to:
  /// **'Generate Report'**
  String get generateReport;

  /// No description provided for @emailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Email Notifications'**
  String get emailNotifications;

  /// No description provided for @pushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get pushNotifications;

  /// No description provided for @paymentReminders.
  ///
  /// In en, this message translates to:
  /// **'Payment Reminders'**
  String get paymentReminders;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @unknownProperty.
  ///
  /// In en, this message translates to:
  /// **'Unknown Property'**
  String get unknownProperty;

  /// No description provided for @user.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// No description provided for @tenantManagement.
  ///
  /// In en, this message translates to:
  /// **'Tenant Management'**
  String get tenantManagement;

  /// No description provided for @manageTenantDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your tenants and their property assignments'**
  String get manageTenantDescription;

  /// No description provided for @totalTenants.
  ///
  /// In en, this message translates to:
  /// **'Total Tenants'**
  String get totalTenants;

  /// No description provided for @activeTenants.
  ///
  /// In en, this message translates to:
  /// **'Active Tenants'**
  String get activeTenants;

  /// No description provided for @occupiedUnits.
  ///
  /// In en, this message translates to:
  /// **'Occupied Units'**
  String get occupiedUnits;

  /// No description provided for @pendingIssues.
  ///
  /// In en, this message translates to:
  /// **'Pending Issues'**
  String get pendingIssues;

  /// No description provided for @propertiesAssigned.
  ///
  /// In en, this message translates to:
  /// **'Properties Assigned'**
  String get propertiesAssigned;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @noTenantsFound.
  ///
  /// In en, this message translates to:
  /// **'No tenants found'**
  String get noTenantsFound;

  /// No description provided for @noTenantsYet.
  ///
  /// In en, this message translates to:
  /// **'No Tenants Yet'**
  String get noTenantsYet;

  /// No description provided for @addPropertiesInviteTenants.
  ///
  /// In en, this message translates to:
  /// **'Add properties and invite tenants to get started'**
  String get addPropertiesInviteTenants;

  /// No description provided for @addProperty.
  ///
  /// In en, this message translates to:
  /// **'Add Property'**
  String get addProperty;

  /// No description provided for @addTenant.
  ///
  /// In en, this message translates to:
  /// **'Add Tenant'**
  String get addTenant;

  /// No description provided for @loadingTenants.
  ///
  /// In en, this message translates to:
  /// **'Loading tenants...'**
  String get loadingTenants;

  /// No description provided for @errorLoadingTenants.
  ///
  /// In en, this message translates to:
  /// **'Error loading tenants'**
  String get errorLoadingTenants;

  /// No description provided for @pleaseTryAgainLater.
  ///
  /// In en, this message translates to:
  /// **'Please try again later'**
  String get pleaseTryAgainLater;

  /// No description provided for @retryLoading.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryLoading;

  /// No description provided for @editTenant.
  ///
  /// In en, this message translates to:
  /// **'Edit Tenant'**
  String get editTenant;

  /// No description provided for @deleteTenant.
  ///
  /// In en, this message translates to:
  /// **'Delete Tenant'**
  String get deleteTenant;

  /// No description provided for @tenantDetails.
  ///
  /// In en, this message translates to:
  /// **'Tenant Details'**
  String get tenantDetails;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @searchTenants.
  ///
  /// In en, this message translates to:
  /// **'Search tenants...'**
  String get searchTenants;

  /// No description provided for @myProperties.
  ///
  /// In en, this message translates to:
  /// **'My Properties'**
  String get myProperties;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @rented.
  ///
  /// In en, this message translates to:
  /// **'RENTED'**
  String get rented;

  /// No description provided for @monthlyRent.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent'**
  String get monthlyRent;

  /// No description provided for @size.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get size;

  /// No description provided for @rooms.
  ///
  /// In en, this message translates to:
  /// **'Rooms'**
  String get rooms;

  /// No description provided for @noPropertiesFound.
  ///
  /// In en, this message translates to:
  /// **'No properties found'**
  String get noPropertiesFound;

  /// No description provided for @addFirstProperty.
  ///
  /// In en, this message translates to:
  /// **'Add your first property to get started'**
  String get addFirstProperty;

  /// No description provided for @noPropertiesAssigned.
  ///
  /// In en, this message translates to:
  /// **'No properties assigned to this tenant'**
  String get noPropertiesAssigned;

  /// No description provided for @contactLandlordForAccess.
  ///
  /// In en, this message translates to:
  /// **'Contact your landlord to get access to your property'**
  String get contactLandlordForAccess;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @noConversationsYet.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get noConversationsYet;

  /// No description provided for @tryAdjustingSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustingSearch;

  /// No description provided for @startConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation with your properties'**
  String get startConversation;

  /// No description provided for @newConversation.
  ///
  /// In en, this message translates to:
  /// **'New Conversation'**
  String get newConversation;

  /// No description provided for @propertySelectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Property selection will be implemented with database integration'**
  String get propertySelectionMessage;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @landlords.
  ///
  /// In en, this message translates to:
  /// **'Landlords'**
  String get landlords;

  /// No description provided for @errorLoadingContacts.
  ///
  /// In en, this message translates to:
  /// **'Error loading contacts'**
  String get errorLoadingContacts;

  /// No description provided for @noContactsFound.
  ///
  /// In en, this message translates to:
  /// **'No contacts found'**
  String get noContactsFound;

  /// No description provided for @noLandlordsFound.
  ///
  /// In en, this message translates to:
  /// **'No landlords found'**
  String get noLandlordsFound;

  /// No description provided for @addPropertiesToConnect.
  ///
  /// In en, this message translates to:
  /// **'Add properties to connect with tenants'**
  String get addPropertiesToConnect;

  /// No description provided for @landlordContactsAppear.
  ///
  /// In en, this message translates to:
  /// **'Your landlord contacts will appear here'**
  String get landlordContactsAppear;

  /// No description provided for @property.
  ///
  /// In en, this message translates to:
  /// **'Property'**
  String get property;

  /// No description provided for @call.
  ///
  /// In en, this message translates to:
  /// **'Call'**
  String get call;

  /// No description provided for @message.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @openChat.
  ///
  /// In en, this message translates to:
  /// **'Open Chat'**
  String get openChat;

  /// No description provided for @phoneCallFunctionality.
  ///
  /// In en, this message translates to:
  /// **'Phone call functionality will be implemented'**
  String get phoneCallFunctionality;

  /// No description provided for @contactInformation.
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// No description provided for @assignedProperties.
  ///
  /// In en, this message translates to:
  /// **'Assigned Properties'**
  String get assignedProperties;

  /// No description provided for @filterOptions.
  ///
  /// In en, this message translates to:
  /// **'Filter options will be implemented'**
  String get filterOptions;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'disabled'**
  String get disabled;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @privacySettingsMessage.
  ///
  /// In en, this message translates to:
  /// **'Privacy settings will be available soon'**
  String get privacySettingsMessage;

  /// No description provided for @receiveUpdatesEmail.
  ///
  /// In en, this message translates to:
  /// **'Receive updates via email'**
  String get receiveUpdatesEmail;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @viewProperties.
  ///
  /// In en, this message translates to:
  /// **'View Properties'**
  String get viewProperties;

  /// No description provided for @outstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get outstanding;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @amenities.
  ///
  /// In en, this message translates to:
  /// **'Amenities'**
  String get amenities;

  /// No description provided for @balcony.
  ///
  /// In en, this message translates to:
  /// **'Balcony'**
  String get balcony;

  /// No description provided for @elevator.
  ///
  /// In en, this message translates to:
  /// **'Elevator'**
  String get elevator;

  /// No description provided for @laundry.
  ///
  /// In en, this message translates to:
  /// **'Laundry'**
  String get laundry;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @financialDetails.
  ///
  /// In en, this message translates to:
  /// **'Financial Details'**
  String get financialDetails;

  /// No description provided for @inviteTenant.
  ///
  /// In en, this message translates to:
  /// **'Invite Tenant'**
  String get inviteTenant;

  /// No description provided for @outstandingPayments.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Payments'**
  String get outstandingPayments;

  /// No description provided for @searchContacts.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContacts;

  /// No description provided for @searchPropertiesTenantsMessages.
  ///
  /// In en, this message translates to:
  /// **'Search properties, tenants, messages...'**
  String get searchPropertiesTenantsMessages;

  /// No description provided for @typeAMessage.
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeAMessage;

  /// No description provided for @managePropertiesAndTenants.
  ///
  /// In en, this message translates to:
  /// **'Manage your properties and tenants'**
  String get managePropertiesAndTenants;

  /// No description provided for @monthlyIncome.
  ///
  /// In en, this message translates to:
  /// **'Monthly Income'**
  String get monthlyIncome;

  /// No description provided for @squareMeters.
  ///
  /// In en, this message translates to:
  /// **'m²'**
  String get squareMeters;

  /// No description provided for @chfPerMonth.
  ///
  /// In en, this message translates to:
  /// **'CHF/month'**
  String get chfPerMonth;

  /// No description provided for @propertyDescription.
  ///
  /// In en, this message translates to:
  /// **'Modern property located in a prime location with excellent amenities and convenient access to public transportation.'**
  String get propertyDescription;

  /// No description provided for @landlord.
  ///
  /// In en, this message translates to:
  /// **'Landlord'**
  String get landlord;

  /// No description provided for @updateYourInformation.
  ///
  /// In en, this message translates to:
  /// **'Update your personal information'**
  String get updateYourInformation;

  /// No description provided for @appSettings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update your password'**
  String get updatePassword;

  /// No description provided for @signOutOfAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account'**
  String get signOutOfAccount;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Confirm Logout'**
  String get confirmLogout;

  /// No description provided for @logoutConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get logoutConfirmation;

  /// No description provided for @searchToFindResults.
  ///
  /// In en, this message translates to:
  /// **'Start typing to find results'**
  String get searchToFindResults;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search for properties, tenants, or messages'**
  String get searchHint;

  /// No description provided for @noResultsFound.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get noResultsFound;

  /// No description provided for @tryDifferentSearch.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// No description provided for @filterProperties.
  ///
  /// In en, this message translates to:
  /// **'Filter Properties'**
  String get filterProperties;

  /// No description provided for @filterRequests.
  ///
  /// In en, this message translates to:
  /// **'Filter Requests'**
  String get filterRequests;

  /// No description provided for @pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// No description provided for @inProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// No description provided for @cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// No description provided for @priority.
  ///
  /// In en, this message translates to:
  /// **'Priority'**
  String get priority;

  /// No description provided for @low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get low;

  /// No description provided for @medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get medium;

  /// No description provided for @high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get high;

  /// No description provided for @emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get emergency;

  /// No description provided for @noMaintenanceRequests.
  ///
  /// In en, this message translates to:
  /// **'No maintenance requests'**
  String get noMaintenanceRequests;

  /// No description provided for @noMaintenanceRequestsDescription.
  ///
  /// In en, this message translates to:
  /// **'All maintenance requests will appear here'**
  String get noMaintenanceRequestsDescription;

  /// No description provided for @getDirections.
  ///
  /// In en, this message translates to:
  /// **'Get Directions'**
  String get getDirections;

  /// No description provided for @locationNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Location not available'**
  String get locationNotAvailable;

  /// No description provided for @addressDisplayOnly.
  ///
  /// In en, this message translates to:
  /// **'Address shown for reference only'**
  String get addressDisplayOnly;

  /// No description provided for @twoFactorAuth.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuth;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact Support'**
  String get contactSupport;

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'enabled'**
  String get enabled;

  /// No description provided for @pushNotificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive updates on your device'**
  String get pushNotificationSubtitle;

  /// No description provided for @paymentReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get reminded about upcoming payments'**
  String get paymentReminderSubtitle;

  /// No description provided for @welcomeToHelpCenter.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Help Center'**
  String get welcomeToHelpCenter;

  /// No description provided for @helpCenterDescription.
  ///
  /// In en, this message translates to:
  /// **'Find answers to common questions, learn how to use ImmoLink features, and get support when you need it.'**
  String get helpCenterDescription;

  /// No description provided for @quickLinks.
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// No description provided for @gettingStarted.
  ///
  /// In en, this message translates to:
  /// **'Getting Started'**
  String get gettingStarted;

  /// No description provided for @gettingStartedDescription.
  ///
  /// In en, this message translates to:
  /// **'Learn the basics of using ImmoLink'**
  String get gettingStartedDescription;

  /// No description provided for @accountSettings.
  ///
  /// In en, this message translates to:
  /// **'Account & Settings'**
  String get accountSettings;

  /// No description provided for @accountSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your account and privacy settings'**
  String get accountSettingsDescription;

  /// No description provided for @propertyManagement.
  ///
  /// In en, this message translates to:
  /// **'Property Management'**
  String get propertyManagement;

  /// No description provided for @propertyManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'How to add and manage properties'**
  String get propertyManagementDescription;

  /// No description provided for @paymentsBilling.
  ///
  /// In en, this message translates to:
  /// **'Payments & Billing'**
  String get paymentsBilling;

  /// No description provided for @paymentsBillingDescription.
  ///
  /// In en, this message translates to:
  /// **'Understanding payments and billing'**
  String get paymentsBillingDescription;

  /// No description provided for @frequentlyAskedQuestions.
  ///
  /// In en, this message translates to:
  /// **'Frequently Asked Questions'**
  String get frequentlyAskedQuestions;

  /// No description provided for @howToAddProperty.
  ///
  /// In en, this message translates to:
  /// **'How do I add a new property?'**
  String get howToAddProperty;

  /// No description provided for @howToAddPropertyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to the Properties tab and tap the \"+\" button. Fill in the property details, add photos, and save.'**
  String get howToAddPropertyAnswer;

  /// No description provided for @howToInviteTenant.
  ///
  /// In en, this message translates to:
  /// **'How do I invite a tenant?'**
  String get howToInviteTenant;

  /// No description provided for @howToInviteTenantAnswer.
  ///
  /// In en, this message translates to:
  /// **'Open a property and tap \"Invite Tenant\". Enter their email address and they will receive an invitation.'**
  String get howToInviteTenantAnswer;

  /// No description provided for @howToChangeCurrency.
  ///
  /// In en, this message translates to:
  /// **'How do I change my currency?'**
  String get howToChangeCurrency;

  /// No description provided for @howToChangeCurrencyAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Preferences > Currency and select your preferred currency.'**
  String get howToChangeCurrencyAnswer;

  /// No description provided for @howToEnable2FA.
  ///
  /// In en, this message translates to:
  /// **'How do I enable two-factor authentication?'**
  String get howToEnable2FA;

  /// No description provided for @howToEnable2FAAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Security > Two-Factor Authentication and follow the setup instructions.'**
  String get howToEnable2FAAnswer;

  /// No description provided for @howToExportData.
  ///
  /// In en, this message translates to:
  /// **'How do I export my data?'**
  String get howToExportData;

  /// No description provided for @howToExportDataAnswer.
  ///
  /// In en, this message translates to:
  /// **'Go to Settings > Privacy Settings > Data Management > Export My Data.'**
  String get howToExportDataAnswer;

  /// No description provided for @userGuides.
  ///
  /// In en, this message translates to:
  /// **'User Guides'**
  String get userGuides;

  /// No description provided for @landlordGuide.
  ///
  /// In en, this message translates to:
  /// **'Landlord Guide'**
  String get landlordGuide;

  /// No description provided for @landlordGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete guide for landlords'**
  String get landlordGuideDescription;

  /// No description provided for @tenantGuide.
  ///
  /// In en, this message translates to:
  /// **'Tenant Guide'**
  String get tenantGuide;

  /// No description provided for @tenantGuideDescription.
  ///
  /// In en, this message translates to:
  /// **'Complete guide for tenants'**
  String get tenantGuideDescription;

  /// No description provided for @securityBestPractices.
  ///
  /// In en, this message translates to:
  /// **'Security Best Practices'**
  String get securityBestPractices;

  /// No description provided for @securityBestPracticesDescription.
  ///
  /// In en, this message translates to:
  /// **'Keep your account secure'**
  String get securityBestPracticesDescription;

  /// No description provided for @needMoreHelp.
  ///
  /// In en, this message translates to:
  /// **'Need More Help?'**
  String get needMoreHelp;

  /// No description provided for @needMoreHelpDescription.
  ///
  /// In en, this message translates to:
  /// **'Can\'t find what you\'re looking for? Our support team is here to help.'**
  String get needMoreHelpDescription;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// No description provided for @gettingStartedWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ImmoLink! Here\'s how to get started:'**
  String get gettingStartedWelcome;

  /// No description provided for @gettingStartedStep1.
  ///
  /// In en, this message translates to:
  /// **'1. Complete your profile'**
  String get gettingStartedStep1;

  /// No description provided for @gettingStartedStep2.
  ///
  /// In en, this message translates to:
  /// **'2. Add your first property'**
  String get gettingStartedStep2;

  /// No description provided for @gettingStartedStep3.
  ///
  /// In en, this message translates to:
  /// **'3. Invite tenants or connect with landlords'**
  String get gettingStartedStep3;

  /// No description provided for @gettingStartedStep4.
  ///
  /// In en, this message translates to:
  /// **'4. Start managing your properties'**
  String get gettingStartedStep4;

  /// No description provided for @propertyManagementGuide.
  ///
  /// In en, this message translates to:
  /// **'Managing properties in ImmoLink:'**
  String get propertyManagementGuide;

  /// No description provided for @propertyManagementTip1.
  ///
  /// In en, this message translates to:
  /// **'• Add property details and photos'**
  String get propertyManagementTip1;

  /// No description provided for @propertyManagementTip2.
  ///
  /// In en, this message translates to:
  /// **'• Set rental prices and terms'**
  String get propertyManagementTip2;

  /// No description provided for @propertyManagementTip3.
  ///
  /// In en, this message translates to:
  /// **'• Invite tenants to view or rent'**
  String get propertyManagementTip3;

  /// No description provided for @propertyManagementTip4.
  ///
  /// In en, this message translates to:
  /// **'• Track maintenance requests'**
  String get propertyManagementTip4;

  /// No description provided for @propertyManagementTip5.
  ///
  /// In en, this message translates to:
  /// **'• Monitor payment status'**
  String get propertyManagementTip5;

  /// No description provided for @paymentsGuide.
  ///
  /// In en, this message translates to:
  /// **'Understanding payments in ImmoLink:'**
  String get paymentsGuide;

  /// No description provided for @paymentsTip1.
  ///
  /// In en, this message translates to:
  /// **'• View payment history and status'**
  String get paymentsTip1;

  /// No description provided for @paymentsTip2.
  ///
  /// In en, this message translates to:
  /// **'• Set up automatic payment reminders'**
  String get paymentsTip2;

  /// No description provided for @paymentsTip3.
  ///
  /// In en, this message translates to:
  /// **'• Track outstanding payments'**
  String get paymentsTip3;

  /// No description provided for @paymentsTip4.
  ///
  /// In en, this message translates to:
  /// **'• Generate payment reports'**
  String get paymentsTip4;

  /// No description provided for @paymentsTip5.
  ///
  /// In en, this message translates to:
  /// **'• Export payment data'**
  String get paymentsTip5;

  /// No description provided for @landlordGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Complete guide for landlords:'**
  String get landlordGuideContent;

  /// No description provided for @landlordTip1.
  ///
  /// In en, this message translates to:
  /// **'• Property portfolio management'**
  String get landlordTip1;

  /// No description provided for @landlordTip2.
  ///
  /// In en, this message translates to:
  /// **'• Tenant screening and onboarding'**
  String get landlordTip2;

  /// No description provided for @landlordTip3.
  ///
  /// In en, this message translates to:
  /// **'• Rent collection and tracking'**
  String get landlordTip3;

  /// No description provided for @landlordTip4.
  ///
  /// In en, this message translates to:
  /// **'• Maintenance request handling'**
  String get landlordTip4;

  /// No description provided for @landlordTip5.
  ///
  /// In en, this message translates to:
  /// **'• Financial reporting and analytics'**
  String get landlordTip5;

  /// No description provided for @landlordTip6.
  ///
  /// In en, this message translates to:
  /// **'• Legal compliance and documentation'**
  String get landlordTip6;

  /// No description provided for @tenantGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Complete guide for tenants:'**
  String get tenantGuideContent;

  /// No description provided for @tenantTip1.
  ///
  /// In en, this message translates to:
  /// **'• Property search and viewing'**
  String get tenantTip1;

  /// No description provided for @tenantTip2.
  ///
  /// In en, this message translates to:
  /// **'• Rental application process'**
  String get tenantTip2;

  /// No description provided for @tenantTip3.
  ///
  /// In en, this message translates to:
  /// **'• Lease agreements and documentation'**
  String get tenantTip3;

  /// No description provided for @tenantTip4.
  ///
  /// In en, this message translates to:
  /// **'• Rent payment and history'**
  String get tenantTip4;

  /// No description provided for @tenantTip5.
  ///
  /// In en, this message translates to:
  /// **'• Maintenance request submission'**
  String get tenantTip5;

  /// No description provided for @tenantTip6.
  ///
  /// In en, this message translates to:
  /// **'• Communication with landlords'**
  String get tenantTip6;

  /// No description provided for @securityGuideContent.
  ///
  /// In en, this message translates to:
  /// **'Keep your account secure:'**
  String get securityGuideContent;

  /// No description provided for @securityTip1.
  ///
  /// In en, this message translates to:
  /// **'• Use a strong, unique password'**
  String get securityTip1;

  /// No description provided for @securityTip2.
  ///
  /// In en, this message translates to:
  /// **'• Enable two-factor authentication'**
  String get securityTip2;

  /// No description provided for @securityTip3.
  ///
  /// In en, this message translates to:
  /// **'• Review privacy settings regularly'**
  String get securityTip3;

  /// No description provided for @securityTip4.
  ///
  /// In en, this message translates to:
  /// **'• Be cautious with shared information'**
  String get securityTip4;

  /// No description provided for @securityTip5.
  ///
  /// In en, this message translates to:
  /// **'• Report suspicious activity immediately'**
  String get securityTip5;

  /// No description provided for @securityTip6.
  ///
  /// In en, this message translates to:
  /// **'• Keep the app updated'**
  String get securityTip6;

  /// No description provided for @weAreHereToHelp.
  ///
  /// In en, this message translates to:
  /// **'We\'re Here to Help'**
  String get weAreHereToHelp;

  /// No description provided for @supportTeamDescription.
  ///
  /// In en, this message translates to:
  /// **'Our support team is ready to assist you with any questions or issues you may have. Choose how you\'d like to get in touch.'**
  String get supportTeamDescription;

  /// No description provided for @quickContact.
  ///
  /// In en, this message translates to:
  /// **'Quick Contact'**
  String get quickContact;

  /// No description provided for @emailUs.
  ///
  /// In en, this message translates to:
  /// **'Email Us'**
  String get emailUs;

  /// No description provided for @callUs.
  ///
  /// In en, this message translates to:
  /// **'Call Us'**
  String get callUs;

  /// No description provided for @liveChat.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChat;

  /// No description provided for @submitSupportRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit a Support Request'**
  String get submitSupportRequest;

  /// No description provided for @supportFormDescription.
  ///
  /// In en, this message translates to:
  /// **'Fill out the form below and we\'ll get back to you as soon as possible.'**
  String get supportFormDescription;

  /// No description provided for @accountInformation.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get accountInformation;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @notAvailable.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @accountAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Account & Settings'**
  String get accountAndSettings;

  /// No description provided for @technicalIssues.
  ///
  /// In en, this message translates to:
  /// **'Technical Issues'**
  String get technicalIssues;

  /// No description provided for @securityConcerns.
  ///
  /// In en, this message translates to:
  /// **'Security Concerns'**
  String get securityConcerns;

  /// No description provided for @featureRequest.
  ///
  /// In en, this message translates to:
  /// **'Feature Request'**
  String get featureRequest;

  /// No description provided for @bugReport.
  ///
  /// In en, this message translates to:
  /// **'Bug Report'**
  String get bugReport;

  /// No description provided for @urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgent;

  /// No description provided for @subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get subject;

  /// No description provided for @subjectHint.
  ///
  /// In en, this message translates to:
  /// **'Brief description of your issue'**
  String get subjectHint;

  /// No description provided for @pleaseEnterSubject.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get pleaseEnterSubject;

  /// No description provided for @describeYourIssue.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue'**
  String get describeYourIssue;

  /// No description provided for @issueDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Please provide as much detail as possible to help us assist you better'**
  String get issueDescriptionHint;

  /// No description provided for @pleaseDescribeIssue.
  ///
  /// In en, this message translates to:
  /// **'Please describe your issue'**
  String get pleaseDescribeIssue;

  /// No description provided for @provideMoreDetails.
  ///
  /// In en, this message translates to:
  /// **'Please provide more details (at least 10 characters)'**
  String get provideMoreDetails;

  /// No description provided for @submitRequest.
  ///
  /// In en, this message translates to:
  /// **'Submit Request'**
  String get submitRequest;

  /// No description provided for @supportInformation.
  ///
  /// In en, this message translates to:
  /// **'Support Information'**
  String get supportInformation;

  /// No description provided for @responseTime.
  ///
  /// In en, this message translates to:
  /// **'Response Time'**
  String get responseTime;

  /// No description provided for @responseTimeInfo.
  ///
  /// In en, this message translates to:
  /// **'Usually within 24 hours'**
  String get responseTimeInfo;

  /// No description provided for @languages.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languages;

  /// No description provided for @languagesSupported.
  ///
  /// In en, this message translates to:
  /// **'English, German, French, Italian'**
  String get languagesSupported;

  /// No description provided for @supportHours.
  ///
  /// In en, this message translates to:
  /// **'Support Hours'**
  String get supportHours;

  /// No description provided for @supportHoursInfo.
  ///
  /// In en, this message translates to:
  /// **'Monday-Friday, 9:00-18:00 CET'**
  String get supportHoursInfo;

  /// No description provided for @emergencyInfo.
  ///
  /// In en, this message translates to:
  /// **'For urgent issues, call +41 800 123 456'**
  String get emergencyInfo;

  /// No description provided for @couldNotOpenEmail.
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get couldNotOpenEmail;

  /// No description provided for @couldNotOpenPhone.
  ///
  /// In en, this message translates to:
  /// **'Could not open phone app'**
  String get couldNotOpenPhone;

  /// No description provided for @liveChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Live Chat'**
  String get liveChatTitle;

  /// No description provided for @liveChatAvailable.
  ///
  /// In en, this message translates to:
  /// **'Live chat is currently available during business hours (Monday-Friday, 9:00-18:00 CET).'**
  String get liveChatAvailable;

  /// No description provided for @liveChatOutsideHours.
  ///
  /// In en, this message translates to:
  /// **'For immediate assistance outside business hours, please use the support form or send us an email.'**
  String get liveChatOutsideHours;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @startChat.
  ///
  /// In en, this message translates to:
  /// **'Start Chat'**
  String get startChat;

  /// No description provided for @liveChatSoon.
  ///
  /// In en, this message translates to:
  /// **'Live chat feature will be available soon'**
  String get liveChatSoon;

  /// No description provided for @supportRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Support request submitted successfully! We\'ll get back to you soon.'**
  String get supportRequestSubmitted;

  /// No description provided for @myTenants.
  ///
  /// In en, this message translates to:
  /// **'My Tenants'**
  String get myTenants;

  /// No description provided for @myLandlords.
  ///
  /// In en, this message translates to:
  /// **'My Landlords'**
  String get myLandlords;

  /// No description provided for @maintenanceRequestDetails.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Request Details'**
  String get maintenanceRequestDetails;

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block User'**
  String get blockUser;

  /// No description provided for @reportConversation.
  ///
  /// In en, this message translates to:
  /// **'Report Conversation'**
  String get reportConversation;

  /// No description provided for @deleteConversation.
  ///
  /// In en, this message translates to:
  /// **'Delete Conversation'**
  String get deleteConversation;

  /// No description provided for @myMaintenanceRequests.
  ///
  /// In en, this message translates to:
  /// **'My Maintenance Requests'**
  String get myMaintenanceRequests;

  /// No description provided for @errorLoadingRequests.
  ///
  /// In en, this message translates to:
  /// **'Error loading maintenance requests'**
  String get errorLoadingRequests;

  /// No description provided for @createRequest.
  ///
  /// In en, this message translates to:
  /// **'Create Request'**
  String get createRequest;

  /// No description provided for @created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get created;

  /// No description provided for @updated.
  ///
  /// In en, this message translates to:
  /// **'Updated'**
  String get updated;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @statusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get statusCancelled;

  /// No description provided for @priorityHigh.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get priorityHigh;

  /// No description provided for @priorityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get priorityMedium;

  /// No description provided for @priorityLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get priorityLow;

  /// No description provided for @addNote.
  ///
  /// In en, this message translates to:
  /// **'Add Note'**
  String get addNote;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid'**
  String get invalid;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @success.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @view.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @upload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get upload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @select.
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// No description provided for @choose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @sort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @searchServices.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get searchServices;

  /// No description provided for @confirmBooking.
  ///
  /// In en, this message translates to:
  /// **'Confirm Booking'**
  String get confirmBooking;

  /// No description provided for @bookingConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Booking Confirmed'**
  String get bookingConfirmed;

  /// No description provided for @unableToOpenChat.
  ///
  /// In en, this message translates to:
  /// **'Unable to open chat. Please try again.'**
  String get unableToOpenChat;

  /// No description provided for @failedToSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Failed to send message'**
  String get failedToSendMessage;

  /// No description provided for @chooseExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose export format:'**
  String get chooseExportFormat;

  /// No description provided for @errorLoadingPayments.
  ///
  /// In en, this message translates to:
  /// **'Error loading payments'**
  String get errorLoadingPayments;

  /// No description provided for @errorLoadingProperties.
  ///
  /// In en, this message translates to:
  /// **'Error loading properties'**
  String get errorLoadingProperties;

  /// No description provided for @errorLoadingPropertyMetrics.
  ///
  /// In en, this message translates to:
  /// **'Error loading property metrics'**
  String get errorLoadingPropertyMetrics;

  /// No description provided for @errorLoadingMaintenanceData.
  ///
  /// In en, this message translates to:
  /// **'Error loading maintenance data'**
  String get errorLoadingMaintenanceData;

  /// No description provided for @errorLoadingPaymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Error loading payment summary'**
  String get errorLoadingPaymentSummary;

  /// No description provided for @errorLoadingMaintenanceRequests.
  ///
  /// In en, this message translates to:
  /// **'Error loading maintenance requests'**
  String get errorLoadingMaintenanceRequests;

  /// No description provided for @errorLoadingPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading payment history'**
  String get errorLoadingPaymentHistory;

  /// No description provided for @searchConversationsHint.
  ///
  /// In en, this message translates to:
  /// **'Search conversations...'**
  String get searchConversationsHint;

  /// No description provided for @searchContactsHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts...'**
  String get searchContactsHint;

  /// No description provided for @failedToStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Failed to start conversation'**
  String get failedToStartConversation;

  /// No description provided for @searchPropertiesMaintenanceMessages.
  ///
  /// In en, this message translates to:
  /// **'Search properties, maintenance, messages...'**
  String get searchPropertiesMaintenanceMessages;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorGeneric;

  /// No description provided for @pleaseSelectProperty.
  ///
  /// In en, this message translates to:
  /// **'Please select a property'**
  String get pleaseSelectProperty;

  /// No description provided for @maintenanceRequestSubmittedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request submitted successfully'**
  String get maintenanceRequestSubmittedSuccessfully;

  /// No description provided for @failedToSubmitRequest.
  ///
  /// In en, this message translates to:
  /// **'Failed to submit request'**
  String get failedToSubmitRequest;

  /// No description provided for @statusUpdatedTo.
  ///
  /// In en, this message translates to:
  /// **'Status updated to'**
  String get statusUpdatedTo;

  /// No description provided for @failedToUpdateStatus.
  ///
  /// In en, this message translates to:
  /// **'Failed to update status'**
  String get failedToUpdateStatus;

  /// No description provided for @noteAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Note added successfully'**
  String get noteAddedSuccessfully;

  /// No description provided for @failedToAddNote.
  ///
  /// In en, this message translates to:
  /// **'Failed to add note'**
  String get failedToAddNote;

  /// No description provided for @filterOptionsWillBeImplemented.
  ///
  /// In en, this message translates to:
  /// **'Filter options will be implemented'**
  String get filterOptionsWillBeImplemented;

  /// No description provided for @imagesSelected.
  ///
  /// In en, this message translates to:
  /// **'image(s) selected'**
  String get imagesSelected;

  /// No description provided for @noImagesSelected.
  ///
  /// In en, this message translates to:
  /// **'No images selected'**
  String get noImagesSelected;

  /// No description provided for @errorSelectingImages.
  ///
  /// In en, this message translates to:
  /// **'Error selecting images'**
  String get errorSelectingImages;

  /// No description provided for @propertyUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property updated successfully!'**
  String get propertyUpdatedSuccessfully;

  /// No description provided for @propertyCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Property created successfully!'**
  String get propertyCreatedSuccessfully;

  /// No description provided for @deleteService.
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// No description provided for @serviceDeleted.
  ///
  /// In en, this message translates to:
  /// **'Service deleted'**
  String get serviceDeleted;

  /// No description provided for @searchPropertiesLandlordsMessages.
  ///
  /// In en, this message translates to:
  /// **'Search properties, landlords, messages...'**
  String get searchPropertiesLandlordsMessages;

  /// No description provided for @errorLoadingConversations.
  ///
  /// In en, this message translates to:
  /// **'Error loading conversations'**
  String get errorLoadingConversations;

  /// No description provided for @allowViewBasicProfile.
  ///
  /// In en, this message translates to:
  /// **'Allow other users to view your basic profile information'**
  String get allowViewBasicProfile;

  /// No description provided for @letUsersFindsPropertiesInSearch.
  ///
  /// In en, this message translates to:
  /// **'Let other users find your properties in search results'**
  String get letUsersFindsPropertiesInSearch;

  /// No description provided for @shareUsageAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Share Usage Analytics'**
  String get shareUsageAnalytics;

  /// No description provided for @getUpdatesAboutNewFeatures.
  ///
  /// In en, this message translates to:
  /// **'Get updates about new features, tips, and special offers'**
  String get getUpdatesAboutNewFeatures;

  /// No description provided for @downloadCopyPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your personal data'**
  String get downloadCopyPersonalData;

  /// No description provided for @permanentlyDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get permanentlyDeleteAccount;

  /// No description provided for @dataExportRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Data export request submitted. You will receive an email with the download link.'**
  String get dataExportRequestSubmitted;

  /// No description provided for @accountDeletionRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted. This feature will be available soon.'**
  String get accountDeletionRequestSubmitted;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @passwordChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// No description provided for @failedToChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Failed to change password'**
  String get failedToChangePassword;

  /// No description provided for @profileImageUploadComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Profile image upload coming soon'**
  String get profileImageUploadComingSoon;

  /// No description provided for @invalidChatParameters.
  ///
  /// In en, this message translates to:
  /// **'Invalid chat parameters'**
  String get invalidChatParameters;

  /// No description provided for @allowOtherUsersViewProfile.
  ///
  /// In en, this message translates to:
  /// **'Allow other users to view your basic profile information'**
  String get allowOtherUsersViewProfile;

  /// No description provided for @letOtherUsersFindProperties.
  ///
  /// In en, this message translates to:
  /// **'Let other users find your properties in search results'**
  String get letOtherUsersFindProperties;

  /// No description provided for @shareUsageAnalyticsDesc.
  ///
  /// In en, this message translates to:
  /// **'Share usage analytics to help improve the app'**
  String get shareUsageAnalyticsDesc;

  /// No description provided for @getUpdatesNewFeatures.
  ///
  /// In en, this message translates to:
  /// **'Get updates about new features, tips, and special offers'**
  String get getUpdatesNewFeatures;

  /// No description provided for @downloadPersonalData.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your personal data'**
  String get downloadPersonalData;

  /// No description provided for @permanentlyDeleteAccountData.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get permanentlyDeleteAccountData;

  /// No description provided for @dataExportRequestSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Data export request submitted. You will receive an email with the download link.'**
  String get dataExportRequestSubmittedMessage;

  /// No description provided for @accountDeletionRequestSubmittedMessage.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted. This feature will be available soon.'**
  String get accountDeletionRequestSubmittedMessage;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @pleaseEnterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get pleaseEnterCurrentPassword;

  /// No description provided for @pleaseEnterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get pleaseEnterNewPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get passwordTooShort;

  /// No description provided for @currentPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get currentPasswordIncorrect;

  /// No description provided for @privacyVisibility.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Visibility'**
  String get privacyVisibility;

  /// No description provided for @publicProfile.
  ///
  /// In en, this message translates to:
  /// **'Public Profile'**
  String get publicProfile;

  /// No description provided for @searchVisibility.
  ///
  /// In en, this message translates to:
  /// **'Search Visibility'**
  String get searchVisibility;

  /// No description provided for @dataAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Data & Analytics'**
  String get dataAndAnalytics;

  /// No description provided for @communicationPreferences.
  ///
  /// In en, this message translates to:
  /// **'Communication Preferences'**
  String get communicationPreferences;

  /// No description provided for @marketingEmails.
  ///
  /// In en, this message translates to:
  /// **'Marketing Emails'**
  String get marketingEmails;

  /// No description provided for @dataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get dataManagement;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export My Data'**
  String get exportMyData;

  /// No description provided for @requestDataExport.
  ///
  /// In en, this message translates to:
  /// **'Request Data Export'**
  String get requestDataExport;

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'Danger Zone'**
  String get dangerZone;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @pleaseTypeConfirmToDelete.
  ///
  /// In en, this message translates to:
  /// **'Please type \'CONFIRM\' to delete your account:'**
  String get pleaseTypeConfirmToDelete;

  /// No description provided for @typeConfirmHere.
  ///
  /// In en, this message translates to:
  /// **'Type \'CONFIRM\' here...'**
  String get typeConfirmHere;

  /// No description provided for @pleaseTypeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Please type \'CONFIRM\''**
  String get pleaseTypeConfirm;

  /// No description provided for @accountDeletion.
  ///
  /// In en, this message translates to:
  /// **'Account Deletion'**
  String get accountDeletion;

  /// No description provided for @areYouSureDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get areYouSureDeleteAccount;

  /// No description provided for @thisWillPermanentlyDelete.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your data, including:'**
  String get thisWillPermanentlyDelete;

  /// No description provided for @allProperties.
  ///
  /// In en, this message translates to:
  /// **'• All properties'**
  String get allProperties;

  /// No description provided for @allConversations.
  ///
  /// In en, this message translates to:
  /// **'• All conversations'**
  String get allConversations;

  /// No description provided for @allDocuments.
  ///
  /// In en, this message translates to:
  /// **'• All documents'**
  String get allDocuments;

  /// No description provided for @allPaymentHistory.
  ///
  /// In en, this message translates to:
  /// **'• All payment history'**
  String get allPaymentHistory;

  /// No description provided for @profileInformation.
  ///
  /// In en, this message translates to:
  /// **'• Profile information'**
  String get profileInformation;

  /// No description provided for @requestDeletion.
  ///
  /// In en, this message translates to:
  /// **'Request Deletion'**
  String get requestDeletion;

  /// No description provided for @editProfileInfo.
  ///
  /// In en, this message translates to:
  /// **'Edit your profile information'**
  String get editProfileInfo;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @bioHint.
  ///
  /// In en, this message translates to:
  /// **'Tell others about yourself...'**
  String get bioHint;

  /// No description provided for @pleaseEnterFirstName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your first name'**
  String get pleaseEnterFirstName;

  /// No description provided for @pleaseEnterLastName.
  ///
  /// In en, this message translates to:
  /// **'Please enter your last name'**
  String get pleaseEnterLastName;

  /// No description provided for @pleaseEnterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get pleaseEnterValidEmail;

  /// No description provided for @phoneNumberOptional.
  ///
  /// In en, this message translates to:
  /// **'Phone Number (optional)'**
  String get phoneNumberOptional;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @profileUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile Updated'**
  String get profileUpdated;

  /// No description provided for @profileUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// No description provided for @failedToUpdateProfile.
  ///
  /// In en, this message translates to:
  /// **'Failed to update profile'**
  String get failedToUpdateProfile;

  /// No description provided for @uploadProfileImage.
  ///
  /// In en, this message translates to:
  /// **'Upload Profile Image'**
  String get uploadProfileImage;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// No description provided for @chooseFromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @propertyManager.
  ///
  /// In en, this message translates to:
  /// **'Property Manager'**
  String get propertyManager;

  /// No description provided for @profileImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Profile image upload coming soon'**
  String get profileImageUpload;

  /// No description provided for @searchPropertiesLandlords.
  ///
  /// In en, this message translates to:
  /// **'Search properties, landlords, messages...'**
  String get searchPropertiesLandlords;

  /// No description provided for @startTypingToFindResults.
  ///
  /// In en, this message translates to:
  /// **'Start typing to find results'**
  String get startTypingToFindResults;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @twoFactorAuthentication.
  ///
  /// In en, this message translates to:
  /// **'Two-Factor Authentication'**
  String get twoFactorAuthentication;

  /// No description provided for @removeTenant.
  ///
  /// In en, this message translates to:
  /// **'Remove Tenant'**
  String get removeTenant;

  /// No description provided for @removeTenantConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this tenant from the property?'**
  String get removeTenantConfirmation;

  /// No description provided for @tenantRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tenant removed successfully'**
  String get tenantRemovedSuccessfully;

  /// No description provided for @failedToRemoveTenant.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove tenant'**
  String get failedToRemoveTenant;

  /// No description provided for @invitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get invitations;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en', 'fr', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
