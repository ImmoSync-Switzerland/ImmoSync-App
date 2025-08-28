// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'ImmoSync';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get properties => 'Propriétés';

  @override
  String get tenants => 'Locataires';

  @override
  String get services => 'Services';

  @override
  String get messages => 'Messages';

  @override
  String get reports => 'Rapports';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get currency => 'Devise';

  @override
  String get preferences => 'Préférences';

  @override
  String get security => 'Sécurité';

  @override
  String get notifications => 'Notifications';

  @override
  String get about => 'À propos';

  @override
  String get logout => 'Déconnexion';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get system => 'Système';

  @override
  String get english => 'Anglais';

  @override
  String get german => 'Allemand';

  @override
  String get french => 'Français';

  @override
  String get italian => 'Italien';

  @override
  String get selectLanguage => 'Sélectionner la langue';

  @override
  String get selectTheme => 'Sélectionner le thème';

  @override
  String get selectCurrency => 'Sélectionner la devise';

  @override
  String get cancel => 'Annuler';

  @override
  String languageChangedTo(Object language) {
    return 'Langue changée en $language';
  }

  @override
  String themeChangedTo(Object theme) {
    return 'Thème changé en $theme';
  }

  @override
  String currencyChangedTo(Object currency) {
    return 'Devise changée en $currency';
  }

  @override
  String get welcome => 'Bienvenue';

  @override
  String get totalProperties => 'Total des propriétés';

  @override
  String get monthlyRevenue => 'Revenus mensuels';

  @override
  String get occupancyRate => 'Taux d\'occupation';

  @override
  String get maintenanceRequests => 'Demandes de maintenance';

  @override
  String get search => 'Rechercher';

  @override
  String get searchConversations => 'Rechercher des conversations...';

  @override
  String get searchProperties => 'Rechercher des propriétés...';

  @override
  String get noConversations => 'Aucune conversation trouvée';

  @override
  String get noProperties => 'Aucune propriété trouvée';

  @override
  String get propertyDetails => 'Détails de la propriété';

  @override
  String get address => 'Adresse';

  @override
  String get type => 'Type';

  @override
  String get status => 'Statut';

  @override
  String get rent => 'Loyer';

  @override
  String get available => 'Disponible';

  @override
  String get occupied => 'Occupé';

  @override
  String get maintenance => 'Maintenance';

  @override
  String get area => 'Surface';

  @override
  String get mapNotAvailable => 'Carte non disponible';

  @override
  String get contactLandlord => 'Contacter le propriétaire';

  @override
  String get statusAvailable => 'Disponible';

  @override
  String get statusRented => 'Loué';

  @override
  String get statusMaintenance => 'Maintenance';

  @override
  String get newMessage => 'Nouveau message';

  @override
  String get typeMessage => 'Tapez un message...';

  @override
  String get send => 'Envoyer';

  @override
  String get revenueReport => 'Rapport de revenus';

  @override
  String get occupancyReport => 'Rapport d\'occupation';

  @override
  String get maintenanceReport => 'Rapport de maintenance';

  @override
  String get generateReport => 'Générer un rapport';

  @override
  String get emailNotifications => 'Notifications par e-mail';

  @override
  String get pushNotifications => 'Notifications push';

  @override
  String get paymentReminders => 'Rappels de paiement';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get version => 'Version';

  @override
  String get unknownProperty => 'Propriété inconnue';

  @override
  String get user => 'Utilisateur';

  @override
  String get tenantManagement => 'Gestion des locataires';

  @override
  String get manageTenantDescription =>
      'Gérez vos locataires et leurs affectations de propriétés';

  @override
  String get totalTenants => 'Total des locataires';

  @override
  String get activeTenants => 'Locataires actifs';

  @override
  String get occupiedUnits => 'Unités occupées';

  @override
  String get pendingIssues => 'Problèmes en attente';

  @override
  String get propertiesAssigned => 'Propriétés assignées';

  @override
  String get empty => 'Vide';

  @override
  String get noTenantsFound => 'Aucun locataire trouvé';

  @override
  String get noTenantsYet => 'Aucun locataire pour le moment';

  @override
  String get addPropertiesInviteTenants =>
      'Ajoutez des propriétés et invitez des locataires pour commencer';

  @override
  String get addProperty => 'Ajouter une propriété';

  @override
  String get addTenant => 'Ajouter un locataire';

  @override
  String get loadingTenants => 'Chargement des locataires...';

  @override
  String get errorLoadingTenants => 'Erreur lors du chargement des locataires';

  @override
  String get pleaseTryAgainLater => 'Veuillez réessayer plus tard';

  @override
  String get retryLoading => 'Réessayer';

  @override
  String get editTenant => 'Modifier le locataire';

  @override
  String get deleteTenant => 'Supprimer le locataire';

  @override
  String get tenantDetails => 'Détails du locataire';

  @override
  String get email => 'E-mail';

  @override
  String get phone => 'Téléphone';

  @override
  String get viewDetails => 'Voir les détails';

  @override
  String get searchTenants => 'Rechercher des locataires...';

  @override
  String get myProperties => 'Mes propriétés';

  @override
  String get all => 'Tout';

  @override
  String get rented => 'LOUÉ';

  @override
  String get monthlyRent => 'Loyer mensuel';

  @override
  String get size => 'Taille';

  @override
  String get rooms => 'Pièces';

  @override
  String get noPropertiesFound => 'Aucune propriété trouvée';

  @override
  String get addFirstProperty =>
      'Ajoutez votre première propriété pour commencer';

  @override
  String get noPropertiesAssigned => 'Aucune propriété assignée';

  @override
  String get contactLandlordForAccess =>
      'Contactez votre propriétaire pour accéder à votre propriété';

  @override
  String get somethingWentWrong => 'Une erreur s\'est produite';

  @override
  String get retry => 'Réessayer';

  @override
  String get noConversationsYet => 'Aucune conversation pour le moment';

  @override
  String get tryAdjustingSearch => 'Essayez d\'ajuster vos termes de recherche';

  @override
  String get startConversation =>
      'Commencez une conversation avec vos propriétés';

  @override
  String get newConversation => 'Nouvelle conversation';

  @override
  String get propertySelectionMessage =>
      'La sélection de propriétés sera implémentée avec l\'intégration de base de données';

  @override
  String get create => 'Créer';

  @override
  String get landlords => 'Propriétaires';

  @override
  String get errorLoadingContacts => 'Erreur lors du chargement des contacts';

  @override
  String get noContactsFound => 'Aucun contact trouvé';

  @override
  String get noLandlordsFound => 'Aucun propriétaire trouvé';

  @override
  String get addPropertiesToConnect =>
      'Ajoutez des propriétés pour vous connecter avec les locataires';

  @override
  String get landlordContactsAppear =>
      'Vos contacts propriétaires apparaîtront ici';

  @override
  String get property => 'Propriété';

  @override
  String get call => 'Appeler';

  @override
  String get message => 'Message';

  @override
  String get details => 'Détails';

  @override
  String get openChat => 'Ouvrir le chat';

  @override
  String get phoneCallFunctionality =>
      'La fonctionnalité d\'appel téléphonique sera implémentée';

  @override
  String get contactInformation => 'Informations de contact';

  @override
  String get assignedProperties => 'Propriétés assignées';

  @override
  String get filterOptions => 'Les options de filtre seront implémentées';

  @override
  String get active => 'Actif';

  @override
  String get editProfile => 'Modifier le profil';

  @override
  String get role => 'Rôle';

  @override
  String get disabled => 'désactivé';

  @override
  String get privacySettings => 'Paramètres de confidentialité';

  @override
  String get privacySettingsMessage =>
      'Les paramètres de confidentialité seront bientôt disponibles';

  @override
  String get receiveUpdatesEmail => 'Recevoir les mises à jour par e-mail';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get quickActions => 'Actions rapides';

  @override
  String get viewProperties => 'Voir les propriétés';

  @override
  String get outstanding => 'En suspens';

  @override
  String get description => 'Description';

  @override
  String get amenities => 'Commodités';

  @override
  String get balcony => 'Balcon';

  @override
  String get elevator => 'Ascenseur';

  @override
  String get laundry => 'Buanderie';

  @override
  String get location => 'Emplacement';

  @override
  String get financialDetails => 'Détails financiers';

  @override
  String get inviteTenant => 'Inviter un locataire';

  @override
  String get outstandingPayments => 'Paiements en suspens';

  @override
  String get searchContacts => 'Rechercher des contacts...';

  @override
  String get searchPropertiesTenantsMessages =>
      'Rechercher propriétés, locataires, messages...';

  @override
  String get typeAMessage => 'Tapez un message...';

  @override
  String get managePropertiesAndTenants => 'Gérez vos propriétés et locataires';

  @override
  String get monthlyIncome => 'Revenus mensuels';

  @override
  String get squareMeters => 'm²';

  @override
  String get chfPerMonth => 'CHF/mois';

  @override
  String get propertyDescription =>
      'Propriété moderne située dans un emplacement privilégié avec d\'excellentes commodités et un accès pratique aux transports publics.';

  @override
  String get landlord => 'Propriétaire';

  @override
  String get updateYourInformation =>
      'Mettez à jour vos informations personnelles';

  @override
  String get appSettings => 'Paramètres de l\'app';

  @override
  String get updatePassword => 'Mettez à jour votre mot de passe';

  @override
  String get signOutOfAccount => 'Déconnectez-vous de votre compte';

  @override
  String get confirmLogout => 'Confirmer la déconnexion';

  @override
  String get logoutConfirmation => 'Êtes-vous sûr de vouloir vous déconnecter?';

  @override
  String get searchToFindResults =>
      'Commencez à taper pour trouver des résultats';

  @override
  String get searchHint => 'Rechercher des propriétés, locataires ou messages';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get tryDifferentSearch => 'Essayez un terme de recherche différent';

  @override
  String get filterProperties => 'Filtrer les propriétés';

  @override
  String get filterRequests => 'Filtrer les demandes';

  @override
  String get pending => 'En attente';

  @override
  String get inProgress => 'En cours';

  @override
  String get completed => 'Terminé';

  @override
  String get cancelled => 'Annulé';

  @override
  String get priority => 'Priorité';

  @override
  String get low => 'Basse';

  @override
  String get medium => 'Moyenne';

  @override
  String get high => 'Haute';

  @override
  String get emergency => 'Urgence';

  @override
  String get noMaintenanceRequests => 'Aucune demande de maintenance';

  @override
  String get noMaintenanceRequestsDescription =>
      'Toutes les demandes de maintenance apparaîtront ici';

  @override
  String get getDirections => 'Obtenir l\'itinéraire';

  @override
  String get locationNotAvailable => 'Emplacement non disponible';

  @override
  String get addressDisplayOnly =>
      'Adresse affichée à titre de référence uniquement';

  @override
  String get twoFactorAuth => 'Authentification à deux facteurs';

  @override
  String get helpCenter => 'Centre d\'aide';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get enabled => 'activé';

  @override
  String get pushNotificationSubtitle =>
      'Recevoir des mises à jour sur votre appareil';

  @override
  String get paymentReminderSubtitle => 'Être rappelé des paiements à venir';

  @override
  String get welcomeToHelpCenter => 'Bienvenue au centre d\'aide';

  @override
  String get helpCenterDescription =>
      'Trouvez des réponses aux questions fréquentes, apprenez les fonctionnalités d\'ImmoSync et obtenez de l\'aide quand vous en avez besoin.';

  @override
  String get quickLinks => 'Liens rapides';

  @override
  String get gettingStarted => 'Commencer';

  @override
  String get gettingStartedDescription =>
      'Apprenez les bases de l\'utilisation d\'ImmoSync';

  @override
  String get accountSettings => 'Compte et paramètres';

  @override
  String get accountSettingsDescription =>
      'Gérez votre compte et vos paramètres de confidentialité';

  @override
  String get propertyManagement => 'Gestion immobilière';

  @override
  String get propertyManagementDescription =>
      'Comment ajouter et gérer des propriétés';

  @override
  String get paymentsBilling => 'Paiements et facturation';

  @override
  String get paymentsBillingDescription =>
      'Comprendre les paiements et la facturation';

  @override
  String get frequentlyAskedQuestions => 'Questions fréquemment posées';

  @override
  String get howToAddProperty => 'Comment ajouter une nouvelle propriété ?';

  @override
  String get howToAddPropertyAnswer =>
      'Allez à l\'onglet Propriétés et appuyez sur le bouton \"+\". Remplissez les détails de la propriété, ajoutez des photos et enregistrez.';

  @override
  String get howToInviteTenant => 'Comment inviter un locataire ?';

  @override
  String get howToInviteTenantAnswer =>
      'Ouvrez une propriété et appuyez sur \"Inviter un locataire\". Entrez leur adresse e-mail et ils recevront une invitation.';

  @override
  String get howToChangeCurrency => 'Comment changer ma devise ?';

  @override
  String get howToChangeCurrencyAnswer =>
      'Allez à Paramètres > Préférences > Devise et sélectionnez votre devise préférée.';

  @override
  String get howToEnable2FA =>
      'Comment activer l\'authentification à deux facteurs ?';

  @override
  String get howToEnable2FAAnswer =>
      'Allez à Paramètres > Sécurité > Authentification à deux facteurs et suivez les instructions de configuration.';

  @override
  String get howToExportData => 'Comment exporter mes données ?';

  @override
  String get howToExportDataAnswer =>
      'Allez à Paramètres > Paramètres de confidentialité > Gestion des données > Exporter mes données.';

  @override
  String get userGuides => 'Guides utilisateur';

  @override
  String get landlordGuide => 'Guide du propriétaire';

  @override
  String get landlordGuideDescription => 'Guide complet pour les propriétaires';

  @override
  String get tenantGuide => 'Guide du locataire';

  @override
  String get tenantGuideDescription => 'Guide complet pour les locataires';

  @override
  String get securityBestPractices => 'Meilleures pratiques de sécurité';

  @override
  String get securityBestPracticesDescription => 'Gardez votre compte sécurisé';

  @override
  String get needMoreHelp => 'Besoin d\'aide supplémentaire ?';

  @override
  String get needMoreHelpDescription =>
      'Vous ne trouvez pas ce que vous cherchez ? Notre équipe de support est là pour vous aider.';

  @override
  String get gotIt => 'Compris';

  @override
  String get gettingStartedWelcome =>
      'Bienvenue sur ImmoSync ! Voici comment commencer :';

  @override
  String get gettingStartedStep1 => '1. Complétez votre profil';

  @override
  String get gettingStartedStep2 => '2. Ajoutez votre première propriété';

  @override
  String get gettingStartedStep3 =>
      '3. Invitez des locataires ou connectez-vous avec des propriétaires';

  @override
  String get gettingStartedStep4 => '4. Commencez à gérer vos propriétés';

  @override
  String get propertyManagementGuide =>
      'Gestion des propriétés dans ImmoSync :';

  @override
  String get propertyManagementTip1 =>
      '• Ajouter des détails et photos de propriété';

  @override
  String get propertyManagementTip2 =>
      '• Définir les prix de location et les conditions';

  @override
  String get propertyManagementTip3 =>
      '• Inviter des locataires pour visites ou location';

  @override
  String get propertyManagementTip4 => '• Suivre les demandes de maintenance';

  @override
  String get propertyManagementTip5 => '• Surveiller le statut des paiements';

  @override
  String get paymentsGuide => 'Comprendre les paiements dans ImmoSync :';

  @override
  String get paymentsTip1 => '• Voir l\'historique et le statut des paiements';

  @override
  String get paymentsTip2 =>
      '• Configurer des rappels de paiement automatiques';

  @override
  String get paymentsTip3 => '• Suivre les paiements en attente';

  @override
  String get paymentsTip4 => '• Générer des rapports de paiement';

  @override
  String get paymentsTip5 => '• Exporter les données de paiement';

  @override
  String get landlordGuideContent => 'Guide complet pour les propriétaires :';

  @override
  String get landlordTip1 => '• Gestion du portefeuille immobilier';

  @override
  String get landlordTip2 => '• Sélection et intégration des locataires';

  @override
  String get landlordTip3 => '• Collecte et suivi des loyers';

  @override
  String get landlordTip4 => '• Traitement des demandes de maintenance';

  @override
  String get landlordTip5 => '• Reporting financier et analytique';

  @override
  String get landlordTip6 => '• Conformité légale et documentation';

  @override
  String get tenantGuideContent => 'Guide complet pour les locataires :';

  @override
  String get tenantTip1 => '• Recherche et visite de propriétés';

  @override
  String get tenantTip2 => '• Processus de candidature locative';

  @override
  String get tenantTip3 => '• Contrats de location et documentation';

  @override
  String get tenantTip4 => '• Paiement de loyer et historique';

  @override
  String get tenantTip5 => '• Soumission de demandes de maintenance';

  @override
  String get tenantTip6 => '• Communication avec les propriétaires';

  @override
  String get securityGuideContent => 'Gardez votre compte sécurisé :';

  @override
  String get securityTip1 => '• Utilisez un mot de passe fort et unique';

  @override
  String get securityTip2 => '• Activez l\'authentification à deux facteurs';

  @override
  String get securityTip3 =>
      '• Vérifiez régulièrement les paramètres de confidentialité';

  @override
  String get securityTip4 => '• Soyez prudent avec les informations partagées';

  @override
  String get securityTip5 => '• Signalez immédiatement les activités suspectes';

  @override
  String get securityTip6 => '• Gardez l\'application à jour';

  @override
  String get weAreHereToHelp => 'Nous sommes là pour vous aider';

  @override
  String get supportTeamDescription =>
      'Notre équipe de support est prête à vous aider avec toutes questions ou problèmes. Choisissez comment vous souhaitez nous contacter.';

  @override
  String get quickContact => 'Contact rapide';

  @override
  String get emailUs => 'Nous envoyer un e-mail';

  @override
  String get callUs => 'Nous appeler';

  @override
  String get liveChat => 'Chat en direct';

  @override
  String get submitSupportRequest => 'Soumettre une demande de support';

  @override
  String get supportFormDescription =>
      'Remplissez le formulaire ci-dessous et nous vous répondrons dès que possible.';

  @override
  String get accountInformation => 'Informations du compte';

  @override
  String get name => 'Nom';

  @override
  String get notAvailable => 'Non disponible';

  @override
  String get category => 'Catégorie';

  @override
  String get general => 'Général';

  @override
  String get accountAndSettings => 'Compte et paramètres';

  @override
  String get technicalIssues => 'Problèmes techniques';

  @override
  String get securityConcerns => 'Préoccupations de sécurité';

  @override
  String get featureRequest => 'Demande de fonctionnalité';

  @override
  String get bugReport => 'Rapport de bug';

  @override
  String get urgent => 'Urgent';

  @override
  String get subject => 'Sujet';

  @override
  String get subjectHint => 'Brève description de votre problème';

  @override
  String get pleaseEnterSubject => 'Veuillez saisir un sujet';

  @override
  String get describeYourIssue => 'Décrivez votre problème';

  @override
  String get issueDescriptionHint =>
      'Veuillez fournir autant de détails que possible pour nous aider à mieux vous assister';

  @override
  String get pleaseDescribeIssue => 'Veuillez décrire votre problème';

  @override
  String get provideMoreDetails =>
      'Veuillez fournir plus de détails (au moins 10 caractères)';

  @override
  String get submitRequest => 'Soumettre la demande';

  @override
  String get supportInformation => 'Informations de support';

  @override
  String get responseTime => 'Temps de réponse';

  @override
  String get responseTimeInfo => 'Généralement dans les 24 heures';

  @override
  String get languages => 'Langues';

  @override
  String get languagesSupported => 'Allemand, Anglais, Français, Italien';

  @override
  String get supportHours => 'Heures de support';

  @override
  String get supportHoursInfo => 'Lundi-Vendredi, 9h00-18h00 CET';

  @override
  String get emergencyInfo =>
      'Pour les problèmes urgents, appelez le +41 800 123 456';

  @override
  String get couldNotOpenEmail => 'Impossible d\'ouvrir l\'application e-mail';

  @override
  String get couldNotOpenPhone =>
      'Impossible d\'ouvrir l\'application téléphone';

  @override
  String get liveChatTitle => 'Chat en direct';

  @override
  String get liveChatAvailable =>
      'Le chat en direct est actuellement disponible pendant les heures d\'ouverture (Lundi-Vendredi, 9h00-18h00 CET).';

  @override
  String get liveChatOutsideHours =>
      'Pour une aide immédiate en dehors des heures d\'ouverture, veuillez utiliser le formulaire de support ou nous envoyer un e-mail.';

  @override
  String get close => 'Fermer';

  @override
  String get startChat => 'Démarrer le chat';

  @override
  String get liveChatSoon =>
      'Fonctionnalité de chat en direct bientôt disponible';

  @override
  String get supportRequestSubmitted =>
      'Demande de support soumise avec succès ! Nous vous répondrons bientôt.';

  @override
  String get myTenants => 'Mes locataires';

  @override
  String get myLandlords => 'Mes propriétaires';

  @override
  String get maintenanceRequestDetails =>
      'Détails de la demande de maintenance';

  @override
  String get blockUser => 'Bloquer l\'utilisateur';

  @override
  String get reportConversation => 'Signaler la conversation';

  @override
  String get deleteConversation => 'Supprimer la conversation';

  @override
  String get myMaintenanceRequests => 'Mes demandes de maintenance';

  @override
  String get errorLoadingRequests => 'Erreur lors du chargement des demandes';

  @override
  String get createRequest => 'Créer une demande';

  @override
  String get created => 'Créé';

  @override
  String get updated => 'Mis à jour';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get statusPending => 'En attente';

  @override
  String get statusInProgress => 'En cours';

  @override
  String get statusCompleted => 'Terminé';

  @override
  String get statusCancelled => 'Annulé';

  @override
  String get priorityHigh => 'Haute';

  @override
  String get priorityMedium => 'Moyenne';

  @override
  String get priorityLow => 'Basse';

  @override
  String get addNote => 'Ajouter une note';

  @override
  String get invalid => 'Invalide';

  @override
  String get failed => 'Échoué';

  @override
  String get success => 'Succès';

  @override
  String get loading => 'Chargement...';

  @override
  String get error => 'Erreur';

  @override
  String get update => 'Mettre à jour';

  @override
  String get delete => 'Supprimer';

  @override
  String get save => 'Enregistrer';

  @override
  String get edit => 'Modifier';

  @override
  String get view => 'Voir';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get previous => 'Précédent';

  @override
  String get confirm => 'Confirmer';

  @override
  String get submit => 'Soumettre';

  @override
  String get upload => 'Télécharger';

  @override
  String get download => 'Télécharger';

  @override
  String get share => 'Partager';

  @override
  String get copy => 'Copier';

  @override
  String get paste => 'Coller';

  @override
  String get select => 'Sélectionner';

  @override
  String get choose => 'Choisir';

  @override
  String get filter => 'Filtrer';

  @override
  String get sort => 'Trier';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get searchServices => 'Rechercher des services...';

  @override
  String get confirmBooking => 'Confirmer la réservation';

  @override
  String get bookingConfirmed => 'Réservation confirmée';

  @override
  String get unableToOpenChat =>
      'Impossible d\'ouvrir le chat. Veuillez réessayer.';

  @override
  String get failedToSendMessage => 'Échec de l\'envoi du message';

  @override
  String get chooseExportFormat => 'Choisir le format d\'exportation :';

  @override
  String get errorLoadingPayments => 'Erreur lors du chargement des paiements';

  @override
  String get errorLoadingProperties =>
      'Erreur lors du chargement des propriétés';

  @override
  String get errorLoadingPropertyMetrics =>
      'Erreur lors du chargement des métriques de propriété';

  @override
  String get errorLoadingMaintenanceData =>
      'Erreur lors du chargement des données de maintenance';

  @override
  String get errorLoadingPaymentSummary =>
      'Erreur lors du chargement du résumé des paiements';

  @override
  String get errorLoadingMaintenanceRequests =>
      'Erreur lors du chargement des demandes de maintenance';

  @override
  String get errorLoadingPaymentHistory =>
      'Erreur lors du chargement de l\'historique des paiements';

  @override
  String get searchConversationsHint => 'Rechercher des conversations...';

  @override
  String get searchContactsHint => 'Rechercher des contacts...';

  @override
  String get failedToStartConversation =>
      'Échec du démarrage de la conversation';

  @override
  String get failedToLoadImage => 'Échec du chargement de l\'image';

  @override
  String get recentMessages => 'Messages récents';

  @override
  String get propertyManager => 'Gestionnaire immobilier';

  @override
  String get documents => 'Documents';

  @override
  String get autoPayment => 'Paiement automatique';

  @override
  String get paymentHistory => 'Historique des paiements';

  @override
  String get searchPropertiesMaintenanceMessages =>
      'Rechercher propriétés, maintenance, messages...';

  @override
  String get errorGeneric => 'Erreur';

  @override
  String get pleaseSelectProperty => 'Veuillez sélectionner une propriété';

  @override
  String get maintenanceRequestSubmittedSuccessfully =>
      'Demande de maintenance soumise avec succès';

  @override
  String get failedToSubmitRequest => 'Échec de la soumission de la demande';

  @override
  String get statusUpdatedTo => 'Statut mis à jour à';

  @override
  String get failedToUpdateStatus => 'Échec de la mise à jour du statut';

  @override
  String get noteAddedSuccessfully => 'Note ajoutée avec succès';

  @override
  String get failedToAddNote => 'Échec de l\'ajout de la note';

  @override
  String get filterOptionsWillBeImplemented =>
      'Les options de filtrage seront implémentées';

  @override
  String get imagesSelected => 'Image(s) sélectionnée(s)';

  @override
  String get noImagesSelected => 'Aucune image sélectionnée';

  @override
  String get errorSelectingImages => 'Erreur lors de la sélection des images';

  @override
  String get propertyUpdatedSuccessfully =>
      'Propriété mise à jour avec succès !';

  @override
  String get propertyCreatedSuccessfully => 'Propriété créée avec succès !';

  @override
  String get deleteService => 'Supprimer le service';

  @override
  String get serviceDeleted => 'Service supprimé';

  @override
  String get searchPropertiesLandlordsMessages =>
      'Rechercher propriétés, propriétaires, messages...';

  @override
  String get errorLoadingConversations =>
      'Erreur lors du chargement des conversations';

  @override
  String get allowViewBasicProfile =>
      'Permettre aux autres utilisateurs de voir vos informations de profil de base';

  @override
  String get letUsersFindsPropertiesInSearch =>
      'Permettre aux autres utilisateurs de trouver vos propriétés dans les résultats de recherche';

  @override
  String get shareUsageAnalytics => 'Partager les analyses d\'utilisation';

  @override
  String get getUpdatesAboutNewFeatures =>
      'Recevoir des mises à jour sur les nouvelles fonctionnalités, conseils et offres spéciales';

  @override
  String get downloadCopyPersonalData =>
      'Télécharger une copie de vos données personnelles';

  @override
  String get permanentlyDeleteAccount =>
      'Supprimer définitivement le compte et toutes les données';

  @override
  String get dataExportRequestSubmitted =>
      'Demande d\'export de données soumise. Vous recevrez un e-mail avec le lien de téléchargement.';

  @override
  String get accountDeletionRequestSubmitted =>
      'Demande de suppression de compte soumise';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get passwordChangedSuccessfully => 'Mot de passe changé avec succès';

  @override
  String get failedToChangePassword => 'Échec du changement de mot de passe';

  @override
  String get profileImageUploadComingSoon =>
      'Téléchargement d\'image de profil bientôt disponible';

  @override
  String get invalidChatParameters => 'Paramètres de chat invalides';

  @override
  String get allowOtherUsersViewProfile =>
      'Permettre aux autres utilisateurs de voir votre profil';

  @override
  String get letOtherUsersFindProperties =>
      'Permettre aux autres utilisateurs de trouver vos propriétés';

  @override
  String get shareUsageAnalyticsDesc =>
      'Partager les analyses d\'utilisation pour améliorer l\'application';

  @override
  String get getUpdatesNewFeatures =>
      'Recevoir des mises à jour sur les nouvelles fonctionnalités';

  @override
  String get downloadPersonalData => 'Télécharger vos données personnelles';

  @override
  String get permanentlyDeleteAccountData =>
      'Supprimer définitivement le compte et toutes les données';

  @override
  String get dataExportRequestSubmittedMessage =>
      'Demande d\'exportation de données soumise avec succès';

  @override
  String get accountDeletionRequestSubmittedMessage =>
      'Demande de suppression de compte soumise avec succès';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get pleaseEnterCurrentPassword =>
      'Veuillez saisir le mot de passe actuel';

  @override
  String get pleaseEnterNewPassword =>
      'Veuillez saisir le nouveau mot de passe';

  @override
  String get passwordTooShort => 'Mot de passe trop court';

  @override
  String get currentPasswordIncorrect => 'Mot de passe actuel incorrect';

  @override
  String get privacyVisibility => 'Confidentialité et visibilité';

  @override
  String get publicProfile => 'Profil public';

  @override
  String get searchVisibility => 'Visibilité dans la recherche';

  @override
  String get dataAndAnalytics => 'Données et analyses';

  @override
  String get communicationPreferences => 'Préférences de communication';

  @override
  String get marketingEmails => 'E-mails marketing';

  @override
  String get dataManagement => 'Gestion des données';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get requestDataExport => 'Demander l\'exportation des données';

  @override
  String get dangerZone => 'Zone dangereuse';

  @override
  String get thisActionCannotBeUndone =>
      'Cette action ne peut pas être annulée';

  @override
  String get pleaseTypeConfirmToDelete =>
      'Veuillez taper \'confirm\' pour supprimer';

  @override
  String get typeConfirmHere => 'Tapez \'confirm\' ici';

  @override
  String get pleaseTypeConfirm => 'Veuillez taper \'confirm\'';

  @override
  String get accountDeletion => 'Suppression du compte';

  @override
  String get areYouSureDeleteAccount =>
      'Êtes-vous sûr de vouloir supprimer votre compte ?';

  @override
  String get thisWillPermanentlyDelete => 'Cela supprimera définitivement :';

  @override
  String get allProperties => 'Toutes les propriétés';

  @override
  String get allConversations => 'Toutes les conversations';

  @override
  String get allDocuments => 'Tous les documents';

  @override
  String get allPaymentHistory => 'Tout l\'historique des paiements';

  @override
  String get profileInformation => 'Informations du profil';

  @override
  String get requestDeletion => 'Demander la suppression';

  @override
  String get editProfileInfo => 'Modifier les informations du profil';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom de famille';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get bio => 'Biographie';

  @override
  String get bioHint => 'Parlez-nous un peu de vous';

  @override
  String get pleaseEnterFirstName => 'Veuillez saisir le prénom';

  @override
  String get pleaseEnterLastName => 'Veuillez saisir le nom de famille';

  @override
  String get pleaseEnterValidEmail => 'Veuillez saisir un e-mail valide';

  @override
  String get phoneNumberOptional => 'Numéro de téléphone (optionnel)';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get profileUpdated => 'Profil mis à jour';

  @override
  String get profileUpdatedSuccessfully => 'Profil mis à jour avec succès';

  @override
  String get failedToUpdateProfile => 'Échec de la mise à jour du profil';

  @override
  String get uploadProfileImage => 'Télécharger une image de profil';

  @override
  String get takePhoto => 'Prendre une photo';

  @override
  String get chooseFromGallery => 'Choisir dans la galerie';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get tenant => 'Locataire';

  @override
  String get profileImageUpload => 'Téléchargement d\'image de profil';

  @override
  String get searchPropertiesLandlords =>
      'Rechercher propriétés, propriétaires';

  @override
  String get startTypingToFindResults =>
      'Commencez à taper pour trouver des résultats';

  @override
  String get tryDifferentSearchTerm =>
      'Essayez un terme de recherche différent';

  @override
  String get twoFactorAuthentication => 'Authentification à deux facteurs';

  @override
  String get removeTenant => 'Supprimer le locataire';

  @override
  String get removeTenantConfirmation =>
      'Êtes-vous sûr de vouloir supprimer ce locataire de la propriété ?';

  @override
  String get tenantRemovedSuccessfully => 'Locataire supprimé avec succès';

  @override
  String get failedToRemoveTenant => 'Échec de la suppression du locataire';

  @override
  String get invitations => 'Invitations';

  @override
  String get analyticsAndReports => 'Analyses & Rapports';

  @override
  String get revenueAnalytics => 'Analyses des revenus';

  @override
  String get revenueChartComingSoon =>
      'Graphique des revenus bientôt disponible';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois-ci';

  @override
  String get thisQuarter => 'Ce trimestre';

  @override
  String get thisYear => 'Cette année';

  @override
  String get reportPeriod => 'Période du rapport';

  @override
  String get financialSummary => 'Résumé financier';

  @override
  String get totalIncome => 'Revenu total';

  @override
  String get paymentSummary => 'Résumé des paiements';

  @override
  String get dashboardComponentsRequireBrowser =>
      'Les composants du tableau de bord nécessitent un navigateur web';

  @override
  String get dashboardAvailableOnWeb => 'Tableau de bord disponible sur le web';

  @override
  String visitWebForFullDashboard(Object component) {
    return 'Visitez la version web pour accéder au tableau de bord complet $component';
  }

  @override
  String get planBasic => 'Basic';

  @override
  String get planProfessional => 'Professionnel';

  @override
  String get planEnterprise => 'Entreprise';

  @override
  String get planBasicDescription =>
      'Parfait pour les propriétaires individuels';

  @override
  String get planProfessionalDescription =>
      'Idéal pour les portefeuilles immobiliers en croissance';

  @override
  String get planEnterpriseDescription =>
      'Pour les grandes sociétés de gestion immobilière';

  @override
  String get featureUpToThreeProperties => 'Jusqu\'à 3 propriétés';

  @override
  String get featureBasicTenantManagement => 'Gestion de locataires basique';

  @override
  String get featurePaymentTracking => 'Suivi des paiements';

  @override
  String get featureEmailSupport => 'Support e-mail';

  @override
  String get featureUpToFifteenProperties => 'Jusqu\'à 15 propriétés';

  @override
  String get featureAdvancedTenantManagement =>
      'Gestion avancée des locataires';

  @override
  String get featureAutomatedRentCollection => 'Collecte de loyer automatisée';

  @override
  String get featureMaintenanceRequestTracking =>
      'Suivi des demandes de maintenance';

  @override
  String get featureFinancialReports => 'Rapports financiers';

  @override
  String get featurePrioritySupport => 'Support prioritaire';

  @override
  String get featureUnlimitedProperties => 'Propriétés illimitées';

  @override
  String get featureMultiUserAccounts => 'Comptes multi-utilisateurs';

  @override
  String get featureAdvancedAnalytics => 'Analyses avancées';

  @override
  String get featureApiAccess => 'Accès API';

  @override
  String get featureCustomIntegrations => 'Intégrations personnalisées';

  @override
  String get featureDedicatedSupport => 'Support dédié';

  @override
  String documentDownloadedTo(Object path) {
    return 'Document téléchargé dans : $path';
  }

  @override
  String get openFolder => 'Ouvrir le dossier';

  @override
  String get downloadFailed => 'Échec du téléchargement';

  @override
  String get failedToOpen => 'Échec de l\'ouverture';

  @override
  String get openInExternalApp => 'Ouvrir dans une application externe';

  @override
  String get loadingDocument => 'Chargement du document...';

  @override
  String get unableToLoadDocument => 'Impossible de charger le document';

  @override
  String get downloadInstead => 'Télécharger à la place';

  @override
  String get viewImage => 'Voir l\'image';

  @override
  String get loadPreview => 'Charger l\'aperçu';

  @override
  String get downloadToDevice => 'Télécharger sur l\'appareil';

  @override
  String get failedToDisplayImage => 'Impossible d\'afficher l\'image';

  @override
  String get pdfDocument => 'Document PDF';

  @override
  String get imageFile => 'Fichier image';

  @override
  String get textFile => 'Fichier texte';

  @override
  String get wordDocument => 'Document Word';

  @override
  String get excelSpreadsheet => 'Feuille de calcul Excel';

  @override
  String get powerPointPresentation => 'Présentation PowerPoint';

  @override
  String get documentFile => 'Fichier document';

  @override
  String get expiringSoon => 'Expire bientôt';

  @override
  String get expired => 'Expiré';

  @override
  String expiresOn(Object date) {
    return 'Expire le $date';
  }

  @override
  String tenantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'locataires',
      one: 'locataire',
    );
    return '$count $_temp0';
  }

  @override
  String propertiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'propriétés',
      one: 'propriété',
    );
    return '$count $_temp0';
  }

  @override
  String daysAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count jours',
      one: 'Il y a 1 jour',
    );
    return '$_temp0';
  }

  @override
  String weeksAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il y a $count semaines',
      one: 'Il y a 1 semaine',
    );
    return '$_temp0';
  }

  @override
  String get financialOverview => 'Aperçu financier';

  @override
  String get subscriptionRequired => 'Abonnement requis';

  @override
  String get subscriptionRequiredMessage =>
      'Cette fonctionnalité est disponible avec un abonnement.';

  @override
  String get subscriptionChoosePlanMessage =>
      'Choisissez un plan pour débloquer toutes les fonctionnalités.';

  @override
  String get viewPlans => 'Voir les plans';

  @override
  String get total => 'Total';

  @override
  String get viewAllProperties => 'Voir toutes les propriétés';

  @override
  String get noRecentMessages => 'Aucun message récent';

  @override
  String get noPendingMaintenanceRequests =>
      'Aucune demande de maintenance en attente';

  @override
  String get errorLoadingMaintenanceRequest =>
      'Erreur de chargement de la demande de maintenance';

  @override
  String get goBack => 'Retour';

  @override
  String get contractorInformation => 'Informations du prestataire';

  @override
  String get contact => 'Contact';

  @override
  String get company => 'Entreprise';

  @override
  String get notes => 'Notes';

  @override
  String get reported => 'Signalé';

  @override
  String get urgency => 'Urgence';

  @override
  String get scheduled => 'Planifié';

  @override
  String get estimated => 'Estimé';

  @override
  String get actualCost => 'Coût réel';

  @override
  String get markAsInProgress => 'Marquer en cours';

  @override
  String get markAsCompleted => 'Marquer terminé';

  @override
  String get enterNoteHint => 'Entrer une note...';

  @override
  String get addingNote => 'Ajout de la note...';

  @override
  String get completePayment => 'Finaliser le paiement';

  @override
  String get perYearSuffix => 'par an';

  @override
  String get perMonthSuffix => 'par mois';

  @override
  String youSavePerYear(Object savings) {
    return 'Vous économisez $savings par an';
  }

  @override
  String get includedFeatures => 'Fonctionnalités incluses';

  @override
  String get paymentMethod => 'Méthode de paiement';

  @override
  String get paymentInfoSecure =>
      'Vos informations de paiement sont sécurisées';

  @override
  String get desktopPaymentNotSupported =>
      'Paiement sur bureau non pris en charge';

  @override
  String get desktopPaymentUseWebOrMobile =>
      'Veuillez utiliser le web ou l\'application mobile pour payer.';

  @override
  String get openWebVersion => 'Ouvrir la version web';

  @override
  String get redirectingToSecurePaymentPage =>
      'Redirection vers la page de paiement sécurisée...';

  @override
  String get subscriptionTerms => 'Conditions d\'abonnement';

  @override
  String subscriptionBulletAutoRenews(Object interval) {
    return 'Renouvellement automatique chaque $interval';
  }

  @override
  String get yearlyInterval => 'an';

  @override
  String get monthlyInterval => 'mois';

  @override
  String get subscriptionBulletCancelAnytime => 'Annulation à tout moment';

  @override
  String get subscriptionBulletRefundPolicy =>
      'Non remboursable après le début de la période de facturation';

  @override
  String get subscriptionBulletAgreeTerms =>
      'En vous abonnant vous acceptez nos conditions';

  @override
  String get subscribeNow => 'S\'abonner maintenant';

  @override
  String get continueOnWeb => 'Continuer sur le web';

  @override
  String paymentFailed(Object error) {
    return 'Paiement échoué : $error';
  }

  @override
  String subscriptionActivated(Object planName) {
    return 'Votre abonnement $planName est actif !';
  }

  @override
  String get getStarted => 'Commencer';
}
