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
  /// **'ImmoSync'**
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

  /// No description provided for @revenueVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Revenue vs Expenses'**
  String get revenueVsExpenses;

  /// No description provided for @totalRevenue.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue'**
  String get totalRevenue;

  /// No description provided for @totalExpenses.
  ///
  /// In en, this message translates to:
  /// **'Total Expenses'**
  String get totalExpenses;

  /// No description provided for @netIncome.
  ///
  /// In en, this message translates to:
  /// **'Net Income'**
  String get netIncome;

  /// No description provided for @monthlyRentDue.
  ///
  /// In en, this message translates to:
  /// **'Monthly Rent Due'**
  String get monthlyRentDue;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get revenue;

  /// No description provided for @expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// No description provided for @net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get net;

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

  /// No description provided for @actual.
  ///
  /// In en, this message translates to:
  /// **'Actual'**
  String get actual;

  /// No description provided for @planned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get planned;

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

  /// No description provided for @privacyPolicyLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 3 October 2025'**
  String get privacyPolicyLastUpdated;

  /// No description provided for @privacyPolicyContent.
  ///
  /// In en, this message translates to:
  /// **'This Privacy Policy explains how ImmoSync KLG (\"ImmoSync\", \"we\", \"us\") processes personal data when you use our website, applications and services (the \"Services\").\n\nImmoSync KLG, Hauptstrasse 38, 4411 Seltisberg, Baselland, Switzerland · Phone: +41 76 391 94 00 · Email: info@immosync.ch\n\nTable of Contents\n1. Controller\n2. What Data We Process\n3. Purposes and Legal Bases\n4. Cookies and Tracking\n5. Analytics and Third Parties\n6. Data Sharing\n7. International Transfers\n8. Retention\n9. Data Security\n10. Minors\n11. Your Rights\n12. How to Exercise Your Rights\n13. Changes to this Policy\n14. Contact\n1. Controller\nThe controller for data processing related to the Services is ImmoSync KLG. For certain functions (e.g. payments via Stripe or push notifications) external providers act as independent controllers or as processors.\n\n2. What Data We Process\nDepending on how you use the Services, we process among others:\n\nAccount & profile data (name, email, phone, address, roles)\nAuthentication data (password hashes, tokens)\nUsage & log data (IP address, device/browser info, actions, timestamps)\nContent you provide (messages, tickets, documents, media)\nPayment-related data (via Stripe; we do not store full card numbers)\nDevice/app data for mobile functions (notifications, contacts – only with your consent)\nCommunication data (support requests, feedback)\n\n3. Purposes and Legal Bases (GDPR / Swiss revDSG)\nProviding and operating the Services; contract performance (Art. 6(1)(b) GDPR)\nImproving security, stability, performance; legal defense (legitimate interests, Art. 6(1)(f) GDPR)\nCommunicating with you (contract, legitimate interests or consent)\nBilling and complying with legal obligations (Art. 6(1)(c) GDPR)\nOptional features based on your consent (Art. 6(1)(a) GDPR); consent may be withdrawn at any time\n\n4. Cookies and Tracking\nWe use necessary cookies for core functionality and may use analytics cookies to understand usage. You can control cookies in your browser settings. Disabling non‑essential cookies may impact functionality.\n\n5. Analytics and Third Parties\nWe use trusted providers for infrastructure, analytics, payments, messaging and error monitoring. These providers process data only as required to deliver their services and in compliance with applicable data protection laws.\n\nExamples: Hosting (e.g. Vercel/AWS), Payments (Stripe), Analytics (privacy‑friendly tools or—where permitted—Google Analytics), communication services.\n\n6. Data Sharing\nWe share data as necessary with processors and partners to deliver the Services, fulfill legal obligations or in connection with corporate operations. We do not sell personal data.\n\n7. International Transfers\nWhere personal data is transferred to countries lacking an adequate level of protection, we implement appropriate safeguards (e.g. Standard Contractual Clauses including Swiss addenda).\n\n8. Retention\nWe retain personal data only as long as needed for the described purposes or as required by law. When no longer needed we delete or anonymize it, or securely store it until deletion is feasible (e.g. in backups).\n\n9. Data Security\nWe apply appropriate technical and organizational measures including encryption, access controls and monitoring. No system is 100% secure; use of the Services is at your own risk.\n\n10. Minors\nOur Services are not directed at children under 18. We do not knowingly collect data from children. If you believe we have done so, contact us for deletion.\n\n11. Your Rights\nDepending on your residence: access, rectification, erasure, restriction, portability, objection. You may lodge a complaint with a supervisory authority (e.g. FDPIC in Switzerland; an EEA authority; ICO UK).\n\n12. How to Exercise Your Rights\nContact us at info@immosync.ch or use our contact form at immosync.ch/contact. Requests are handled in line with legal requirements.\n\n13. Changes to this Policy\nWe update this Policy as needed to reflect changes in processing or legal requirements. The \"Last updated\" date indicates the current version.\n\n14. Contact\n\nImmoSync KLG\n\nHauptstrasse 38\n\n4411 Seltisberg (Baselland)\n\nSwitzerland\n\nPhone: +41 76 391 94 00\n\nEmail: info@immosync.ch'**
  String get privacyPolicyContent;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: 1 October 2025'**
  String get termsOfServiceLastUpdated;

  /// No description provided for @termsOfServiceContent.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service (TOS)\nLast updated: 1 October 2025\n\nThese Terms of Service (\"Terms\") govern your use of all products, services and applications of ImmoSync KLG (\"ImmoSync\", \"we\", \"us\"). By accessing or using our Services you agree to these Terms. If you do not agree, you may not use the Services.\n\nImmoSync KLG, Hauptstrasse 38, 4411 Seltisberg, Baselland, Switzerland.\nPhone: +41 76 391 94 00 · Email: info@immosync.ch\n\nTable of Contents\nFoundational Provisions\n1. Our Services\n2. Intellectual Property Rights\n3. User Representations\n4. User Registration\n5. Purchases and Payments\n6. Subscriptions\n7. Software\n8. Prohibited Activities\n9. User Generated Content\n10. License to Contributions\n11. Review Guidelines\n12. Mobile Application\n13. Third‑Party Websites and Content\n14. Service Management\n15. Data Protection\n16. Copyright Infringements\n17. Term and Termination\n18. Changes and Interruptions\n19. Governing Law\n20. Dispute Resolution\n21. Corrections\n22. Disclaimer\n23. Limitation of Liability\n24. Indemnification\n25. User Data\n26. Electronic Communications\n27. SMS Notifications\n28. Final Provisions\n29. Contact\nFoundational Provisions\nBy accessing our Website https://immosync.ch, our mobile applications or other offerings (together the \"Services\") you confirm you are at least 18 years old, have the necessary legal capacity and have read and accepted these Terms. If you act on behalf of a legal entity you represent that you are authorized to bind that entity to these Terms.\n\nWe may update these Terms at any time. Changes will be posted on the Website or communicated by email. Continued use of the Services after changes take effect constitutes acceptance of the revised Terms.\n\n1. Our Services\nImmoSync provides a digital platform that enables communication and collaboration between landlords, tenants, service providers and other stakeholders. The platform evolves continuously and may include features such as messaging, ticketing, document management, scheduling, integrations and automated workflows or bookings.\n\nInformation made available through the Services is not intended for users in jurisdictions where access or use would violate applicable law. Users accessing from outside Switzerland are solely responsible for compliance with local laws.\n\n2. Intellectual Property Rights\nAll content, trademarks, designs, software and databases within the Services are owned by ImmoSync KLG or used under appropriate licenses and are protected by copyright and other intellectual property laws worldwide.\n\nWe grant you a non‑transferable, revocable and non‑exclusive license to use the Services solely for your internal purposes. Any reproduction, modification, publication or other exploitation beyond contractual scope requires our prior written consent.\n\n3. User Representations\nYou warrant that all information you provide during registration or use is truthful, current and complete and will be updated as changes occur. You agree to use the Services only in accordance with law and these Terms and not to infringe third‑party rights.\n\nAccess via automated tools, bots or similar methods is prohibited. We reserve the right to suspend or delete accounts for violations of these representations.\n\n4. User Registration\nCertain features require registration. Credentials must be kept confidential and not shared with third parties. You are responsible for all activities under your account. We may reject or change usernames that infringe rights or are misleading.\n\n5. Purchases and Payments\nPayments for services or subscriptions must be made in Swiss Francs (CHF) at the displayed prices. Accepted payment methods are shown during checkout. Taxes and duties are calculated according to legal requirements.\n\nYou agree to maintain current payment information and authorize us to charge due amounts via the selected method. We may review, limit or decline orders.\n\n6. Subscriptions\nSubscriptions renew automatically at the end of each term unless cancelled in time. Cancellations can be performed via the user account and take effect at the end of the current billing period.\n\nFree trials may be changed or terminated at any time. After a trial ends the account converts to a paid subscription unless cancelled earlier.\n\n7. Software\nWe may provide software or mobile apps. Where additional license terms (EULA) apply they prevail. You may not decompile, reverse engineer or redistribute software without explicit authorization.\n\n8. Prohibited Activities\nUse of the Services for unlawful, fraudulent or harassing purposes is forbidden. This includes in particular:\n\nCollecting or scraping data without permission\nPosting unlawful, defamatory or discriminatory content\nAttempting to bypass security features or introducing malware\nAbusing support channels, false reports or identity theft.\nIn case of violations we may take legal action, remove content or suspend accounts.\n\n9. User Generated Content\nThe Services may allow you to upload content such as text, images or documents. You are responsible that your content does not violate third‑party rights or applicable law.\n\n10. License to Contributions\nBy uploading or providing content you grant us a worldwide, royalty‑free, transferable and perpetual license to use, store, copy, adapt and publish such content for operating the Services. You retain ownership of your content.\n\n11. Review Guidelines\nReviews or testimonials must be based on actual experiences, be factual and free from offensive, discriminatory or infringing statements. We may remove reviews that violate these guidelines.\n\n12. Mobile Application\nWhen using our mobile apps you receive a limited, revocable license to install and use them on your devices. You may not modify, redistribute or use the app to build competing products. App marketplaces (e.g. Apple App Store, Google Play) are third parties and not responsible for support of the app.\n\n13. Third‑Party Websites and Content\nThe Services may contain links to third‑party content or websites. We accept no responsibility for their content, availability or privacy practices. Use is at your own risk and subject to the third parties\' terms.\n\n14. Service Management\nWe may monitor content, restrict access, delete data or perform technical adjustments to ensure secure and proper operation of the Services. We are not obligated to monitor all activities.\n\n15. Data Protection\nProtection of your data is important to us. Information on processing of personal data is provided in our Privacy Policy which forms part of these Terms. By using the Services you consent to the described processing.\n\n16. Copyright Infringements\nIf you believe content distributed via the Services infringes your copyright, contact us promptly with sufficient details to investigate. Abusive notices may have legal consequences.\n\n17. Term and Termination\nThese Terms apply as long as you use the Services. We may suspend or terminate access at any time for cause, especially in case of violations of these Terms or applicable law. You may terminate your account at any time; accrued payment obligations remain unaffected.\n\n18. Changes and Interruptions\nWe may adapt, extend or discontinue the Services or parts thereof. Maintenance may cause temporary interruptions. We are not liable for damages resulting from unavoidable downtime or necessary adjustments.\n\n19. Governing Law\nThese Terms are governed by Swiss law excluding conflict‑of‑laws rules and the UN Sales Convention. Mandatory consumer protections of your residence remain unaffected. Venue is Basel‑Landschaft, Switzerland.\n\n20. Dispute Resolution\nWe seek to resolve disputes amicably first. Failing that, disputes shall be decided under the Rules of the European Court of Arbitration (seat Strasbourg) by a single arbitrator. Place of arbitration: Basel‑City. Language: German. Statutory rights to court proceedings, especially for consumers, remain.\n\n21. Corrections\nDespite careful maintenance information may contain errors. We reserve the right to correct such errors and update content at any time.\n\n22. Disclaimer\nThe Services are provided \"as is\" and \"as available\". To the extent permitted by law we make no warranties regarding availability, error‑free operation or fitness for a particular purpose. Use is at your own risk.\n\n23. Limitation of Liability\nWe are liable only for damages caused intentionally or by gross negligence and for injury to life, body or health. For slight negligence we are liable only for breach of essential contractual obligations (cardinal duties) and limited to the typical foreseeable damage. Statutory mandatory liability remains unaffected.\n\n24. Indemnification\nYou agree to indemnify us against third‑party claims arising from your use of the Services, your content or violations of these Terms, including reasonable legal defense costs. We will inform you of such claims and coordinate the response with you.\n\n25. User Data\nYou are responsible for backing up data you upload. While we perform regular backups we do not guarantee against data loss or restoration except where caused by our gross negligence.\n\n26. Electronic Communications\nCommunication via email, in‑app messages or forms constitutes written notice. You consent to receiving electronic communications and waive paper delivery where legally permissible.\n\n27. SMS Notifications\nIf you enable SMS services (e.g. two‑factor authentication) you will receive technical messages on your mobile device. Standard carrier rates may apply. Deactivation may limit security or certain features.\n\n28. Final Provisions\nThese Terms constitute the entire agreement between you and us. If any provision is invalid the remaining provisions remain effective. Rights and obligations may not be assigned without our consent. Failure to enforce a right does not constitute a waiver for the future.\n\n29. Contact\nFor questions regarding these Terms contact: \n\nImmoSync KLG\nHauptstrasse 38\n4411 Seltisberg (Baselland)\nSwitzerland\nPhone: +41 76 391 94 00\nEmail: info@immosync.ch'**
  String get termsOfServiceContent;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @export.
  ///
  /// In en, this message translates to:
  /// **'Export'**
  String get export;

  /// No description provided for @exportComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Export coming soon'**
  String get exportComingSoon;

  /// No description provided for @tableOfContents.
  ///
  /// In en, this message translates to:
  /// **'Table of Contents'**
  String get tableOfContents;

  /// No description provided for @yourPrivacyMatters.
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get yourPrivacyMatters;

  /// No description provided for @trustBadgeText.
  ///
  /// In en, this message translates to:
  /// **'We protect your data and give you control over your privacy.'**
  String get trustBadgeText;

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
  /// **'Find answers to common questions, learn how to use ImmoSync features, and get support when you need it.'**
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
  /// **'Learn the basics of using ImmoSync'**
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
  /// **'Welcome to ImmoSync! Here\'s how to get started:'**
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
  /// **'Managing properties in ImmoSync:'**
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
  /// **'Understanding payments in ImmoSync:'**
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

  /// No description provided for @supportRequests.
  ///
  /// In en, this message translates to:
  /// **'Support Requests'**
  String get supportRequests;

  /// No description provided for @noSupportRequests.
  ///
  /// In en, this message translates to:
  /// **'No support requests'**
  String get noSupportRequests;

  /// No description provided for @supportRequestStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get supportRequestStatusOpen;

  /// No description provided for @supportRequestStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get supportRequestStatusInProgress;

  /// No description provided for @supportRequestStatusClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get supportRequestStatusClosed;

  /// No description provided for @supportRequestStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed to {status}'**
  String supportRequestStatusChanged(Object status);

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

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock User'**
  String get unblockUser;

  /// No description provided for @blockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedLabel;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @unblock.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @blockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to block this user? You will no longer receive messages from them.'**
  String get blockConfirmBody;

  /// No description provided for @unblockConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Do you want to unblock this user? You will be able to exchange messages again.'**
  String get unblockConfirmBody;

  /// No description provided for @reportConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to report this conversation? Our support team will review it.'**
  String get reportConfirmBody;

  /// No description provided for @deleteConversationConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this conversation? This action cannot be undone.'**
  String get deleteConversationConfirmBody;

  /// No description provided for @chatOptions.
  ///
  /// In en, this message translates to:
  /// **'Chat Options'**
  String get chatOptions;

  /// No description provided for @gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get gallery;

  /// No description provided for @camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get camera;

  /// No description provided for @document.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get document;

  /// No description provided for @emojis.
  ///
  /// In en, this message translates to:
  /// **'Emojis'**
  String get emojis;

  /// No description provided for @imageReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'Image ready to send'**
  String get imageReadyToSend;

  /// No description provided for @fileReadyToSend.
  ///
  /// In en, this message translates to:
  /// **'File ready to send'**
  String get fileReadyToSend;

  /// No description provided for @pleaseSendTextFirst.
  ///
  /// In en, this message translates to:
  /// **'Please send a text message first to start the conversation'**
  String get pleaseSendTextFirst;

  /// No description provided for @encryptionKeyNotReady.
  ///
  /// In en, this message translates to:
  /// **'Encryption key not ready yet...'**
  String get encryptionKeyNotReady;

  /// No description provided for @openFileFailed.
  ///
  /// In en, this message translates to:
  /// **'Open failed'**
  String get openFileFailed;

  /// No description provided for @attachmentFailed.
  ///
  /// In en, this message translates to:
  /// **'Attachment failed'**
  String get attachmentFailed;

  /// No description provided for @errorSelectingImage.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get errorSelectingImage;

  /// No description provided for @errorTakingPhoto.
  ///
  /// In en, this message translates to:
  /// **'Error taking photo'**
  String get errorTakingPhoto;

  /// No description provided for @errorSendingDocument.
  ///
  /// In en, this message translates to:
  /// **'Error sending document'**
  String get errorSendingDocument;

  /// No description provided for @cannotMakeCallOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Cannot make phone calls on this device'**
  String get cannotMakeCallOnDevice;

  /// No description provided for @errorInitiatingCall.
  ///
  /// In en, this message translates to:
  /// **'Error initiating call'**
  String get errorInitiatingCall;

  /// No description provided for @invitationSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation sent successfully'**
  String get invitationSentSuccessfully;

  /// No description provided for @failedToSendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invitation'**
  String get failedToSendInvitation;

  /// No description provided for @invitationAcceptedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invitation accepted successfully!'**
  String get invitationAcceptedSuccessfully;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Declined'**
  String get invitationDeclined;

  /// No description provided for @failedToRespondInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to respond to invitation'**
  String get failedToRespondInvitation;

  /// No description provided for @callPrompt.
  ///
  /// In en, this message translates to:
  /// **'Do you want to make this call?'**
  String get callPrompt;

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

  /// No description provided for @failedToLoadImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to load image'**
  String get failedToLoadImage;

  /// No description provided for @failedToLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Failed to load messages'**
  String get failedToLoadMessages;

  /// No description provided for @recentMessages.
  ///
  /// In en, this message translates to:
  /// **'Recent Messages'**
  String get recentMessages;

  /// No description provided for @propertyManager.
  ///
  /// In en, this message translates to:
  /// **'Property Manager'**
  String get propertyManager;

  /// No description provided for @documents.
  ///
  /// In en, this message translates to:
  /// **'Documents'**
  String get documents;

  /// No description provided for @autoPayment.
  ///
  /// In en, this message translates to:
  /// **'Auto Payment'**
  String get autoPayment;

  /// No description provided for @paymentHistory.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get paymentHistory;

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
  /// **'{count} image(s) selected'**
  String imagesSelected(Object count);

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

  /// No description provided for @tenantSortNameAz.
  ///
  /// In en, this message translates to:
  /// **'Name (A–Z)'**
  String get tenantSortNameAz;

  /// No description provided for @tenantStartingConversation.
  ///
  /// In en, this message translates to:
  /// **'Starting conversation with {fullName}...'**
  String tenantStartingConversation(Object fullName);

  /// No description provided for @tenantNoPhoneAvailable.
  ///
  /// In en, this message translates to:
  /// **'No phone number available for {fullName}'**
  String tenantNoPhoneAvailable(Object fullName);

  /// No description provided for @tenantCallTitle.
  ///
  /// In en, this message translates to:
  /// **'Call {fullName}'**
  String tenantCallTitle(Object fullName);

  /// No description provided for @tenantCallConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Do you want to call {phone}?'**
  String tenantCallConfirmation(Object phone);

  /// No description provided for @tenantCallError.
  ///
  /// In en, this message translates to:
  /// **'Could not make phone call: {error}'**
  String tenantCallError(Object error);

  /// No description provided for @tenantFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Filter Tenants'**
  String get tenantFilterTitle;

  /// No description provided for @tenantServicesServiceProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get tenantServicesServiceProviderLabel;

  /// No description provided for @tenantServicesErrorLoadingProperties.
  ///
  /// In en, this message translates to:
  /// **'Error loading properties'**
  String get tenantServicesErrorLoadingProperties;

  /// No description provided for @tenantServicesNoPropertiesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Properties Assigned'**
  String get tenantServicesNoPropertiesTitle;

  /// No description provided for @tenantServicesNoPropertiesBody.
  ///
  /// In en, this message translates to:
  /// **'You need to be assigned to a property to view available services.'**
  String get tenantServicesNoPropertiesBody;

  /// No description provided for @tenantServicesErrorLoadingServices.
  ///
  /// In en, this message translates to:
  /// **'Error loading services'**
  String get tenantServicesErrorLoadingServices;

  /// No description provided for @tenantServicesHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Available Services'**
  String get tenantServicesHeaderTitle;

  /// No description provided for @tenantServicesHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Book services that your landlord has made available for tenants. All services are pre-approved and professionally managed.'**
  String get tenantServicesHeaderSubtitle;

  /// No description provided for @tenantServicesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get tenantServicesSearchHint;

  /// No description provided for @tenantServicesCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tenantServicesCategoryAll;

  /// No description provided for @tenantServicesCategoryMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get tenantServicesCategoryMaintenance;

  /// No description provided for @tenantServicesCategoryCleaning.
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get tenantServicesCategoryCleaning;

  /// No description provided for @tenantServicesCategoryRepair.
  ///
  /// In en, this message translates to:
  /// **'Repair'**
  String get tenantServicesCategoryRepair;

  /// No description provided for @tenantServicesCategoryGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get tenantServicesCategoryGeneral;

  /// No description provided for @tenantServicesBookServiceButton.
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get tenantServicesBookServiceButton;

  /// No description provided for @tenantServicesUnavailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get tenantServicesUnavailableLabel;

  /// No description provided for @tenantServicesNoServicesTitle.
  ///
  /// In en, this message translates to:
  /// **'No Services Available'**
  String get tenantServicesNoServicesTitle;

  /// No description provided for @tenantServicesNoServicesBody.
  ///
  /// In en, this message translates to:
  /// **'Your landlord hasn\'t set up any services yet.'**
  String get tenantServicesNoServicesBody;

  /// No description provided for @tenantServicesBookDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Book {serviceName}'**
  String tenantServicesBookDialogTitle(Object serviceName);

  /// No description provided for @tenantServicesServiceLine.
  ///
  /// In en, this message translates to:
  /// **'Service: {serviceName}'**
  String tenantServicesServiceLine(Object serviceName);

  /// No description provided for @tenantServicesProviderLine.
  ///
  /// In en, this message translates to:
  /// **'Provider: {provider}'**
  String tenantServicesProviderLine(Object provider);

  /// No description provided for @tenantServicesPriceLine.
  ///
  /// In en, this message translates to:
  /// **'Price: {price}'**
  String tenantServicesPriceLine(Object price);

  /// No description provided for @tenantServicesContactInfoLabel.
  ///
  /// In en, this message translates to:
  /// **'Contact Information:'**
  String get tenantServicesContactInfoLabel;

  /// No description provided for @tenantServicesContactInfoUnavailable.
  ///
  /// In en, this message translates to:
  /// **'No contact info available'**
  String get tenantServicesContactInfoUnavailable;

  /// No description provided for @tenantServicesContactProviderButton.
  ///
  /// In en, this message translates to:
  /// **'Contact Provider'**
  String get tenantServicesContactProviderButton;

  /// No description provided for @tenantServicesContactInfoProvided.
  ///
  /// In en, this message translates to:
  /// **'Contact information for {serviceName} has been provided. Please reach out to {provider} directly.'**
  String tenantServicesContactInfoProvided(Object provider, Object serviceName);

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @profileImageUpload.
  ///
  /// In en, this message translates to:
  /// **'Profile image upload coming soon'**
  String get profileImageUpload;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address and we\'ll send you a link to reset your password.'**
  String get forgotPasswordDescription;

  /// No description provided for @sendResetEmail.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Email'**
  String get sendResetEmail;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @passwordResetEmailSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent! Please check your inbox.'**
  String get passwordResetEmailSent;

  /// No description provided for @pleaseEnterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterYourEmail;

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

  /// No description provided for @privacySettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettingsTitle;

  /// No description provided for @privacySettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Control who can see your profile information and how you appear to other users.'**
  String get privacySettingsIntro;

  /// No description provided for @privacyProfileVisibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Show profile to other users'**
  String get privacyProfileVisibilityTitle;

  /// No description provided for @privacyProfileVisibilityDescription.
  ///
  /// In en, this message translates to:
  /// **'Allow other users you interact with to see your profile details.'**
  String get privacyProfileVisibilityDescription;

  /// No description provided for @privacyContactInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Show contact information'**
  String get privacyContactInfoTitle;

  /// No description provided for @privacyContactInfoDescription.
  ///
  /// In en, this message translates to:
  /// **'Display email and phone number to connected users'**
  String get privacyContactInfoDescription;

  /// No description provided for @privacyDataSharingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get privacyDataSharingSectionTitle;

  /// No description provided for @privacyDataSharingDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how your data is used to improve ImmoLink services.'**
  String get privacyDataSharingDescription;

  /// No description provided for @privacyAllowPropertySearchTitle.
  ///
  /// In en, this message translates to:
  /// **'Allow property search'**
  String get privacyAllowPropertySearchTitle;

  /// No description provided for @privacyAllowPropertySearchDescription.
  ///
  /// In en, this message translates to:
  /// **'Let other users find your properties in search results'**
  String get privacyAllowPropertySearchDescription;

  /// No description provided for @privacyUsageAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Share usage analytics'**
  String get privacyUsageAnalyticsTitle;

  /// No description provided for @privacyUsageAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Help improve ImmoLink by sharing anonymous usage data'**
  String get privacyUsageAnalyticsDescription;

  /// No description provided for @privacyMarketingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Marketing & Communications'**
  String get privacyMarketingSectionTitle;

  /// No description provided for @privacyMarketingDescription.
  ///
  /// In en, this message translates to:
  /// **'Control how we communicate with you about new features and offers.'**
  String get privacyMarketingDescription;

  /// No description provided for @privacyMarketingEmailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Receive marketing emails'**
  String get privacyMarketingEmailsTitle;

  /// No description provided for @privacyMarketingEmailsDescription.
  ///
  /// In en, this message translates to:
  /// **'Get updates about new features, tips, and special offers'**
  String get privacyMarketingEmailsDescription;

  /// No description provided for @privacyDataManagementSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get privacyDataManagementSectionTitle;

  /// No description provided for @privacyDataManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Manage your personal data and export your information.'**
  String get privacyDataManagementDescription;

  /// No description provided for @privacyExportDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get privacyExportDataTitle;

  /// No description provided for @privacyExportDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Download a copy of your personal data'**
  String get privacyExportDataSubtitle;

  /// No description provided for @privacyDeleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get privacyDeleteAccountTitle;

  /// No description provided for @privacyDeleteAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and all data'**
  String get privacyDeleteAccountSubtitle;

  /// No description provided for @privacyExportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get privacyExportDialogTitle;

  /// No description provided for @privacyExportDialogDescription.
  ///
  /// In en, this message translates to:
  /// **'We will prepare a download link with all your personal data including:'**
  String get privacyExportDialogDescription;

  /// No description provided for @privacyExportIncludesProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get privacyExportIncludesProfile;

  /// No description provided for @privacyExportIncludesProperty.
  ///
  /// In en, this message translates to:
  /// **'Property data'**
  String get privacyExportIncludesProperty;

  /// No description provided for @privacyExportIncludesMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages and conversations'**
  String get privacyExportIncludesMessages;

  /// No description provided for @privacyExportIncludesPayments.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get privacyExportIncludesPayments;

  /// No description provided for @privacyExportIncludesSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings and preferences'**
  String get privacyExportIncludesSettings;

  /// No description provided for @privacyExportDialogNote.
  ///
  /// In en, this message translates to:
  /// **'The export process may take up to 24 hours. You will receive an email with the download link.'**
  String get privacyExportDialogNote;

  /// No description provided for @privacyExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Data export request submitted. You will receive an email with the download link.'**
  String get privacyExportSuccess;

  /// No description provided for @privacyExportButton.
  ///
  /// In en, this message translates to:
  /// **'Request export'**
  String get privacyExportButton;

  /// No description provided for @privacyDeleteDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get privacyDeleteDialogTitle;

  /// No description provided for @privacyDeleteDialogQuestion.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account?'**
  String get privacyDeleteDialogQuestion;

  /// No description provided for @privacyDeleteDialogWarningTitle.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete:'**
  String get privacyDeleteDialogWarningTitle;

  /// No description provided for @privacyDeleteDialogDeleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Your profile and all personal data'**
  String get privacyDeleteDialogDeleteProfile;

  /// No description provided for @privacyDeleteDialogDeleteProperties.
  ///
  /// In en, this message translates to:
  /// **'All properties and property data'**
  String get privacyDeleteDialogDeleteProperties;

  /// No description provided for @privacyDeleteDialogDeleteMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages and conversations'**
  String get privacyDeleteDialogDeleteMessages;

  /// No description provided for @privacyDeleteDialogDeletePayments.
  ///
  /// In en, this message translates to:
  /// **'Payment history'**
  String get privacyDeleteDialogDeletePayments;

  /// No description provided for @privacyDeleteDialogDeleteDocuments.
  ///
  /// In en, this message translates to:
  /// **'All uploaded documents and images'**
  String get privacyDeleteDialogDeleteDocuments;

  /// No description provided for @privacyDeleteDialogIrreversible.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone. Please export your data first if you want to keep a copy.'**
  String get privacyDeleteDialogIrreversible;

  /// No description provided for @privacyDeleteRequestSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Account deletion request submitted. This feature will be available soon.'**
  String get privacyDeleteRequestSubmitted;

  /// No description provided for @privacyDeleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get privacyDeleteButton;

  /// No description provided for @changePasswordPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordPageTitle;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password and choose a new one'**
  String get changePasswordSubtitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordCurrentRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get changePasswordCurrentRequired;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordNewRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get changePasswordNewRequired;

  /// No description provided for @changePasswordNewLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters long'**
  String get changePasswordNewLength;

  /// No description provided for @changePasswordNewComplexity.
  ///
  /// In en, this message translates to:
  /// **'Password must contain uppercase, lowercase, and numbers'**
  String get changePasswordNewComplexity;

  /// No description provided for @changePasswordConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get changePasswordConfirmRequired;

  /// No description provided for @changePasswordConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get changePasswordConfirmMismatch;

  /// No description provided for @passwordRequirementsTitle.
  ///
  /// In en, this message translates to:
  /// **'Password Requirements'**
  String get passwordRequirementsTitle;

  /// No description provided for @passwordRequirementLength.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters long'**
  String get passwordRequirementLength;

  /// No description provided for @passwordRequirementUppercase.
  ///
  /// In en, this message translates to:
  /// **'Contains uppercase letters (A-Z)'**
  String get passwordRequirementUppercase;

  /// No description provided for @passwordRequirementLowercase.
  ///
  /// In en, this message translates to:
  /// **'Contains lowercase letters (a-z)'**
  String get passwordRequirementLowercase;

  /// No description provided for @passwordRequirementNumbers.
  ///
  /// In en, this message translates to:
  /// **'Contains numbers (0-9)'**
  String get passwordRequirementNumbers;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePasswordButton;

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

  /// No description provided for @subscriptionPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscriptionPageTitle;

  /// No description provided for @subscriptionLoginPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please log in'**
  String get subscriptionLoginPrompt;

  /// No description provided for @subscriptionNoActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get subscriptionNoActiveTitle;

  /// No description provided for @subscriptionNoActiveDescription.
  ///
  /// In en, this message translates to:
  /// **'You currently don\'t have an active subscription.'**
  String get subscriptionNoActiveDescription;

  /// No description provided for @subscriptionViewPlansButton.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get subscriptionViewPlansButton;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Subscription Active'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusValue.
  ///
  /// In en, this message translates to:
  /// **'Subscription {status}'**
  String subscriptionStatusValue(Object status);

  /// No description provided for @subscriptionPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get subscriptionPlanLabel;

  /// No description provided for @subscriptionAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get subscriptionAmountLabel;

  /// No description provided for @subscriptionBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get subscriptionBillingLabel;

  /// No description provided for @subscriptionBillingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionBillingMonthly;

  /// No description provided for @subscriptionBillingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionBillingYearly;

  /// No description provided for @subscriptionNextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next Billing'**
  String get subscriptionNextBillingLabel;

  /// No description provided for @subscriptionDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Subscription Details'**
  String get subscriptionDetailsTitle;

  /// No description provided for @subscriptionIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Subscription ID'**
  String get subscriptionIdLabel;

  /// No description provided for @subscriptionCustomerIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Customer ID'**
  String get subscriptionCustomerIdLabel;

  /// No description provided for @subscriptionCustomerIdUnavailable.
  ///
  /// In en, this message translates to:
  /// **'N/A'**
  String get subscriptionCustomerIdUnavailable;

  /// No description provided for @subscriptionStartedLabel.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get subscriptionStartedLabel;

  /// No description provided for @subscriptionEndsLabel.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get subscriptionEndsLabel;

  /// No description provided for @subscriptionManageButton.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get subscriptionManageButton;

  /// No description provided for @subscriptionCancelButton.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription'**
  String get subscriptionCancelButton;

  /// No description provided for @subscriptionErrorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading subscription'**
  String get subscriptionErrorLoading;

  /// No description provided for @subscriptionNoCustomerIdMessage.
  ///
  /// In en, this message translates to:
  /// **'No customer ID found'**
  String get subscriptionNoCustomerIdMessage;

  /// No description provided for @subscriptionOpeningPortal.
  ///
  /// In en, this message translates to:
  /// **'Opening Stripe Portal...'**
  String get subscriptionOpeningPortal;

  /// No description provided for @subscriptionFailedToOpenPortal.
  ///
  /// In en, this message translates to:
  /// **'Failed to open portal: {error}'**
  String subscriptionFailedToOpenPortal(Object error);

  /// No description provided for @subscriptionCancelDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel Subscription?'**
  String get subscriptionCancelDialogTitle;

  /// No description provided for @subscriptionCancelDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of the current billing period.'**
  String get subscriptionCancelDialogBody;

  /// No description provided for @subscriptionKeepButton.
  ///
  /// In en, this message translates to:
  /// **'Keep Subscription'**
  String get subscriptionKeepButton;

  /// No description provided for @subscriptionCancelledMessage.
  ///
  /// In en, this message translates to:
  /// **'Subscription cancelled'**
  String get subscriptionCancelledMessage;

  /// No description provided for @subscriptionCancelErrorMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String subscriptionCancelErrorMessage(Object error);

  /// No description provided for @analyticsAndReports.
  ///
  /// In en, this message translates to:
  /// **'Analytics & Reports'**
  String get analyticsAndReports;

  /// No description provided for @exportReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Reports'**
  String get exportReportsTitle;

  /// No description provided for @exportFormatPrompt.
  ///
  /// In en, this message translates to:
  /// **'Select export format'**
  String get exportFormatPrompt;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @generatingPdfReport.
  ///
  /// In en, this message translates to:
  /// **'Generating PDF report...'**
  String get generatingPdfReport;

  /// No description provided for @pdfExportInfo.
  ///
  /// In en, this message translates to:
  /// **'PDF export feature will be implemented with pdf package'**
  String get pdfExportInfo;

  /// No description provided for @propertyOverview.
  ///
  /// In en, this message translates to:
  /// **'Property Overview'**
  String get propertyOverview;

  /// No description provided for @financialOverview.
  ///
  /// In en, this message translates to:
  /// **'Financial Overview'**
  String get financialOverview;

  /// No description provided for @maintenanceOverview.
  ///
  /// In en, this message translates to:
  /// **'Maintenance Overview'**
  String get maintenanceOverview;

  /// No description provided for @recentPayments.
  ///
  /// In en, this message translates to:
  /// **'Recent Payments'**
  String get recentPayments;

  /// No description provided for @noPaymentsFound.
  ///
  /// In en, this message translates to:
  /// **'No payments found'**
  String get noPaymentsFound;

  /// No description provided for @collected.
  ///
  /// In en, this message translates to:
  /// **'Collected'**
  String get collected;

  /// No description provided for @totalPaid.
  ///
  /// In en, this message translates to:
  /// **'Total Paid'**
  String get totalPaid;

  /// No description provided for @totalPayments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get totalPayments;

  /// No description provided for @totalRequests.
  ///
  /// In en, this message translates to:
  /// **'Total Requests'**
  String get totalRequests;

  /// No description provided for @revenueAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Revenue Analytics'**
  String get revenueAnalytics;

  /// No description provided for @revenueChartComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Revenue Chart Coming Soon'**
  String get revenueChartComingSoon;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @thisQuarter.
  ///
  /// In en, this message translates to:
  /// **'This Quarter'**
  String get thisQuarter;

  /// No description provided for @thisYear.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get thisYear;

  /// No description provided for @reportPeriod.
  ///
  /// In en, this message translates to:
  /// **'Report Period'**
  String get reportPeriod;

  /// No description provided for @financialSummary.
  ///
  /// In en, this message translates to:
  /// **'Financial Summary'**
  String get financialSummary;

  /// No description provided for @totalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get totalIncome;

  /// No description provided for @paymentSummary.
  ///
  /// In en, this message translates to:
  /// **'Payment Summary'**
  String get paymentSummary;

  /// No description provided for @dashboardComponentsRequireBrowser.
  ///
  /// In en, this message translates to:
  /// **'Dashboard components require web browser'**
  String get dashboardComponentsRequireBrowser;

  /// No description provided for @dashboardAvailableOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Available on Web'**
  String get dashboardAvailableOnWeb;

  /// No description provided for @visitWebForFullDashboard.
  ///
  /// In en, this message translates to:
  /// **'Visit the web version to access the full {component} dashboard'**
  String visitWebForFullDashboard(Object component);

  /// No description provided for @planBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic'**
  String get planBasic;

  /// No description provided for @planProfessional.
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get planProfessional;

  /// No description provided for @planEnterprise.
  ///
  /// In en, this message translates to:
  /// **'Enterprise'**
  String get planEnterprise;

  /// No description provided for @planBasicDescription.
  ///
  /// In en, this message translates to:
  /// **'Perfect for individual landlords'**
  String get planBasicDescription;

  /// No description provided for @planProfessionalDescription.
  ///
  /// In en, this message translates to:
  /// **'Best for growing property portfolios'**
  String get planProfessionalDescription;

  /// No description provided for @planEnterpriseDescription.
  ///
  /// In en, this message translates to:
  /// **'For large property management companies'**
  String get planEnterpriseDescription;

  /// No description provided for @featureUpToThreeProperties.
  ///
  /// In en, this message translates to:
  /// **'Up to 3 properties'**
  String get featureUpToThreeProperties;

  /// No description provided for @featureBasicTenantManagement.
  ///
  /// In en, this message translates to:
  /// **'Basic tenant management'**
  String get featureBasicTenantManagement;

  /// No description provided for @featurePaymentTracking.
  ///
  /// In en, this message translates to:
  /// **'Payment tracking'**
  String get featurePaymentTracking;

  /// No description provided for @featureEmailSupport.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get featureEmailSupport;

  /// No description provided for @featureUpToFifteenProperties.
  ///
  /// In en, this message translates to:
  /// **'Up to 15 properties'**
  String get featureUpToFifteenProperties;

  /// No description provided for @featureAdvancedTenantManagement.
  ///
  /// In en, this message translates to:
  /// **'Advanced tenant management'**
  String get featureAdvancedTenantManagement;

  /// No description provided for @featureAutomatedRentCollection.
  ///
  /// In en, this message translates to:
  /// **'Automated rent collection'**
  String get featureAutomatedRentCollection;

  /// No description provided for @featureMaintenanceRequestTracking.
  ///
  /// In en, this message translates to:
  /// **'Maintenance request tracking'**
  String get featureMaintenanceRequestTracking;

  /// No description provided for @featureFinancialReports.
  ///
  /// In en, this message translates to:
  /// **'Financial reports'**
  String get featureFinancialReports;

  /// No description provided for @featurePrioritySupport.
  ///
  /// In en, this message translates to:
  /// **'Priority support'**
  String get featurePrioritySupport;

  /// No description provided for @featureUnlimitedProperties.
  ///
  /// In en, this message translates to:
  /// **'Unlimited properties'**
  String get featureUnlimitedProperties;

  /// No description provided for @featureMultiUserAccounts.
  ///
  /// In en, this message translates to:
  /// **'Multi-user accounts'**
  String get featureMultiUserAccounts;

  /// No description provided for @featureAdvancedAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Advanced analytics'**
  String get featureAdvancedAnalytics;

  /// No description provided for @featureApiAccess.
  ///
  /// In en, this message translates to:
  /// **'API access'**
  String get featureApiAccess;

  /// No description provided for @featureCustomIntegrations.
  ///
  /// In en, this message translates to:
  /// **'Custom integrations'**
  String get featureCustomIntegrations;

  /// No description provided for @featureDedicatedSupport.
  ///
  /// In en, this message translates to:
  /// **'Dedicated support'**
  String get featureDedicatedSupport;

  /// No description provided for @documentDownloadedTo.
  ///
  /// In en, this message translates to:
  /// **'Document downloaded to: {path}'**
  String documentDownloadedTo(Object path);

  /// No description provided for @openFolder.
  ///
  /// In en, this message translates to:
  /// **'Open Folder'**
  String get openFolder;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @failedToOpen.
  ///
  /// In en, this message translates to:
  /// **'Failed to open'**
  String get failedToOpen;

  /// No description provided for @openInExternalApp.
  ///
  /// In en, this message translates to:
  /// **'Open in External App'**
  String get openInExternalApp;

  /// No description provided for @loadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Loading document...'**
  String get loadingDocument;

  /// No description provided for @unableToLoadDocument.
  ///
  /// In en, this message translates to:
  /// **'Unable to load document'**
  String get unableToLoadDocument;

  /// No description provided for @downloadInstead.
  ///
  /// In en, this message translates to:
  /// **'Download Instead'**
  String get downloadInstead;

  /// No description provided for @viewImage.
  ///
  /// In en, this message translates to:
  /// **'View Image'**
  String get viewImage;

  /// No description provided for @loadPreview.
  ///
  /// In en, this message translates to:
  /// **'Load Preview'**
  String get loadPreview;

  /// No description provided for @downloadToDevice.
  ///
  /// In en, this message translates to:
  /// **'Download to Device'**
  String get downloadToDevice;

  /// No description provided for @failedToDisplayImage.
  ///
  /// In en, this message translates to:
  /// **'Failed to display image'**
  String get failedToDisplayImage;

  /// No description provided for @pdfDocument.
  ///
  /// In en, this message translates to:
  /// **'PDF Document'**
  String get pdfDocument;

  /// No description provided for @imageFile.
  ///
  /// In en, this message translates to:
  /// **'Image File'**
  String get imageFile;

  /// No description provided for @textFile.
  ///
  /// In en, this message translates to:
  /// **'Text File'**
  String get textFile;

  /// No description provided for @wordDocument.
  ///
  /// In en, this message translates to:
  /// **'Word Document'**
  String get wordDocument;

  /// No description provided for @excelSpreadsheet.
  ///
  /// In en, this message translates to:
  /// **'Excel Spreadsheet'**
  String get excelSpreadsheet;

  /// No description provided for @powerPointPresentation.
  ///
  /// In en, this message translates to:
  /// **'PowerPoint Presentation'**
  String get powerPointPresentation;

  /// No description provided for @documentFile.
  ///
  /// In en, this message translates to:
  /// **'Document File'**
  String get documentFile;

  /// No description provided for @expiringSoon.
  ///
  /// In en, this message translates to:
  /// **'Expiring Soon'**
  String get expiringSoon;

  /// No description provided for @expired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get expired;

  /// No description provided for @expiresOn.
  ///
  /// In en, this message translates to:
  /// **'Expires {date}'**
  String expiresOn(Object date);

  /// No description provided for @tenantsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{tenant} other{tenants}}'**
  String tenantsCount(num count);

  /// No description provided for @propertiesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{property} other{properties}}'**
  String propertiesCount(num count);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(Object days);

  /// No description provided for @weeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String weeksAgo(num count);

  /// No description provided for @subscriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Subscription Required'**
  String get subscriptionRequired;

  /// No description provided for @subscriptionRequiredMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature is available with a subscription.'**
  String get subscriptionRequiredMessage;

  /// No description provided for @subscriptionChoosePlanMessage.
  ///
  /// In en, this message translates to:
  /// **'Choose a plan to unlock all features.'**
  String get subscriptionChoosePlanMessage;

  /// No description provided for @viewPlans.
  ///
  /// In en, this message translates to:
  /// **'View Plans'**
  String get viewPlans;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @viewAllProperties.
  ///
  /// In en, this message translates to:
  /// **'View All Properties'**
  String get viewAllProperties;

  /// No description provided for @noRecentMessages.
  ///
  /// In en, this message translates to:
  /// **'No recent messages'**
  String get noRecentMessages;

  /// No description provided for @noPendingMaintenanceRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending maintenance requests'**
  String get noPendingMaintenanceRequests;

  /// No description provided for @errorLoadingMaintenanceRequest.
  ///
  /// In en, this message translates to:
  /// **'Error loading maintenance request'**
  String get errorLoadingMaintenanceRequest;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go Back'**
  String get goBack;

  /// No description provided for @contractorInformation.
  ///
  /// In en, this message translates to:
  /// **'Contractor Information'**
  String get contractorInformation;

  /// No description provided for @contact.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @company.
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @reported.
  ///
  /// In en, this message translates to:
  /// **'Reported'**
  String get reported;

  /// No description provided for @loadingAddress.
  ///
  /// In en, this message translates to:
  /// **'Loading address...'**
  String get loadingAddress;

  /// No description provided for @propertyIdLabel.
  ///
  /// In en, this message translates to:
  /// **'Property ID'**
  String get propertyIdLabel;

  /// No description provided for @urgency.
  ///
  /// In en, this message translates to:
  /// **'Urgency'**
  String get urgency;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @estimated.
  ///
  /// In en, this message translates to:
  /// **'Estimated'**
  String get estimated;

  /// No description provided for @actualCost.
  ///
  /// In en, this message translates to:
  /// **'Actual Cost'**
  String get actualCost;

  /// No description provided for @markAsInProgress.
  ///
  /// In en, this message translates to:
  /// **'Mark as In Progress'**
  String get markAsInProgress;

  /// No description provided for @markAsCompleted.
  ///
  /// In en, this message translates to:
  /// **'Mark as Completed'**
  String get markAsCompleted;

  /// No description provided for @enterNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a note...'**
  String get enterNoteHint;

  /// No description provided for @addingNote.
  ///
  /// In en, this message translates to:
  /// **'Adding note...'**
  String get addingNote;

  /// No description provided for @completePayment.
  ///
  /// In en, this message translates to:
  /// **'Complete Payment'**
  String get completePayment;

  /// No description provided for @perYearSuffix.
  ///
  /// In en, this message translates to:
  /// **'per year'**
  String get perYearSuffix;

  /// No description provided for @perMonthSuffix.
  ///
  /// In en, this message translates to:
  /// **'per month'**
  String get perMonthSuffix;

  /// No description provided for @youSavePerYear.
  ///
  /// In en, this message translates to:
  /// **'You save {savings} per year'**
  String youSavePerYear(Object savings);

  /// No description provided for @includedFeatures.
  ///
  /// In en, this message translates to:
  /// **'Included Features'**
  String get includedFeatures;

  /// No description provided for @paymentMethod.
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// No description provided for @paymentInfoSecure.
  ///
  /// In en, this message translates to:
  /// **'Your payment information is secure'**
  String get paymentInfoSecure;

  /// No description provided for @desktopPaymentNotSupported.
  ///
  /// In en, this message translates to:
  /// **'Desktop payment not supported'**
  String get desktopPaymentNotSupported;

  /// No description provided for @desktopPaymentUseWebOrMobile.
  ///
  /// In en, this message translates to:
  /// **'Please use the web or mobile app to complete your payment.'**
  String get desktopPaymentUseWebOrMobile;

  /// No description provided for @openWebVersion.
  ///
  /// In en, this message translates to:
  /// **'Open Web Version'**
  String get openWebVersion;

  /// No description provided for @redirectingToSecurePaymentPage.
  ///
  /// In en, this message translates to:
  /// **'Redirecting to secure payment page...'**
  String get redirectingToSecurePaymentPage;

  /// No description provided for @subscriptionTerms.
  ///
  /// In en, this message translates to:
  /// **'Subscription Terms'**
  String get subscriptionTerms;

  /// No description provided for @subscriptionBulletAutoRenews.
  ///
  /// In en, this message translates to:
  /// **'Renews automatically every {interval}'**
  String subscriptionBulletAutoRenews(Object interval);

  /// No description provided for @yearlyInterval.
  ///
  /// In en, this message translates to:
  /// **'year'**
  String get yearlyInterval;

  /// No description provided for @monthlyInterval.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get monthlyInterval;

  /// No description provided for @subscriptionBulletCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime'**
  String get subscriptionBulletCancelAnytime;

  /// No description provided for @subscriptionBulletRefundPolicy.
  ///
  /// In en, this message translates to:
  /// **'Non-refundable once the billing period starts'**
  String get subscriptionBulletRefundPolicy;

  /// No description provided for @subscriptionBulletAgreeTerms.
  ///
  /// In en, this message translates to:
  /// **'By subscribing you agree to our terms'**
  String get subscriptionBulletAgreeTerms;

  /// No description provided for @subscribeNow.
  ///
  /// In en, this message translates to:
  /// **'Subscribe Now'**
  String get subscribeNow;

  /// No description provided for @continueOnWeb.
  ///
  /// In en, this message translates to:
  /// **'Continue on Web'**
  String get continueOnWeb;

  /// No description provided for @paymentFailed.
  ///
  /// In en, this message translates to:
  /// **'Payment failed: {error}'**
  String paymentFailed(Object error);

  /// No description provided for @subscriptionActivated.
  ///
  /// In en, this message translates to:
  /// **'Your {planName} subscription is active!'**
  String subscriptionActivated(Object planName);

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @manageSubscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage Subscription'**
  String get manageSubscriptionTitle;

  /// No description provided for @chooseYourPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Your Plan'**
  String get chooseYourPlanTitle;

  /// No description provided for @subscriptionLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load subscription data'**
  String get subscriptionLoadError;

  /// No description provided for @upgradeUnlockFeaturesMessage.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to unlock more features and property limits'**
  String get upgradeUnlockFeaturesMessage;

  /// No description provided for @selectPlanIntro.
  ///
  /// In en, this message translates to:
  /// **'Select the perfect plan for your property management needs'**
  String get selectPlanIntro;

  /// No description provided for @highestPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re on the highest plan!'**
  String get highestPlanTitle;

  /// No description provided for @highestPlanDescription.
  ///
  /// In en, this message translates to:
  /// **'You have access to all premium features and unlimited property management capabilities.'**
  String get highestPlanDescription;

  /// No description provided for @premiumThanksMessage.
  ///
  /// In en, this message translates to:
  /// **'Thank you for being a premium subscriber!'**
  String get premiumThanksMessage;

  /// No description provided for @billingMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get billingMonthly;

  /// No description provided for @billingYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get billingYearly;

  /// No description provided for @savePercent.
  ///
  /// In en, this message translates to:
  /// **'Save {percent}%'**
  String savePercent(Object percent);

  /// No description provided for @currentPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Current Plan'**
  String get currentPlanLabel;

  /// No description provided for @statusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get statusLabel;

  /// No description provided for @nextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next billing'**
  String get nextBillingLabel;

  /// No description provided for @popularBadge.
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popularBadge;

  /// No description provided for @upgradeBadge.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgradeBadge;

  /// No description provided for @upgradePlanButton.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlanButton;

  /// No description provided for @continueToPayment.
  ///
  /// In en, this message translates to:
  /// **'Continue to Payment'**
  String get continueToPayment;

  /// No description provided for @yourProperty.
  ///
  /// In en, this message translates to:
  /// **'Your Property'**
  String get yourProperty;

  /// No description provided for @recentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// No description provided for @statusActiveUpper.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get statusActiveUpper;

  /// No description provided for @myDocuments.
  ///
  /// In en, this message translates to:
  /// **'My Documents'**
  String get myDocuments;

  /// No description provided for @welcomeUser.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {userName}'**
  String welcomeUser(Object userName);

  /// No description provided for @tenantDocumentsIntro.
  ///
  /// In en, this message translates to:
  /// **'Manage all your rental documents, contracts and important papers here.'**
  String get tenantDocumentsIntro;

  /// No description provided for @documentCategories.
  ///
  /// In en, this message translates to:
  /// **'Document Categories'**
  String get documentCategories;

  /// No description provided for @leaseAgreement.
  ///
  /// In en, this message translates to:
  /// **'Lease Agreement'**
  String get leaseAgreement;

  /// No description provided for @leaseAgreementSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your current rental contract'**
  String get leaseAgreementSubtitle;

  /// No description provided for @operatingCosts.
  ///
  /// In en, this message translates to:
  /// **'Operating Costs'**
  String get operatingCosts;

  /// No description provided for @operatingCostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Statements and receipts'**
  String get operatingCostsSubtitle;

  /// No description provided for @protocols.
  ///
  /// In en, this message translates to:
  /// **'Protocols'**
  String get protocols;

  /// No description provided for @protocolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Handover and inspection reports'**
  String get protocolsSubtitle;

  /// No description provided for @correspondence.
  ///
  /// In en, this message translates to:
  /// **'Correspondence'**
  String get correspondence;

  /// No description provided for @correspondenceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Emails and letters'**
  String get correspondenceSubtitle;

  /// No description provided for @documentsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} document{pluralSuffix}'**
  String documentsCount(Object count, Object pluralSuffix);

  /// No description provided for @enterSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Enter a search term'**
  String get enterSearchTerm;

  /// No description provided for @noDocumentsFound.
  ///
  /// In en, this message translates to:
  /// **'No documents found'**
  String get noDocumentsFound;

  /// No description provided for @documentSearch.
  ///
  /// In en, this message translates to:
  /// **'Document Search'**
  String get documentSearch;

  /// No description provided for @useDocumentsTabForDetailedSearch.
  ///
  /// In en, this message translates to:
  /// **'Use the documents tab for a detailed search'**
  String get useDocumentsTabForDetailedSearch;

  /// No description provided for @recentDocuments.
  ///
  /// In en, this message translates to:
  /// **'Recent Documents'**
  String get recentDocuments;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @noRecentDocuments.
  ///
  /// In en, this message translates to:
  /// **'No recent documents'**
  String get noRecentDocuments;

  /// No description provided for @allDocumentsHeader.
  ///
  /// In en, this message translates to:
  /// **'All Documents'**
  String get allDocumentsHeader;

  /// No description provided for @noDocumentsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No documents available'**
  String get noDocumentsAvailable;

  /// No description provided for @documentsSharedByLandlord.
  ///
  /// In en, this message translates to:
  /// **'Documents shared by your landlord will appear here'**
  String get documentsSharedByLandlord;

  /// No description provided for @loadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Loading documents...'**
  String get loadingDocuments;

  /// No description provided for @errorLoadingDocuments.
  ///
  /// In en, this message translates to:
  /// **'Error loading documents'**
  String get errorLoadingDocuments;

  /// No description provided for @pleaseLoginToUploadDocuments.
  ///
  /// In en, this message translates to:
  /// **'Please log in to upload documents'**
  String get pleaseLoginToUploadDocuments;

  /// No description provided for @downloadingDocument.
  ///
  /// In en, this message translates to:
  /// **'Downloading {name}...'**
  String downloadingDocument(Object name);

  /// No description provided for @documentDownloadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'{name} downloaded successfully'**
  String documentDownloadedSuccessfully(Object name);

  /// No description provided for @failedToDownloadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to download {name}'**
  String failedToDownloadDocument(Object name);

  /// No description provided for @documentUploadedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document \"{name}\" uploaded successfully'**
  String documentUploadedSuccessfully(Object name);

  /// No description provided for @failedToUploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document: {error}'**
  String failedToUploadDocument(Object error);

  /// No description provided for @featureComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get featureComingSoonTitle;

  /// No description provided for @featureComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in a future update.'**
  String get featureComingSoonMessage;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @expiring.
  ///
  /// In en, this message translates to:
  /// **'Expiring'**
  String get expiring;

  /// No description provided for @uploadDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload Document'**
  String get uploadDocument;

  /// No description provided for @noSpecificProperty.
  ///
  /// In en, this message translates to:
  /// **'No specific property'**
  String get noSpecificProperty;

  /// No description provided for @failedToUploadDocumentGeneric.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload document: {error}'**
  String failedToUploadDocumentGeneric(Object error);

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @inspectionReports.
  ///
  /// In en, this message translates to:
  /// **'Inspection Reports'**
  String get inspectionReports;

  /// No description provided for @legalDocuments.
  ///
  /// In en, this message translates to:
  /// **'Legal Documents'**
  String get legalDocuments;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @documentManagement.
  ///
  /// In en, this message translates to:
  /// **'Document Management'**
  String get documentManagement;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back, {name}'**
  String welcomeBack(Object name);

  /// No description provided for @quickUpload.
  ///
  /// In en, this message translates to:
  /// **'Quick Upload'**
  String get quickUpload;

  /// No description provided for @notice.
  ///
  /// In en, this message translates to:
  /// **'Notice'**
  String get notice;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @filterDocuments.
  ///
  /// In en, this message translates to:
  /// **'Filter Documents'**
  String get filterDocuments;

  /// No description provided for @loadingProperties.
  ///
  /// In en, this message translates to:
  /// **'Loading properties...'**
  String get loadingProperties;

  /// No description provided for @documentLibrary.
  ///
  /// In en, this message translates to:
  /// **'Document Library'**
  String get documentLibrary;

  /// No description provided for @uploadFirstDocument.
  ///
  /// In en, this message translates to:
  /// **'Upload your first document to get started'**
  String get uploadFirstDocument;

  /// No description provided for @fileLabel.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get fileLabel;

  /// No description provided for @sizeLabel.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get sizeLabel;

  /// No description provided for @recentLabel.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentLabel;

  /// No description provided for @importantLabel.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get importantLabel;

  /// No description provided for @documentName.
  ///
  /// In en, this message translates to:
  /// **'Document Name'**
  String get documentName;

  /// No description provided for @descriptionOptional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptional;

  /// No description provided for @assignToPropertyOptional.
  ///
  /// In en, this message translates to:
  /// **'Assign to Property (optional)'**
  String get assignToPropertyOptional;

  /// No description provided for @areYouSure.
  ///
  /// In en, this message translates to:
  /// **'Are you sure?'**
  String get areYouSure;

  /// No description provided for @documentDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Document \"{name}\" deleted successfully'**
  String documentDeletedSuccessfully(Object name);

  /// No description provided for @failedToDeleteDocument.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete document: {error}'**
  String failedToDeleteDocument(Object error);

  /// No description provided for @noAppToOpenFile.
  ///
  /// In en, this message translates to:
  /// **'No app found to open this file'**
  String get noAppToOpenFile;

  /// No description provided for @subscriptionStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get subscriptionStatus;

  /// No description provided for @subscriptionMonthlyAmount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amount'**
  String get subscriptionMonthlyAmount;

  /// No description provided for @subscriptionYearlyCost.
  ///
  /// In en, this message translates to:
  /// **'Yearly Cost'**
  String get subscriptionYearlyCost;

  /// No description provided for @subscriptionMonthlyCost.
  ///
  /// In en, this message translates to:
  /// **'Monthly Cost'**
  String get subscriptionMonthlyCost;

  /// No description provided for @subscriptionNextBilling.
  ///
  /// In en, this message translates to:
  /// **'Next Billing'**
  String get subscriptionNextBilling;

  /// No description provided for @subscriptionBillingInterval.
  ///
  /// In en, this message translates to:
  /// **'Billing Interval'**
  String get subscriptionBillingInterval;

  /// No description provided for @subscriptionMySubscription.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get subscriptionMySubscription;

  /// No description provided for @subscriptionActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get subscriptionActive;

  /// No description provided for @subscriptionPastDue.
  ///
  /// In en, this message translates to:
  /// **'Past Due'**
  String get subscriptionPastDue;

  /// No description provided for @subscriptionCanceled.
  ///
  /// In en, this message translates to:
  /// **'Canceled'**
  String get subscriptionCanceled;

  /// No description provided for @subscriptionPaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment Due!'**
  String get subscriptionPaymentDue;

  /// No description provided for @subscriptionNextPayment.
  ///
  /// In en, this message translates to:
  /// **'Next Payment'**
  String get subscriptionNextPayment;

  /// No description provided for @subscriptionInDays.
  ///
  /// In en, this message translates to:
  /// **'In {days} days'**
  String subscriptionInDays(Object days);

  /// No description provided for @subscriptionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get subscriptionToday;

  /// No description provided for @subscriptionOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get subscriptionOverdue;

  /// No description provided for @subscriptionMemberSince.
  ///
  /// In en, this message translates to:
  /// **'Member Since'**
  String get subscriptionMemberSince;

  /// No description provided for @subscriptionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionMonthly;

  /// No description provided for @subscriptionYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscriptionYearly;

  /// No description provided for @noActiveSubscription.
  ///
  /// In en, this message translates to:
  /// **'No Active Subscription'**
  String get noActiveSubscription;

  /// No description provided for @noActiveSubscriptionLandlord.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to unlock premium features and manage your properties more efficiently.'**
  String get noActiveSubscriptionLandlord;

  /// No description provided for @noActiveSubscriptionTenant.
  ///
  /// In en, this message translates to:
  /// **'Subscribe to access all features and enjoy a seamless experience.'**
  String get noActiveSubscriptionTenant;

  /// No description provided for @tenantPayments.
  ///
  /// In en, this message translates to:
  /// **'Tenant Payments'**
  String get tenantPayments;

  /// No description provided for @totalOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Total Outstanding'**
  String get totalOutstanding;

  /// No description provided for @pendingPayments.
  ///
  /// In en, this message translates to:
  /// **'Pending Payments'**
  String get pendingPayments;

  /// No description provided for @overduePayments.
  ///
  /// In en, this message translates to:
  /// **'Overdue Payments'**
  String get overduePayments;

  /// No description provided for @noTenantsYetMessage.
  ///
  /// In en, this message translates to:
  /// **'Add tenants to your properties to track their subscription payments.'**
  String get noTenantsYetMessage;

  /// No description provided for @invitationSent.
  ///
  /// In en, this message translates to:
  /// **'Invitation Sent'**
  String get invitationSent;

  /// No description provided for @propertyInvitation.
  ///
  /// In en, this message translates to:
  /// **'Property Invitation'**
  String get propertyInvitation;

  /// No description provided for @toTenant.
  ///
  /// In en, this message translates to:
  /// **'To {tenantName} • {propertyAddress}'**
  String toTenant(Object tenantName, Object propertyAddress);

  /// No description provided for @fromLandlord.
  ///
  /// In en, this message translates to:
  /// **'From {landlordName}'**
  String fromLandlord(Object landlordName);

  /// No description provided for @unknownTenant.
  ///
  /// In en, this message translates to:
  /// **'Unknown Tenant'**
  String get unknownTenant;

  /// No description provided for @invitationAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get invitationAccepted;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get invitationPending;

  /// No description provided for @messageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageLabel;

  /// No description provided for @decline.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get decline;

  /// No description provided for @accept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get accept;

  /// No description provided for @invitationExpired.
  ///
  /// In en, this message translates to:
  /// **'This invitation has expired'**
  String get invitationExpired;

  /// No description provided for @acceptedOn.
  ///
  /// In en, this message translates to:
  /// **'Accepted {date}'**
  String acceptedOn(Object date);

  /// No description provided for @declinedOn.
  ///
  /// In en, this message translates to:
  /// **'Declined {date}'**
  String declinedOn(Object date);

  /// No description provided for @receivedOn.
  ///
  /// In en, this message translates to:
  /// **'Received {date}'**
  String receivedOn(Object date);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(Object minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(Object hours);

  /// No description provided for @imageRemoved.
  ///
  /// In en, this message translates to:
  /// **'Image removed'**
  String get imageRemoved;

  /// No description provided for @upgradePlan.
  ///
  /// In en, this message translates to:
  /// **'Upgrade Plan'**
  String get upgradePlan;

  /// No description provided for @editProperty.
  ///
  /// In en, this message translates to:
  /// **'Edit Property'**
  String get editProperty;

  /// No description provided for @newProperty.
  ///
  /// In en, this message translates to:
  /// **'New Property'**
  String get newProperty;

  /// No description provided for @addPropertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Add property details to get started'**
  String get addPropertyDetails;

  /// No description provided for @updatePropertyDetails.
  ///
  /// In en, this message translates to:
  /// **'Update your property details'**
  String get updatePropertyDetails;

  /// No description provided for @streetAddress.
  ///
  /// In en, this message translates to:
  /// **'Street Address'**
  String get streetAddress;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @postalCode.
  ///
  /// In en, this message translates to:
  /// **'Postal Code'**
  String get postalCode;

  /// No description provided for @images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get images;

  /// No description provided for @addressRequired.
  ///
  /// In en, this message translates to:
  /// **'Address is required'**
  String get addressRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City is required'**
  String get cityRequired;

  /// No description provided for @postalCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'Postal code is required'**
  String get postalCodeRequired;

  /// No description provided for @rentRequired.
  ///
  /// In en, this message translates to:
  /// **'Rent is required'**
  String get rentRequired;

  /// No description provided for @sizeRequired.
  ///
  /// In en, this message translates to:
  /// **'Size is required'**
  String get sizeRequired;

  /// No description provided for @roomsRequired.
  ///
  /// In en, this message translates to:
  /// **'Rooms are required'**
  String get roomsRequired;

  /// No description provided for @updatingProperty.
  ///
  /// In en, this message translates to:
  /// **'Updating property...'**
  String get updatingProperty;

  /// No description provided for @creatingProperty.
  ///
  /// In en, this message translates to:
  /// **'Creating property...'**
  String get creatingProperty;

  /// No description provided for @selectAmenities.
  ///
  /// In en, this message translates to:
  /// **'Select amenities'**
  String get selectAmenities;

  /// No description provided for @addPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotos;

  /// No description provided for @selectPhotosDescription.
  ///
  /// In en, this message translates to:
  /// **'Select photos to showcase your property'**
  String get selectPhotosDescription;

  /// No description provided for @tapToUploadImages.
  ///
  /// In en, this message translates to:
  /// **'Tap to upload images'**
  String get tapToUploadImages;

  /// No description provided for @saveProperty.
  ///
  /// In en, this message translates to:
  /// **'Save Property'**
  String get saveProperty;

  /// No description provided for @updateProperty.
  ///
  /// In en, this message translates to:
  /// **'Update Property'**
  String get updateProperty;

  /// No description provided for @payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get payments;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @payouts.
  ///
  /// In en, this message translates to:
  /// **'Payouts'**
  String get payouts;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @revenueDetails.
  ///
  /// In en, this message translates to:
  /// **'Revenue Details'**
  String get revenueDetails;

  /// No description provided for @outstandingPaymentsDetails.
  ///
  /// In en, this message translates to:
  /// **'Outstanding Payments Details'**
  String get outstandingPaymentsDetails;

  /// No description provided for @totalRevenuePerMonth.
  ///
  /// In en, this message translates to:
  /// **'Total Revenue per Month'**
  String get totalRevenuePerMonth;

  /// No description provided for @averagePerProperty.
  ///
  /// In en, this message translates to:
  /// **'Average per Property'**
  String get averagePerProperty;

  /// No description provided for @numberOfProperties.
  ///
  /// In en, this message translates to:
  /// **'Number of Properties'**
  String get numberOfProperties;

  /// No description provided for @revenueByProperty.
  ///
  /// In en, this message translates to:
  /// **'Revenue by Property'**
  String get revenueByProperty;

  /// No description provided for @revenueDistribution.
  ///
  /// In en, this message translates to:
  /// **'Revenue Distribution'**
  String get revenueDistribution;

  /// No description provided for @rentIncome.
  ///
  /// In en, this message translates to:
  /// **'Rent Income'**
  String get rentIncome;

  /// No description provided for @utilityCosts.
  ///
  /// In en, this message translates to:
  /// **'Utility Costs'**
  String get utilityCosts;

  /// No description provided for @otherIncome.
  ///
  /// In en, this message translates to:
  /// **'Other Income'**
  String get otherIncome;

  /// No description provided for @unknownAddress.
  ///
  /// In en, this message translates to:
  /// **'Unknown Address'**
  String get unknownAddress;

  /// No description provided for @openPayments.
  ///
  /// In en, this message translates to:
  /// **'Open Payments'**
  String get openPayments;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @noOutstandingPayments.
  ///
  /// In en, this message translates to:
  /// **'No Outstanding Payments'**
  String get noOutstandingPayments;

  /// No description provided for @allRentPaymentsCurrent.
  ///
  /// In en, this message translates to:
  /// **'All rent payments are current.'**
  String get allRentPaymentsCurrent;
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
