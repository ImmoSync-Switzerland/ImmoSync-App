// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'ImmoLink';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get tenantDashboard => 'Mieter-Dashboard';

  @override
  String get landlordDashboard => 'Vermieter-Dashboard';

  @override
  String get upcomingPayments => 'Bevorstehende Zahlungen';

  @override
  String get payRent => 'Miete bezahlen';

  @override
  String get properties => 'Immobilien';

  @override
  String get tenants => 'Mieter';

  @override
  String get services => 'Dienstleistungen';

  @override
  String get messages => 'Nachrichten';

  @override
  String get reports => 'Berichte';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get theme => 'Theme';

  @override
  String get dashboardDesign => 'Dashboard-Design';

  @override
  String get currency => 'Währung';

  @override
  String get preferences => 'Einstellungen';

  @override
  String get security => 'Sicherheit';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get about => 'Über';

  @override
  String get logout => 'Abmelden';

  @override
  String get light => 'Hell';

  @override
  String get dark => 'Dunkel';

  @override
  String get system => 'System';

  @override
  String get english => 'Englisch';

  @override
  String get german => 'Deutsch';

  @override
  String get french => 'Französisch';

  @override
  String get italian => 'Italienisch';

  @override
  String get selectLanguage => 'Sprache auswählen';

  @override
  String get selectTheme => 'Theme auswählen';

  @override
  String get selectDashboardDesign => 'Dashboard-Design wählen';

  @override
  String get selectCurrency => 'Währung auswählen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String languageChangedTo(Object language) {
    return 'Sprache geändert zu $language';
  }

  @override
  String themeChangedTo(Object theme) {
    return 'Theme geändert zu $theme';
  }

  @override
  String dashboardDesignChangedTo(Object design) {
    return 'Dashboard-Design geändert zu $design';
  }

  @override
  String currencyChangedTo(Object currency) {
    return 'Währung geändert zu $currency';
  }

  @override
  String get dashboardDesignGlass => 'Glas (Modern)';

  @override
  String get dashboardDesignClassic => 'Klassisch (Standard)';

  @override
  String get dashboardDesignPromptDescription =>
      'Wähle deinen bevorzugten Stil. Du kannst dies später in den Einstellungen ändern.';

  @override
  String get dashboardDesignGlassDescription =>
      'Modernes, mattes Design mit kräftigen Farbverläufen.';

  @override
  String get dashboardDesignClassicDescription =>
      'Helle Karten mit einer klaren Business-Struktur.';

  @override
  String get messageStatusSending => 'Wird gesendet...';

  @override
  String messageStatusDeliveredAt(Object time) {
    return 'Zugestellt um $time';
  }

  @override
  String messageStatusReadAt(Object time) {
    return 'Gelesen um $time';
  }

  @override
  String get messageStatusRead => 'Gelesen';

  @override
  String get messageStatusDelivered => 'Zugestellt';

  @override
  String get messageStatusSent => 'Gesendet';

  @override
  String get welcome => 'Willkommen';

  @override
  String get totalProperties => 'Gesamte Immobilien';

  @override
  String get monthlyRevenue => 'Monatliche Einnahmen';

  @override
  String get revenueVsExpenses => 'Einnahmen vs. Ausgaben';

  @override
  String get totalRevenue => 'Gesamteinnahmen';

  @override
  String get totalExpenses => 'Gesamtausgaben';

  @override
  String get netIncome => 'Nettogewinn';

  @override
  String get monthlyRentDue => 'Monatliche Miete fällig';

  @override
  String get month => 'Monat';

  @override
  String get revenue => 'Einnahmen';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get net => 'Netto';

  @override
  String get occupancyRate => 'Auslastungsgrad';

  @override
  String get maintenanceRequests => 'Wartungsanfragen';

  @override
  String get search => 'Suchen';

  @override
  String get searchConversations => 'Unterhaltungen suchen...';

  @override
  String get searchProperties => 'Immobilien suchen...';

  @override
  String get noConversations => 'Keine Unterhaltungen gefunden';

  @override
  String get noProperties => 'Keine Immobilien gefunden';

  @override
  String get propertyDetails => 'Immobiliendetails';

  @override
  String get address => 'Adresse';

  @override
  String get type => 'Typ';

  @override
  String get status => 'Status';

  @override
  String get rent => 'Miete';

  @override
  String get available => 'Verfügbar';

  @override
  String get occupied => 'Belegt';

  @override
  String get maintenance => 'Wartung';

  @override
  String get area => 'Fläche';

  @override
  String get mapNotAvailable => 'Karte nicht verfügbar';

  @override
  String get contactLandlord => 'Vermieter kontaktieren';

  @override
  String get statusAvailable => 'Verfügbar';

  @override
  String get statusRented => 'Vermietet';

  @override
  String get statusMaintenance => 'Wartung';

  @override
  String get newMessage => 'Neue Nachricht';

  @override
  String get typeMessage => 'Nachricht eingeben...';

  @override
  String get send => 'Senden';

  @override
  String get revenueReport => 'Umsatzbericht';

  @override
  String get occupancyReport => 'Auslastungsbericht';

  @override
  String get maintenanceReport => 'Wartungsbericht';

  @override
  String get generateReport => 'Bericht erstellen';

  @override
  String get propertyBreakdown => 'Aufschlüsselung nach Immobilie';

  @override
  String get aggregateView => 'Gesamtansicht';

  @override
  String get occupancy => 'Auslastung';

  @override
  String get actual => 'Ist';

  @override
  String get planned => 'Soll';

  @override
  String get emailNotifications => 'E-Mail-Benachrichtigungen';

  @override
  String get pushNotifications => 'Push-Benachrichtigungen';

  @override
  String get paymentReminders => 'Zahlungserinnerungen';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get privacyPolicyLastUpdated =>
      'Zuletzt aktualisiert: 3. Oktober 2025';

  @override
  String get privacyPolicyContent =>
      'Diese Datenschutzerklärung erläutert, wie die ImmoSync KLG (\"ImmoSync\", \"wir\", \"uns\") personenbezogene Daten verarbeitet, wenn Sie unsere Website, Anwendungen und Dienste (die \"Dienste\") nutzen.\n\nImmoSync KLG, Hauptstrasse 38, 4411 Seltisberg, Baselland, Schweiz · Telefon: +41 76 391 94 00 · E‑Mail: info@immosync.ch\n\nInhaltsverzeichnis\n1. Verantwortlicher\n2. Welche Daten wir verarbeiten\n3. Zwecke und Rechtsgrundlagen\n4. Cookies und Tracking\n5. Analysen und Drittanbieter\n6. Weitergabe von Daten\n7. Internationale Übermittlungen\n8. Aufbewahrung\n9. Datensicherheit\n10. Minderjährige\n11. Ihre Rechte\n12. Ausübung Ihrer Rechte\n13. Änderungen dieser Erklärung\n14. Kontakt\n1. Verantwortlicher\nVerantwortlich für die Datenverarbeitung im Zusammenhang mit den Diensten ist die ImmoSync KLG. Für bestimmte Funktionen (z. B. Zahlungen über Stripe oder Push‑Benachrichtigungen) agieren externe Anbieter als eigenständige Verantwortliche oder als Auftragsverarbeiter.\n\n2. Welche Daten wir verarbeiten\nJe nach Nutzung der Dienste verarbeiten wir unter anderem folgende Kategorien personenbezogener Daten:\n\nAccount‑ und Profildaten (Name, E‑Mail, Telefonnummer, Adresse, Rollen)\nAuthentifizierungsdaten (Passwort‑Hashes, Tokens)\nNutzungs‑ und Protokolldaten (IP‑Adresse, Geräte/Browser‑Informationen, Aktionen, Zeitstempel)\nInhalte, die Sie bereitstellen (Nachrichten, Tickets, Dokumente, Medien)\nZahlungsbezogene Daten (über Stripe; vollständige Kartennummern speichern wir nicht)\nGeräte/App‑Daten für mobile Funktionen (Benachrichtigungen, Kontakte – nur mit Ihrer Zustimmung)\nKommunikationsdaten (Support‑Anfragen, Feedback)\n\n3. Zwecke und Rechtsgrundlagen\nWir verarbeiten personenbezogene Daten zu folgenden Zwecken und Rechtsgrundlagen nach DSGVO und Schweizer DSG (revDSG):\n\nBereitstellung und Betrieb der Dienste; Vertragserfüllung (Art. 6 Abs. 1 lit. b DSGVO)\nVerbesserung von Sicherheit, Stabilität und Leistung; Rechtsverteidigung (berechtigte Interessen, Art. 6 Abs. 1 lit. f DSGVO)\nKommunikation mit Ihnen (Vertrag, berechtigte Interessen oder Einwilligung)\nAbrechnung sowie Erfüllung gesetzlicher Pflichten (Art. 6 Abs. 1 lit. c DSGVO)\nMit Ihrer Einwilligung für optionale Funktionen (Art. 6 Abs. 1 lit. a DSGVO); Einwilligung kann jederzeit widerrufen werden\n\n4. Cookies und Tracking\nWir verwenden notwendige Cookies für grundlegende Funktionen und ggf. Analyse‑Cookies, um die Nutzung zu verstehen. Sie können Cookies in den Einstellungen Ihres Browsers steuern. Das Deaktivieren nicht notwendiger Cookies kann die Funktionalität beeinträchtigen.\n\n5. Analysen und Drittanbieter\nWir setzen vertrauenswürdige Anbieter für Infrastruktur, Analysen, Zahlungen, Messaging und Fehlerüberwachung ein. Diese Dienstleister verarbeiten Daten nur, soweit dies zur Leistungserbringung erforderlich ist und im Einklang mit den geltenden Datenschutzgesetzen.\n\nBeispiele: Hosting (z. B. Vercel/AWS), Zahlungen (Stripe), Analysen (z. B. datenschutzfreundliche Tools oder – wo zulässig – Google Analytics), Kommunikationsdienste.\n\n6. Weitergabe von Daten\nWir teilen Daten, soweit erforderlich, mit Auftragsverarbeitern und Partnern zur Erbringung der Dienste, zur Erfüllung rechtlicher Pflichten oder im Zusammenhang mit Unternehmensvorgängen. Ein Verkauf personenbezogener Daten findet nicht statt.\n\n7. Internationale Übermittlungen\nWerden personenbezogene Daten in Länder ohne angemessenes Schutzniveau übermittelt, setzen wir geeignete Garantien ein (z. B. Standardvertragsklauseln inkl. Schweizer Anhänge), um Ihre Daten zu schützen.\n\n8. Aufbewahrung\nWir bewahren personenbezogene Daten nur so lange auf, wie es für die beschriebenen Zwecke erforderlich ist oder wie es das Recht verlangt. Sind Daten nicht mehr erforderlich, löschen oder anonymisieren wir sie oder bewahren sie sicher auf, bis eine Löschung möglich ist (z. B. in Backups).\n\n9. Datensicherheit\nWir treffen dem Risiko angemessene technische und organisatorische Maßnahmen, u. a. Verschlüsselung, Zugriffskontrollen und Monitoring. Kein System ist zu 100 % sicher; die Nutzung der Dienste erfolgt auf eigenes Risiko.\n\n10. Minderjährige\nUnsere Dienste richten sich nicht an Kinder unter 18 Jahren. Wir erheben wissentlich keine Daten von Kindern. Sollten Sie der Ansicht sein, dass wir solche Daten erhoben haben, kontaktieren Sie uns bitte zur Löschung.\n\n11. Ihre Rechte\nJe nach Wohnsitz haben Sie Rechte auf Auskunft, Berichtigung, Löschung, Einschränkung, Datenübertragbarkeit und Widerspruch. Außerdem können Sie Beschwerde bei einer Aufsichtsbehörde einlegen (z. B. EDÖB in der Schweiz; eine Datenschutzbehörde im EWR; ICO im Vereinigten Königreich).\n\n12. Ausübung Ihrer Rechte\nZur Ausübung Ihrer Rechte oder zum Widerruf von Einwilligungen kontaktieren Sie uns unter info@immosync.ch oder nutzen Sie unser Kontaktformular unter immosync.ch/contact. Wir bearbeiten Anfragen entsprechend den gesetzlichen Vorgaben.\n\n13. Änderungen dieser Erklärung\nWir aktualisieren diese Erklärung bei Bedarf, um Änderungen unserer Verarbeitung oder rechtliche Anforderungen abzubilden. Das Datum \"Zuletzt aktualisiert\" oben weist auf die aktuellste Fassung hin.\n\n14. Kontakt\n\nImmoSync KLG\n\nHauptstrasse 38\n\n4411 Seltisberg (Baselland)\n\nSchweiz\n\nTelefon: +41 76 391 94 00\n\nE‑Mail: info@immosync.ch';

  @override
  String get termsOfService => 'Allgemeine Geschäftsbedingungen';

  @override
  String get termsOfServiceLastUpdated =>
      'Zuletzt aktualisiert: 1. Oktober 2025';

  @override
  String get termsOfServiceContent =>
      'Allgemeine Geschäftsbedingungen (AGB)\nZuletzt aktualisiert: 1. Oktober 2025\n\nDiese Allgemeinen Geschäftsbedingungen (\"AGB\") regeln die Nutzung aller Produkte, Dienstleistungen und Anwendungen der ImmoSync KLG (\"ImmoSync\", \"wir\", \"uns\"). Mit dem Zugriff auf oder der Nutzung unserer Dienste erklären Sie sich mit diesen Bedingungen einverstanden. Wenn Sie nicht zustimmen, dürfen Sie unsere Dienste nicht nutzen.\n\nImmoSync KLG, Hauptstrasse 38, 4411 Seltisberg, Baselland, Schweiz.\nTelefon: +41 76 391 94 00 · E-Mail: info@immosync.ch\n\nInhaltsverzeichnis\nVertragliche Grundlagen\n1. Unsere Dienstleistungen\n2. Rechte an geistigem Eigentum\n3. Zusicherungen der Nutzer\n4. Benutzerregistrierung\n5. Käufe und Zahlungen\n6. Abonnements\n7. Software\n8. Verbotene Aktivitäten\n9. Von Nutzern erstellte Inhalte\n10. Lizenz für Beiträge\n11. Richtlinien für Bewertungen\n12. Mobile Applikation\n13. Websites und Inhalte Dritter\n14. Verwaltung der Dienste\n15. Datenschutz\n16. Urheberrechtsverletzungen\n17. Laufzeit und Kündigung\n18. Änderungen und Unterbrechungen\n19. Anwendbares Recht\n20. Streitbeilegung\n21. Berichtigungen\n22. Haftungsausschluss\n23. Haftungsbeschränkung\n24. Freistellung\n25. Nutzerdaten\n26. Elektronische Kommunikation\n27. SMS-Mitteilungen\n28. Schlussbestimmungen\n29. Kontakt\nVertragliche Grundlagen\nDurch den Zugriff auf unsere Website https://immosync.ch, unsere mobilen Anwendungen oder sonstige Angebote (zusammen die \"Dienste\") erklären Sie, dass Sie mindestens 18 Jahre alt sind, über die erforderliche Handlungsfähigkeit verfügen und diese AGB gelesen sowie akzeptiert haben. Falls Sie im Namen einer juristischen Person handeln, sichern Sie zu, dass Sie dazu berechtigt sind und die Organisation an diese AGB binden dürfen.\n\nWir behalten uns vor, diese AGB jederzeit zu aktualisieren. Änderungen werden auf der Website veröffentlicht oder per E-Mail mitgeteilt. Die fortgesetzte Nutzung der Dienste nach Inkrafttreten der Änderungen gilt als Zustimmung zu den neuen Bedingungen.\n\n1. Unsere Dienstleistungen\nImmoSync bietet eine digitale Plattform zur Kommunikation und Zusammenarbeit zwischen Vermietern, Mietern, Dienstleistungsunternehmen und weiteren Beteiligten. Die Plattform wird kontinuierlich weiterentwickelt und kann Funktionen wie Messaging, Ticketing, Dokumentenverwaltung, Terminplanung, Integrationen und automatisierte Buchungen umfassen.\n\nDie Informationen, die über die Dienste bereitgestellt werden, sind nicht für Nutzer in Rechtsordnungen bestimmt, in denen der Zugriff oder die Nutzung gegen geltendes Recht verstossen würde. Nutzer, die von ausserhalb der Schweiz auf die Dienste zugreifen, sind selbst für die Einhaltung der dortigen Gesetze verantwortlich.\n\n2. Rechte an geistigem Eigentum\nSämtliche Inhalte, Marken, Designs, Software und Datenbanken innerhalb der Dienste sind Eigentum der ImmoSync KLG oder werden mit entsprechender Lizenz genutzt. Diese Inhalte sind urheberrechtlich und durch weitere Schutzrechte weltweit geschützt.\n\nWir gewähren Ihnen eine nicht übertragbare, widerrufliche und nicht exklusive Lizenz, die Dienste ausschliesslich für eigene Zwecke zu nutzen. Jegliche Vervielfältigung, Bearbeitung, Veröffentlichung oder sonstige Nutzung über den vertraglich vorgesehenen Umfang hinaus bedarf unserer schriftlichen Zustimmung.\n\n3. Zusicherungen der Nutzer\nSie garantieren, dass alle Angaben, die Sie bei der Registrierung oder Nutzung machen, wahrheitsgetreu, aktuell und vollständig sind und aktualisiert werden, sobald sich Änderungen ergeben. Sie verpflichten sich, die Dienste nur im Rahmen der gesetzlichen Vorgaben sowie dieser AGB zu nutzen und keine Rechte Dritter zu verletzen.\n\nDer Zugriff mittels automatisierter Tools, Bots oder ähnlichen Methoden ist untersagt. Wir behalten uns vor, Nutzerkonten zu sperren oder zu löschen, wenn Verstösse gegen diese Zusicherungen festgestellt werden.\n\n4. Benutzerregistrierung\nFür bestimmte Funktionen ist eine Registrierung erforderlich. Zugangsdaten sind vertraulich zu behandeln und dürfen nicht an Dritte weitergegeben werden. Sie haften für alle Aktivitäten, die über Ihr Konto erfolgen. Wir können Benutzernamen ablehnen oder ändern, wenn sie gegen Rechte Dritter verstossen oder irreführend sind.\n\n5. Käufe und Zahlungen\nZahlungen für Dienstleistungen oder Abonnements sind gemäss der jeweils ausgewiesenen Preise in Schweizer Franken (CHF) zu leisten. Akzeptierte Zahlungsmethoden werden auf der Website oder im Bestellprozess angezeigt. Steuern und Abgaben werden gemäss den gesetzlichen Vorgaben berechnet.\n\nSie verpflichten sich, aktuelle Zahlungsinformationen zu hinterlegen und autorisieren uns, fällige Beträge über die gewählte Zahlungsmethode einzuziehen. Wir behalten uns vor, Bestellungen zu prüfen, zu begrenzen oder abzulehnen.\n\n6. Abonnements\nUnsere Abonnements verlängern sich automatisch zum Ende der jeweiligen Laufzeit, sofern sie nicht fristgerecht gekündigt werden. Kündigungen sind über das Benutzerkonto möglich und werden zum Ende des laufenden Abrechnungszeitraums wirksam.\n\nKostenlose Testzeiträume können jederzeit beendet oder angepasst werden. Nach Ablauf eines Testzeitraums wird das Konto automatisch in ein kostenpflichtiges Abonnement überführt, sofern es nicht vorher gekündigt wird.\n\n7. Software\nWir können Software oder mobile Apps zur Verfügung stellen. Sofern für bestimmte Komponenten zusätzliche Lizenzbedingungen (EULA) gelten, haben diese Vorrang. Ohne ausdrückliche Genehmigung dürfen Sie die Software nicht dekompilieren, zurückentwickeln oder weitergeben.\n\n8. Verbotene Aktivitäten\nDie Nutzung der Dienste für rechtswidrige, betrügerische oder belästigende Zwecke ist untersagt. Dazu gehören insbesondere:\n\nSammlung oder Scraping von Daten ohne unsere Genehmigung,\nVeröffentlichung rechtswidriger, diffamierender oder diskriminierender Inhalte,\nVersuch, Sicherheitsfunktionen zu umgehen oder Schadsoftware einzuschleusen,\nMissbrauch von Supportkanälen, falsche Meldungen oder Identitätsdiebstahl.\nBei Verstössen behalten wir uns rechtliche Schritte, die Löschung von Inhalten und die Sperrung von Konten vor.\n\n9. Von Nutzern erstellte Inhalte\nUnsere Dienste können Funktionen bieten, die es Ihnen ermöglichen, Inhalte wie Texte, Bilder oder Dokumente hochzuladen. Sie sind verantwortlich dafür, dass Ihre Inhalte keine Rechte Dritter verletzen und nicht gegen geltendes Recht verstossen.\n\n10. Lizenz für Beiträge\nMit dem Hochladen oder Bereitstellen von Inhalten gewähren Sie uns ein weltweites, unentgeltliches, übertragbares und zeitlich unbegrenztes Nutzungsrecht, diese Inhalte zum Betrieb der Dienste zu verwenden, zu speichern, zu kopieren, zu bearbeiten und zu veröffentlichen. Sie behalten das Eigentum an Ihren Inhalten.\n\n11. Richtlinien für Bewertungen\nWenn Bewertungen oder Erfahrungsberichte abgegeben werden, müssen diese auf tatsächlichen Erfahrungen beruhen, sachlich sein und dürfen keine beleidigenden, diskriminierenden oder rechtsverletzenden Aussagen enthalten. Wir behalten uns vor, Bewertungen zu entfernen, die gegen diese Richtlinien verstossen.\n\n12. Mobile Applikation\nBei Nutzung unserer mobilen Apps erhalten Sie eine beschränkte, widerrufliche Lizenz zur Installation und Verwendung auf Ihren Geräten. Sie dürfen die App nicht verändern, weiterverteilen oder zur Erstellung konkurrierender Produkte nutzen. App-Marktplätze (z. B. Apple App Store, Google Play) sind Drittanbieter und nicht für Supportleistungen der App verantwortlich.\n\n13. Websites und Inhalte Dritter\nDie Dienste können Links zu Inhalten oder Websites Dritter enthalten. Wir übernehmen keine Verantwortung für deren Inhalte, Verfügbarkeit oder Datenschutzpraktiken. Die Nutzung erfolgt auf eigenes Risiko und unterliegt den jeweiligen Bedingungen der Drittanbieter.\n\n14. Verwaltung der Dienste\nWir behalten uns vor, Inhalte zu überwachen, den Zugriff zu beschränken, Daten zu löschen oder technische Anpassungen vorzunehmen, um den sicheren und ordnungsgemässen Betrieb der Dienste sicherzustellen. Wir sind jedoch nicht verpflichtet, alle Aktivitäten aktiv zu überwachen.\n\n15. Datenschutz\nDer Schutz Ihrer Daten ist uns wichtig. Informationen zur Verarbeitung personenbezogener Daten finden Sie in unserer Datenschutzerklärung, die Bestandteil dieser AGB ist. Durch die Nutzung der Dienste stimmen Sie der dort beschriebenen Verarbeitung zu.\n\n16. Urheberrechtsverletzungen\nSollten Sie glauben, dass über unsere Dienste Inhalte verbreitet werden, die Ihre Urheberrechte verletzen, kontaktieren Sie uns bitte umgehend unter Angabe ausreichender Informationen, damit wir den Sachverhalt prüfen können. Missbräuchliche Meldungen können rechtliche Folgen nach sich ziehen.\n\n17. Laufzeit und Kündigung\nDiese AGB gelten, solange Sie unsere Dienste nutzen. Wir können den Zugang zu den Diensten jederzeit aus wichtigem Grund ohne Vorankündigung sperren oder kündigen, insbesondere bei Verletzung dieser AGB oder geltenden Rechts. Sie können Ihr Konto jederzeit kündigen; bereits fällige Zahlungen bleiben unberührt.\n\n18. Änderungen und Unterbrechungen\nWir können die Dienste oder Teile davon anpassen, erweitern oder einstellen. Wartungsarbeiten können zu vorübergehenden Unterbrechungen führen. Wir haften nicht für Schäden, die durch unvermeidbare Ausfallzeiten oder notwendige Anpassungen entstehen.\n\n19. Anwendbares Recht\nDiese AGB unterliegen schweizerischem Recht unter Ausschluss der Kollisionsnormen und des Wiener Kaufrechts. Zwingende Verbraucherschutzvorschriften Ihres Wohnsitzstaates bleiben unberührt. Gerichtsstand ist Basel-Landschaft, Schweiz.\n\n20. Streitbeilegung\nStreitigkeiten versuchen wir zunächst gütlich zu lösen. Sollte keine Einigung erzielt werden, wird die Streitigkeit nach den Regeln des Europäischen Schiedsgerichtshofs (Sitz Strasbourg) durch einen Schiedsrichter entschieden. Schiedsort ist Basel-Stadt, Verfahrenssprache Deutsch. Gesetzliche Rechte auf gerichtliche Verfahren, insbesondere für Verbraucher, bleiben bestehen.\n\n21. Berichtigungen\nTrotz sorgfältiger Pflege können Informationen Fehler enthalten. Wir behalten uns das Recht vor, solche Fehler zu korrigieren und Inhalte jederzeit zu aktualisieren.\n\n22. Haftungsausschluss\nDie Dienste werden \"wie gesehen\" und \"wie verfügbar\" bereitgestellt. Soweit gesetzlich zulässig, übernehmen wir keine Gewährleistung für Verfügbarkeit, Fehlerfreiheit oder Eignung für einen bestimmten Zweck. Die Nutzung erfolgt auf eigenes Risiko.\n\n23. Haftungsbeschränkung\nWir haften nur für Schäden, die vorsätzlich oder grobfahrlässig verursacht wurden, sowie für Schäden aus der Verletzung von Leben, Körper oder Gesundheit. Für leichte Fahrlässigkeit haften wir nur bei Verletzung wesentlicher Vertragspflichten (Kardinalpflichten) und begrenzen die Haftung auf den vertragstypischen vorhersehbaren Schaden. Gesetzliche Haftung nach zwingendem Recht bleibt unberührt.\n\n24. Freistellung\nSie stellen uns von sämtlichen Ansprüchen Dritter frei, die aufgrund Ihrer Nutzung der Dienste, Ihrer Inhalte oder Verstösse gegen diese AGB gegen uns geltend gemacht werden. Dies umfasst angemessene Kosten der Rechtsverteidigung. Wir informieren Sie über entsprechende Ansprüche und koordinieren das Vorgehen mit Ihnen.\n\n25. Nutzerdaten\nSie sind für die Sicherung der von Ihnen hochgeladenen Daten verantwortlich. Obwohl wir regelmässige Backups durchführen, übernehmen wir keine Gewähr für den Verlust oder die Wiederherstellbarkeit von Daten, ausser wenn dieser Verlust durch unser grobes Verschulden verursacht wurde.\n\n26. Elektronische Kommunikation\nDie Kommunikation über E-Mail, In-App-Nachrichten oder Formulare gilt als schriftliche Mitteilung. Sie stimmen dem Empfang elektronischer Mitteilungen zu und verzichten auf eine Zustellung in Papierform, soweit gesetzlich erlaubt.\n\n27. SMS-Mitteilungen\nBei Aktivierung des SMS-Dienstes (z. B. für Zwei-Faktor-Authentifizierung) erhalten Sie technische Benachrichtigungen auf Ihr Mobiltelefon. Standardtarife Ihres Mobilfunkanbieters können anfallen. Eine Deaktivierung des Dienstes kann die Sicherheit oder Nutzung einzelner Funktionen einschränken.\n\n28. Schlussbestimmungen\nDiese AGB stellen die vollständige Vereinbarung zwischen Ihnen und uns dar. Sollten einzelne Bestimmungen unwirksam sein, bleibt die Wirksamkeit der übrigen Regelungen unberührt. Rechte und Pflichten dürfen ohne unsere Zustimmung nicht abgetreten werden. Ein Verzicht auf die Durchsetzung einzelner Rechte stellt keinen Verzicht für die Zukunft dar.\n\n29. Kontakt\nBei Fragen oder Anliegen zu diesen AGB kontaktieren Sie uns bitte:\n\nImmoSync KLG\nHauptstrasse 38\n4411 Seltisberg (Baselland)\nSchweiz\nTelefon: +41 76 391 94 00\nE-Mail: info@immosync.ch';

  @override
  String get copy => 'Kopieren';

  @override
  String get copied => 'Kopiert';

  @override
  String get export => 'Exportieren';

  @override
  String get exportComingSoon => 'Exportfunktion folgt in Kürze';

  @override
  String get tableOfContents => 'Inhalt';

  @override
  String get yourPrivacyMatters => 'Ihre Privatsphäre ist wichtig';

  @override
  String get trustBadgeText =>
      'Wir schützen Ihre Daten und geben Ihnen Kontrolle über Ihre Privatsphäre.';

  @override
  String get version => 'Version';

  @override
  String get unknownProperty => 'Unbekannte Immobilie';

  @override
  String get user => 'Benutzer';

  @override
  String get tenantManagement => 'Mieterverwaltung';

  @override
  String get manageTenantDescription =>
      'Verwalten Sie Ihre Mieter und deren Immobilienzuweisungen';

  @override
  String get totalTenants => 'Mieter insgesamt';

  @override
  String get activeTenants => 'Aktive Mieter';

  @override
  String get occupiedUnits => 'Belegte Einheiten';

  @override
  String get pendingIssues => 'Offene Probleme';

  @override
  String get propertiesAssigned => 'Zugewiesene Immobilien';

  @override
  String get empty => 'Leer';

  @override
  String get noTenantsFound => 'Keine Mieter gefunden';

  @override
  String get noTenantsYet => 'Noch keine Mieter';

  @override
  String get addPropertiesInviteTenants =>
      'Fügen Sie Immobilien hinzu und laden Sie Mieter ein, um zu beginnen';

  @override
  String get addProperty => 'Immobilie hinzufügen';

  @override
  String get addTenant => 'Mieter hinzufügen';

  @override
  String get loadingTenants => 'Mieter werden geladen...';

  @override
  String get errorLoadingTenants => 'Fehler beim Laden der Mieter';

  @override
  String get couldNotLoadTenants => 'Mieter konnten nicht geladen werden';

  @override
  String get pleaseTryAgainLater => 'Bitte versuchen Sie es später erneut';

  @override
  String get retryLoading => 'Wiederholen';

  @override
  String get editTenant => 'Mieter bearbeiten';

  @override
  String get deleteTenant => 'Mieter löschen';

  @override
  String get tenantDetails => 'Mieterdetails';

  @override
  String get email => 'E-Mail';

  @override
  String get phone => 'Telefon';

  @override
  String get viewDetails => 'Details anzeigen';

  @override
  String get searchTenants => 'Mieter suchen...';

  @override
  String get myProperties => 'Meine Immobilien';

  @override
  String get all => 'Alle';

  @override
  String get rented => 'VERMIETET';

  @override
  String get monthlyRent => 'Monatliche Miete';

  @override
  String get size => 'Größe';

  @override
  String get rooms => 'Zimmer';

  @override
  String get noPropertiesFound => 'Keine Immobilien gefunden';

  @override
  String get addFirstProperty =>
      'Fügen Sie Ihre erste Immobilie hinzu, um zu beginnen';

  @override
  String get noPropertiesAssigned =>
      'Diesem Mieter sind keine Immobilien zugewiesen';

  @override
  String get contactLandlordForAccess =>
      'Kontaktieren Sie Ihren Vermieter für Zugang zu Ihrer Immobilie';

  @override
  String get somethingWentWrong => 'Etwas ist schief gelaufen';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get noConversationsYet => 'Noch keine Unterhaltungen';

  @override
  String get tryAdjustingSearch =>
      'Versuchen Sie, Ihre Suchbegriffe anzupassen';

  @override
  String get startConversation =>
      'Beginnen Sie eine Unterhaltung mit Ihren Immobilien';

  @override
  String get newConversation => 'Neue Unterhaltung';

  @override
  String get propertySelectionMessage =>
      'Immobilienauswahl wird mit Datenbankintegration implementiert';

  @override
  String get create => 'Erstellen';

  @override
  String get landlords => 'Vermieter';

  @override
  String get errorLoadingContacts => 'Fehler beim Laden der Kontakte';

  @override
  String get noContactsFound => 'Keine Kontakte gefunden';

  @override
  String get noLandlordsFound => 'Keine Vermieter gefunden';

  @override
  String get addPropertiesToConnect =>
      'Fügen Sie Immobilien hinzu, um sich mit Mietern zu verbinden';

  @override
  String get landlordContactsAppear =>
      'Ihre Vermieter-Kontakte werden hier angezeigt';

  @override
  String get property => 'Immobilie';

  @override
  String get call => 'Anrufen';

  @override
  String get message => 'Nachricht';

  @override
  String get details => 'Details';

  @override
  String get openChat => 'Chat öffnen';

  @override
  String get phoneCallFunctionality => 'Anruffunktion wird implementiert';

  @override
  String get contactInformation => 'Kontaktinformationen';

  @override
  String get assignedProperties => 'Zugewiesene Immobilien';

  @override
  String get filterOptions => 'Filteroptionen werden implementiert';

  @override
  String get active => 'Aktiv';

  @override
  String get editProfile => 'Profil bearbeiten';

  @override
  String get role => 'Rolle';

  @override
  String get disabled => 'deaktiviert';

  @override
  String get privacySettings => 'Datenschutzeinstellungen';

  @override
  String get privacySettingsMessage =>
      'Datenschutzeinstellungen werden bald verfügbar sein';

  @override
  String get receiveUpdatesEmail => 'Updates per E-Mail erhalten';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get hello => 'Hallo';

  @override
  String get quickActions => 'Schnelle Aktionen';

  @override
  String get searchLandlordDashboardHint => 'Suche nach Immobilien, Mietern...';

  @override
  String get searchTenantDashboardHint => 'Suche nach Wohnungen, Zahlungen...';

  @override
  String get support => 'Support';

  @override
  String get revenueChart => 'Einnahmen-Diagramm';

  @override
  String get noRecentActivityYet => 'Noch keine aktuellen Aktivitäten';

  @override
  String get recentActivityDescription =>
      'Aktualisierungen zu Zahlungen, Wartung und Chats werden hier angezeigt.';

  @override
  String get viewProperties => 'Immobilien anzeigen';

  @override
  String get outstanding => 'Ausstehend';

  @override
  String get description => 'Beschreibung';

  @override
  String get amenities => 'Ausstattung';

  @override
  String get balcony => 'Balkon';

  @override
  String get elevator => 'Aufzug';

  @override
  String get laundry => 'Wäscherei';

  @override
  String get location => 'Standort';

  @override
  String get financialDetails => 'Finanzielle Details';

  @override
  String get inviteTenant => 'Mieter einladen';

  @override
  String get outstandingPayments => 'Ausstehende Zahlungen';

  @override
  String get searchContacts => 'Kontakte suchen...';

  @override
  String get searchPropertiesTenantsMessages =>
      'Immobilien, Mieter, Nachrichten suchen...';

  @override
  String get typeAMessage => 'Nachricht eingeben...';

  @override
  String get managePropertiesAndTenants =>
      'Verwalten Sie Ihre Immobilien und Mieter';

  @override
  String get monthlyIncome => 'Monatliche Einnahmen';

  @override
  String get squareMeters => 'm²';

  @override
  String get chfPerMonth => 'CHF/Monat';

  @override
  String get propertyDescription =>
      'Moderne Immobilie in bester Lage mit hervorragender Ausstattung und bequemer Anbindung an öffentliche Verkehrsmittel.';

  @override
  String get landlord => 'Vermieter';

  @override
  String get updateYourInformation =>
      'Aktualisieren Sie Ihre persönlichen Informationen';

  @override
  String get appSettings => 'App-Einstellungen';

  @override
  String get updatePassword => 'Aktualisieren Sie Ihr Passwort';

  @override
  String get signOutOfAccount => 'Aus Ihrem Konto abmelden';

  @override
  String get confirmLogout => 'Abmeldung bestätigen';

  @override
  String get logoutConfirmation =>
      'Sind Sie sicher, dass Sie sich abmelden möchten?';

  @override
  String get searchToFindResults =>
      'Beginnen Sie zu tippen, um Ergebnisse zu finden';

  @override
  String get searchHint => 'Nach Immobilien, Mietern oder Nachrichten suchen';

  @override
  String get noResultsFound => 'Keine Ergebnisse gefunden';

  @override
  String get tryDifferentSearch => 'Versuchen Sie einen anderen Suchbegriff';

  @override
  String get filterProperties => 'Immobilien filtern';

  @override
  String get filterRequests => 'Anfragen filtern';

  @override
  String get pending => 'Ausstehend';

  @override
  String get inProgress => 'In Bearbeitung';

  @override
  String get completed => 'Abgeschlossen';

  @override
  String get cancelled => 'Storniert';

  @override
  String get priority => 'Priorität';

  @override
  String get low => 'Niedrig';

  @override
  String get medium => 'Mittel';

  @override
  String get high => 'Hoch';

  @override
  String get emergency => 'Notfall';

  @override
  String get noMaintenanceRequests => 'Keine Wartungsanfragen';

  @override
  String get noMaintenanceRequestsDescription =>
      'Alle Wartungsanfragen werden hier angezeigt';

  @override
  String get getDirections => 'Route anzeigen';

  @override
  String get locationNotAvailable => 'Standort nicht verfügbar';

  @override
  String get addressDisplayOnly => 'Adresse nur zur Anzeige';

  @override
  String get twoFactorAuth => 'Zwei-Faktor-Authentifizierung';

  @override
  String get helpCenter => 'Hilfezentrum';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get enabled => 'aktiviert';

  @override
  String get pushNotificationSubtitle => 'Updates auf Ihrem Gerät erhalten';

  @override
  String get paymentReminderSubtitle =>
      'An anstehende Zahlungen erinnert werden';

  @override
  String get welcomeToHelpCenter => 'Willkommen im Hilfezentrum';

  @override
  String get helpCenterDescription =>
      'Finden Sie Antworten auf häufige Fragen, lernen Sie, wie Sie ImmoLink-Funktionen nutzen, und erhalten Sie Unterstützung, wenn Sie sie benötigen.';

  @override
  String get quickLinks => 'Schnellzugriffe';

  @override
  String get gettingStarted => 'Erste Schritte';

  @override
  String get gettingStartedDescription =>
      'Lernen Sie die Grundlagen der Nutzung von ImmoLink';

  @override
  String get accountSettings => 'Konto & Einstellungen';

  @override
  String get accountSettingsDescription =>
      'Verwalten Sie Ihr Konto und Ihre Datenschutzeinstellungen';

  @override
  String get propertyManagement => 'Immobilienverwaltung';

  @override
  String get propertyManagementDescription =>
      'Wie Sie Immobilien hinzufügen und verwalten';

  @override
  String get paymentsBilling => 'Zahlungen & Abrechnung';

  @override
  String get paymentsBillingDescription => 'Zahlungen und Abrechnung verstehen';

  @override
  String get frequentlyAskedQuestions => 'Häufig gestellte Fragen';

  @override
  String get howToAddProperty => 'Wie füge ich eine neue Immobilie hinzu?';

  @override
  String get howToAddPropertyAnswer =>
      'Gehen Sie zum Immobilien-Tab und tippen Sie auf die \"+\"-Schaltfläche. Füllen Sie die Immobiliendetails aus, fügen Sie Fotos hinzu und speichern Sie.';

  @override
  String get howToInviteTenant => 'Wie lade ich einen Mieter ein?';

  @override
  String get howToInviteTenantAnswer =>
      'Öffnen Sie eine Immobilie und tippen Sie auf \"Mieter einladen\". Geben Sie deren E-Mail-Adresse ein und sie erhalten eine Einladung.';

  @override
  String get howToChangeCurrency => 'Wie ändere ich meine Währung?';

  @override
  String get howToChangeCurrencyAnswer =>
      'Gehen Sie zu Einstellungen > Präferenzen > Währung und wählen Sie Ihre bevorzugte Währung.';

  @override
  String get howToEnable2FA =>
      'Wie aktiviere ich die Zwei-Faktor-Authentifizierung?';

  @override
  String get howToEnable2FAAnswer =>
      'Gehen Sie zu Einstellungen > Sicherheit > Zwei-Faktor-Authentifizierung und befolgen Sie die Einrichtungsanweisungen.';

  @override
  String get howToExportData => 'Wie exportiere ich meine Daten?';

  @override
  String get howToExportDataAnswer =>
      'Gehen Sie zu Einstellungen > Datenschutzeinstellungen > Datenverwaltung > Meine Daten exportieren.';

  @override
  String get userGuides => 'Benutzerhandbücher';

  @override
  String get landlordGuide => 'Vermieter-Handbuch';

  @override
  String get landlordGuideDescription => 'Vollständiges Handbuch für Vermieter';

  @override
  String get tenantGuide => 'Mieter-Handbuch';

  @override
  String get tenantGuideDescription => 'Vollständiges Handbuch für Mieter';

  @override
  String get securityBestPractices => 'Sicherheits-Best-Practices';

  @override
  String get securityBestPracticesDescription => 'Halten Sie Ihr Konto sicher';

  @override
  String get needMoreHelp => 'Benötigen Sie weitere Hilfe?';

  @override
  String get needMoreHelpDescription =>
      'Können Sie nicht finden, wonach Sie suchen? Unser Support-Team hilft Ihnen gerne.';

  @override
  String get gotIt => 'Verstanden';

  @override
  String get gettingStartedWelcome =>
      'Willkommen bei ImmoLink! So können Sie loslegen:';

  @override
  String get gettingStartedStep1 => '1. Vervollständigen Sie Ihr Profil';

  @override
  String get gettingStartedStep2 => '2. Fügen Sie Ihre erste Immobilie hinzu';

  @override
  String get gettingStartedStep3 =>
      '3. Laden Sie Mieter ein oder verbinden Sie sich mit Vermietern';

  @override
  String get gettingStartedStep4 =>
      '4. Beginnen Sie mit der Verwaltung Ihrer Immobilien';

  @override
  String get propertyManagementGuide =>
      'Verwaltung von Immobilien in ImmoLink:';

  @override
  String get propertyManagementTip1 =>
      '• Immobiliendetails und Fotos hinzufügen';

  @override
  String get propertyManagementTip2 => '• Mietpreise und Konditionen festlegen';

  @override
  String get propertyManagementTip3 =>
      '• Mieter zur Besichtigung oder Anmietung einladen';

  @override
  String get propertyManagementTip4 => '• Wartungsanfragen verfolgen';

  @override
  String get propertyManagementTip5 => '• Zahlungsstatus überwachen';

  @override
  String get paymentsGuide => 'Zahlungen in ImmoLink verstehen:';

  @override
  String get paymentsTip1 => '• Zahlungshistorie und Status anzeigen';

  @override
  String get paymentsTip2 => '• Automatische Zahlungserinnerungen einrichten';

  @override
  String get paymentsTip3 => '• Ausstehende Zahlungen verfolgen';

  @override
  String get paymentsTip4 => '• Zahlungsberichte erstellen';

  @override
  String get paymentsTip5 => '• Zahlungsdaten exportieren';

  @override
  String get landlordGuideContent => 'Vollständiges Handbuch für Vermieter:';

  @override
  String get landlordTip1 => '• Immobilienportfolio-Management';

  @override
  String get landlordTip2 => '• Mieter-Screening und Onboarding';

  @override
  String get landlordTip3 => '• Mieterfassung und -verfolgung';

  @override
  String get landlordTip4 => '• Bearbeitung von Wartungsanfragen';

  @override
  String get landlordTip5 => '• Finanzberichterstattung und -analytik';

  @override
  String get landlordTip6 => '• Rechtliche Compliance und Dokumentation';

  @override
  String get tenantGuideContent => 'Vollständiges Handbuch für Mieter:';

  @override
  String get tenantTip1 => '• Immobiliensuche und -besichtigung';

  @override
  String get tenantTip2 => '• Mietantragsprozess';

  @override
  String get tenantTip3 => '• Mietverträge und Dokumentation';

  @override
  String get tenantTip4 => '• Mietzahlung und -historie';

  @override
  String get tenantTip5 => '• Wartungsanfragen einreichen';

  @override
  String get tenantTip6 => '• Kommunikation mit Vermietern';

  @override
  String get securityGuideContent => 'Halten Sie Ihr Konto sicher:';

  @override
  String get securityTip1 =>
      '• Verwenden Sie ein starkes, einzigartiges Passwort';

  @override
  String get securityTip2 =>
      '• Aktivieren Sie die Zwei-Faktor-Authentifizierung';

  @override
  String get securityTip3 =>
      '• Überprüfen Sie regelmäßig die Datenschutzeinstellungen';

  @override
  String get securityTip4 =>
      '• Seien Sie vorsichtig mit geteilten Informationen';

  @override
  String get securityTip5 => '• Melden Sie verdächtige Aktivitäten sofort';

  @override
  String get securityTip6 => '• Halten Sie die App aktuell';

  @override
  String get weAreHereToHelp => 'Wir sind hier, um zu helfen';

  @override
  String get supportTeamDescription =>
      'Unser Support-Team steht bereit, Sie bei allen Fragen oder Problemen zu unterstützen. Wählen Sie, wie Sie Kontakt aufnehmen möchten.';

  @override
  String get quickContact => 'Schnellkontakt';

  @override
  String get emailUs => 'E-Mail senden';

  @override
  String get callUs => 'Anrufen';

  @override
  String get liveChat => 'Live-Chat';

  @override
  String get submitSupportRequest => 'Support-Anfrage senden';

  @override
  String get supportFormDescription =>
      'Füllen Sie das folgende Formular aus und wir melden uns so schnell wie möglich bei Ihnen.';

  @override
  String get accountInformation => 'Kontoinformationen';

  @override
  String get name => 'Name';

  @override
  String get notAvailable => 'Nicht verfügbar';

  @override
  String get category => 'Kategorie';

  @override
  String get general => 'Allgemein';

  @override
  String get accountAndSettings => 'Konto & Einstellungen';

  @override
  String get technicalIssues => 'Technische Probleme';

  @override
  String get securityConcerns => 'Sicherheitsbedenken';

  @override
  String get featureRequest => 'Feature-Anfrage';

  @override
  String get bugReport => 'Fehlerbericht';

  @override
  String get urgent => 'Dringend';

  @override
  String get subject => 'Betreff';

  @override
  String get subjectHint => 'Kurze Beschreibung Ihres Problems';

  @override
  String get pleaseEnterSubject => 'Bitte geben Sie einen Betreff ein';

  @override
  String get describeYourIssue => 'Beschreiben Sie Ihr Problem';

  @override
  String get issueDescriptionHint =>
      'Bitte geben Sie so viele Details wie möglich an, um uns zu helfen, Ihnen besser zu helfen';

  @override
  String get pleaseDescribeIssue => 'Bitte beschreiben Sie Ihr Problem';

  @override
  String get provideMoreDetails =>
      'Bitte geben Sie mehr Details an (mindestens 10 Zeichen)';

  @override
  String get submitRequest => 'Anfrage senden';

  @override
  String get supportInformation => 'Support-Informationen';

  @override
  String get responseTime => 'Antwortzeit';

  @override
  String get responseTimeInfo => 'Normalerweise innerhalb von 24 Stunden';

  @override
  String get languages => 'Sprachen';

  @override
  String get languagesSupported =>
      'Deutsch, Englisch, Französisch, Italienisch';

  @override
  String get supportHours => 'Support-Zeiten';

  @override
  String get supportHoursInfo => 'Montag-Freitag, 9:00-18:00 MEZ';

  @override
  String get emergencyInfo =>
      'Bei dringenden Problemen rufen Sie +41 800 123 456 an';

  @override
  String get couldNotOpenEmail => 'E-Mail-App konnte nicht geöffnet werden';

  @override
  String get couldNotOpenPhone => 'Telefon-App konnte nicht geöffnet werden';

  @override
  String get liveChatTitle => 'Live-Chat';

  @override
  String get liveChatAvailable =>
      'Live-Chat ist derzeit während der Geschäftszeiten verfügbar (Montag-Freitag, 9:00-18:00 MEZ).';

  @override
  String get liveChatOutsideHours =>
      'Für sofortige Hilfe außerhalb der Geschäftszeiten verwenden Sie bitte das Support-Formular oder senden Sie uns eine E-Mail.';

  @override
  String get close => 'Schließen';

  @override
  String get startChat => 'Chat starten';

  @override
  String get liveChatSoon => 'Live-Chat-Funktion wird bald verfügbar sein';

  @override
  String get supportRequestSubmitted =>
      'Support-Anfrage erfolgreich gesendet! Wir melden uns bald bei Ihnen.';

  @override
  String get supportRequests => 'Support-Anfragen';

  @override
  String get noSupportRequests => 'Keine Support-Anfragen vorhanden';

  @override
  String get supportRequestStatusOpen => 'Offen';

  @override
  String get supportRequestStatusInProgress => 'In Bearbeitung';

  @override
  String get supportRequestStatusClosed => 'Geschlossen';

  @override
  String supportRequestStatusChanged(Object status) {
    return 'Status geändert zu $status';
  }

  @override
  String get myTenants => 'Meine Mieter';

  @override
  String get myLandlords => 'Meine Vermieter';

  @override
  String get maintenanceRequestDetails => 'Details der Wartungsanfrage';

  @override
  String get blockUser => 'Benutzer blockieren';

  @override
  String get reportConversation => 'Unterhaltung melden';

  @override
  String get deleteConversation => 'Unterhaltung löschen';

  @override
  String get unblockUser => 'Blockierung aufheben';

  @override
  String get blockedLabel => 'Blockiert';

  @override
  String get block => 'Blockieren';

  @override
  String get unblock => 'Entsperren';

  @override
  String get report => 'Melden';

  @override
  String get userBlockedSuccessfully => 'Benutzer wurde blockiert';

  @override
  String failedToBlockUser(Object error) {
    return 'Benutzer konnte nicht blockiert werden: $error';
  }

  @override
  String get userUnblockedSuccessfully => 'Benutzer wurde entsperrt';

  @override
  String failedToUnblockUser(Object error) {
    return 'Benutzer konnte nicht entsperrt werden: $error';
  }

  @override
  String get mustBeLoggedInToReport => 'Bitte melden Sie sich an, um zu melden';

  @override
  String get unableToDetermineConversationToReport =>
      'Unterhaltung konnte nicht ermittelt werden';

  @override
  String get conversationReportedAndRemoved =>
      'Unterhaltung wurde gemeldet und entfernt';

  @override
  String failedToReportConversation(Object error) {
    return 'Meldung fehlgeschlagen: $error';
  }

  @override
  String get conversationDeletedSuccessfully => 'Unterhaltung wurde gelöscht';

  @override
  String failedToDeleteConversation(Object error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get blockConfirmBody =>
      'Möchten Sie diesen Benutzer wirklich blockieren? Sie erhalten keine Nachrichten mehr von ihm.';

  @override
  String get unblockConfirmBody =>
      'Möchten Sie diesen Benutzer entsperren? Sie können wieder Nachrichten austauschen.';

  @override
  String get reportConfirmBody =>
      'Möchten Sie diese Unterhaltung wirklich melden? Unser Support-Team wird sie prüfen.';

  @override
  String get deleteConversationConfirmBody =>
      'Möchten Sie diese Unterhaltung wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get chatOptions => 'Chat-Optionen';

  @override
  String get gallery => 'Galerie';

  @override
  String get camera => 'Kamera';

  @override
  String get document => 'Dokument';

  @override
  String get emojis => 'Emojis';

  @override
  String get imageReadyToSend => 'Bild bereit zum Senden';

  @override
  String get fileReadyToSend => 'Datei bereit zum Senden';

  @override
  String get pleaseSendTextFirst =>
      'Bitte senden Sie zuerst eine Textnachricht, um die Unterhaltung zu starten';

  @override
  String get missingRecipientForNewChat => 'Empfänger für neuen Chat fehlt';

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get encryptedMessagePlaceholder => '[verschlüsselt]';

  @override
  String get encryptionKeyNotReady =>
      'Verschlüsselungsschlüssel noch nicht bereit...';

  @override
  String get matrixInitializingSecureChat =>
      'Sicherer Chat wird initialisiert...';

  @override
  String get matrixPreparingE2ee =>
      'Ende-zu-Ende-Verschlüsselung wird vorbereitet...';

  @override
  String get matrixEstablishingRoom => 'Chatraum wird erstellt...';

  @override
  String get matrixErrorTryLater =>
      'Chat konnte nicht initialisiert werden. Bitte später erneut versuchen.';

  @override
  String get reconnect => 'Erneut verbinden';

  @override
  String get openFileFailed => 'Öffnen fehlgeschlagen';

  @override
  String get attachmentFailed => 'Anhang fehlgeschlagen';

  @override
  String get errorSelectingImage => 'Fehler beim Auswählen des Bildes';

  @override
  String get errorTakingPhoto => 'Fehler beim Aufnehmen des Fotos';

  @override
  String get errorSendingDocument => 'Fehler beim Senden des Dokuments';

  @override
  String get cannotMakeCallOnDevice =>
      'Auf diesem Gerät können keine Anrufe getätigt werden';

  @override
  String get errorInitiatingCall => 'Fehler beim Starten des Anrufs';

  @override
  String get invitationSentSuccessfully => 'Einladung erfolgreich gesendet';

  @override
  String get failedToSendInvitation => 'Senden der Einladung fehlgeschlagen';

  @override
  String get invitationAcceptedSuccessfully =>
      'Einladung erfolgreich angenommen!';

  @override
  String get invitationDeclined => 'Abgelehnt';

  @override
  String get failedToRespondInvitation =>
      'Antwort auf Einladung fehlgeschlagen';

  @override
  String get callPrompt => 'Möchten Sie diesen Anruf tätigen?';

  @override
  String get myMaintenanceRequests => 'Meine Wartungsanfragen';

  @override
  String get errorLoadingRequests => 'Fehler beim Laden der Anfragen';

  @override
  String get createRequest => 'Anfrage erstellen';

  @override
  String get created => 'Erstellt';

  @override
  String get updated => 'Aktualisiert';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get statusPending => 'Ausstehend';

  @override
  String get statusInProgress => 'In Bearbeitung';

  @override
  String get statusCompleted => 'Abgeschlossen';

  @override
  String get statusCancelled => 'Storniert';

  @override
  String get priorityHigh => 'Hoch';

  @override
  String get priorityMedium => 'Mittel';

  @override
  String get priorityLow => 'Niedrig';

  @override
  String get addNote => 'Notiz hinzufügen';

  @override
  String get invalid => 'Ungültig';

  @override
  String get failed => 'Fehlgeschlagen';

  @override
  String get success => 'Erfolgreich';

  @override
  String get loading => 'Lädt...';

  @override
  String get error => 'Fehler';

  @override
  String get update => 'Aktualisieren';

  @override
  String get delete => 'Löschen';

  @override
  String get save => 'Speichern';

  @override
  String get saveFilter => 'Filter speichern';

  @override
  String get propertyType => 'Immobilientyp';

  @override
  String get priceRange => 'Preisspanne';

  @override
  String get bedrooms => 'Schlafzimmer';

  @override
  String get beds => 'Betten';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get view => 'Anzeigen';

  @override
  String get back => 'Zurück';

  @override
  String get next => 'Weiter';

  @override
  String get previous => 'Zurück';

  @override
  String get confirm => 'Bestätigen';

  @override
  String get submit => 'Senden';

  @override
  String get upload => 'Hochladen';

  @override
  String get download => 'Herunterladen';

  @override
  String get share => 'Teilen';

  @override
  String get paste => 'Einfügen';

  @override
  String get select => 'Auswählen';

  @override
  String get choose => 'Wählen';

  @override
  String get filter => 'Filter';

  @override
  String get sort => 'Sortieren';

  @override
  String get noData => 'Keine Daten';

  @override
  String get tryAgain => 'Erneut versuchen';

  @override
  String get searchServices => 'Services suchen...';

  @override
  String get confirmBooking => 'Buchung bestätigen';

  @override
  String get bookingConfirmed => 'Buchung bestätigt';

  @override
  String get unableToOpenChat =>
      'Chat kann nicht geöffnet werden. Bitte versuchen Sie es erneut.';

  @override
  String get failedToSendMessage => 'Nachricht konnte nicht gesendet werden';

  @override
  String get chooseExportFormat => 'Exportformat wählen:';

  @override
  String get errorLoadingPayments => 'Fehler beim Laden der Zahlungen';

  @override
  String get errorLoadingProperties => 'Fehler beim Laden der Immobilien';

  @override
  String get errorLoadingPropertyMetrics =>
      'Fehler beim Laden der Immobilienkennzahlen';

  @override
  String get errorLoadingMaintenanceData =>
      'Fehler beim Laden der Wartungsdaten';

  @override
  String get errorLoadingPaymentSummary =>
      'Fehler beim Laden der Zahlungsübersicht';

  @override
  String get errorLoadingMaintenanceRequests =>
      'Fehler beim Laden der Wartungsanfragen';

  @override
  String get errorLoadingPaymentHistory =>
      'Fehler beim Laden der Zahlungshistorie';

  @override
  String get searchConversationsHint => 'Unterhaltungen suchen...';

  @override
  String get searchContactsHint => 'Kontakte suchen...';

  @override
  String get failedToStartConversation =>
      'Unterhaltung konnte nicht gestartet werden';

  @override
  String get failedToLoadImage => 'Bild konnte nicht geladen werden';

  @override
  String get failedToLoadMessages => 'Nachrichten konnten nicht geladen werden';

  @override
  String get recentMessages => 'Neueste Nachrichten';

  @override
  String get propertyManager => 'Immobilienverwalter';

  @override
  String get documents => 'Dokumente';

  @override
  String get autoPayment => 'Automatische Zahlung';

  @override
  String get paymentHistory => 'Zahlungshistorie';

  @override
  String get trackAllTransactions => 'Alle Transaktionen im Blick';

  @override
  String get filterPayments => 'Zahlungen filtern';

  @override
  String get allTypes => 'Alle Typen';

  @override
  String get other => 'Sonstiges';

  @override
  String get deposit => 'Kaution';

  @override
  String get fee => 'Gebühr';

  @override
  String get refunded => 'Erstattet';

  @override
  String get noPaymentHistoryFound => 'Keine Zahlungshistorie gefunden';

  @override
  String get paymentHistoryWillAppearAfterFirstPayment =>
      'Ihre Zahlungshistorie wird hier angezeigt, sobald Sie Ihre erste Zahlung vorgenommen haben.';

  @override
  String get loadingPaymentHistory => 'Zahlungshistorie wird geladen...';

  @override
  String get amount => 'Betrag';

  @override
  String get date => 'Datum';

  @override
  String get propertyId => 'Objekt-ID';

  @override
  String get tenantId => 'Mieter-ID';

  @override
  String get transactionId => 'Transaktions-ID';

  @override
  String get downloadReceipt => 'Beleg herunterladen';

  @override
  String get cancelPayment => 'Zahlung stornieren';

  @override
  String get confirmCancelPaymentMessage =>
      'Möchten Sie diese Zahlung wirklich stornieren? Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get no => 'Nein';

  @override
  String get yesCancel => 'Ja, stornieren';

  @override
  String get paymentCancelledSuccessfully => 'Zahlung erfolgreich storniert';

  @override
  String failedToCancelPayment(Object error) {
    return 'Zahlung konnte nicht storniert werden: $error';
  }

  @override
  String get receiptDownloadStarted => 'Beleg-Download gestartet';

  @override
  String failedToDownloadReceipt(Object error) {
    return 'Beleg konnte nicht heruntergeladen werden: $error';
  }

  @override
  String get couldNotOpenReceipt => 'Beleg konnte nicht geöffnet werden';

  @override
  String propertyIdWithValue(Object id) {
    return 'Objekt-ID: $id';
  }

  @override
  String methodWithValue(Object method) {
    return 'Methode: $method';
  }

  @override
  String get searchPropertiesMaintenanceMessages =>
      'Immobilien, Wartung, Nachrichten suchen...';

  @override
  String get errorGeneric => 'Fehler';

  @override
  String get pleaseSelectProperty => 'Bitte wählen Sie eine Immobilie';

  @override
  String get attach => 'Anhängen';

  @override
  String get maintenanceNewRequestTitle => 'Neue Anfrage';

  @override
  String get maintenanceNewRequestSubtitle =>
      'Melden Sie ein Problem mit Ihrer Immobilie.';

  @override
  String get maintenanceSelectPropertyHint => 'Immobilie auswählen';

  @override
  String get maintenanceIssueTitleLabel => 'Problem-Titel';

  @override
  String get maintenanceIssueTitleHint => 'Kurzer Titel für das Problem';

  @override
  String get maintenancePleaseEnterTitle => 'Bitte einen Titel eingeben';

  @override
  String get maintenanceSelectCategoryHint => 'Kategorie auswählen';

  @override
  String get maintenanceDescribeIssueHint =>
      'Beschreiben Sie das Problem im Detail...';

  @override
  String get maintenanceSubmittingRequest => 'Anfrage wird gesendet...';

  @override
  String get maintenanceCategoryPlumbing => 'Sanitär';

  @override
  String get maintenanceCategoryElectrical => 'Elektrik';

  @override
  String get maintenanceCategoryHeating => 'Heizung';

  @override
  String get maintenanceCategoryAppliances => 'Haushaltsgeräte';

  @override
  String get maintenanceCategoryGeneral => 'Allgemein';

  @override
  String get maintenanceRequestSubmittedSuccessfully =>
      'Wartungsanfrage erfolgreich eingereicht';

  @override
  String get failedToSubmitRequest => 'Anfrage konnte nicht eingereicht werden';

  @override
  String get statusUpdatedTo => 'Status aktualisiert auf';

  @override
  String get failedToUpdateStatus => 'Status konnte nicht aktualisiert werden';

  @override
  String get noteAddedSuccessfully => 'Notiz erfolgreich hinzugefügt';

  @override
  String get failedToAddNote => 'Notiz konnte nicht hinzugefügt werden';

  @override
  String get filterOptionsWillBeImplemented =>
      'Filteroptionen werden implementiert';

  @override
  String imagesSelected(Object count) {
    return '$count Bild(er) ausgewählt';
  }

  @override
  String get noImagesSelected => 'Keine Bilder ausgewählt';

  @override
  String get errorSelectingImages => 'Fehler beim Auswählen der Bilder';

  @override
  String get propertyUpdatedSuccessfully =>
      'Immobilie erfolgreich aktualisiert!';

  @override
  String get propertyCreatedSuccessfully => 'Immobilie erfolgreich erstellt!';

  @override
  String get deleteService => 'Service löschen';

  @override
  String get serviceDeleted => 'Service gelöscht';

  @override
  String get searchPropertiesLandlordsMessages =>
      'Immobilien, Vermieter, Nachrichten suchen...';

  @override
  String get errorLoadingConversations =>
      'Fehler beim Laden der Unterhaltungen';

  @override
  String get allowViewBasicProfile =>
      'Anderen Benutzern erlauben, Ihre grundlegenden Profilinformationen anzuzeigen';

  @override
  String get letUsersFindsPropertiesInSearch =>
      'Anderen Benutzern erlauben, Ihre Immobilien in Suchergebnissen zu finden';

  @override
  String get shareUsageAnalytics => 'Nutzungsanalytik teilen';

  @override
  String get getUpdatesAboutNewFeatures =>
      'Updates über neue Funktionen, Tipps und Sonderangebote erhalten';

  @override
  String get downloadCopyPersonalData =>
      'Eine Kopie Ihrer persönlichen Daten herunterladen';

  @override
  String get permanentlyDeleteAccount =>
      'Konto und alle Daten dauerhaft löschen';

  @override
  String get dataExportRequestSubmitted =>
      'Datenexport-Anfrage eingereicht. Sie erhalten eine E-Mail mit dem Download-Link.';

  @override
  String get accountDeletionRequestSubmitted =>
      'Kontolöschungs-Anfrage eingereicht. Diese Funktion wird bald verfügbar sein.';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get passwordChangedSuccessfully => 'Passwort erfolgreich geändert';

  @override
  String get failedToChangePassword => 'Passwort konnte nicht geändert werden';

  @override
  String get profileImageUploadComingSoon => 'Profilbild-Upload kommt bald';

  @override
  String get invalidChatParameters => 'Ungültige Chat-Parameter';

  @override
  String get allowOtherUsersViewProfile =>
      'Anderen Benutzern erlauben, Ihre grundlegenden Profilinformationen anzuzeigen';

  @override
  String get letOtherUsersFindProperties =>
      'Anderen Benutzern erlauben, Ihre Immobilien in Suchergebnissen zu finden';

  @override
  String get shareUsageAnalyticsDesc =>
      'Nutzungsanalytik teilen, um die App zu verbessern';

  @override
  String get getUpdatesNewFeatures =>
      'Updates über neue Funktionen, Tipps und Sonderangebote erhalten';

  @override
  String get downloadPersonalData =>
      'Eine Kopie Ihrer persönlichen Daten herunterladen';

  @override
  String get permanentlyDeleteAccountData =>
      'Konto und alle Daten dauerhaft löschen';

  @override
  String get dataExportRequestSubmittedMessage =>
      'Datenexport-Anfrage eingereicht. Sie erhalten eine E-Mail mit dem Download-Link.';

  @override
  String get accountDeletionRequestSubmittedMessage =>
      'Kontolöschungs-Anfrage eingereicht. Diese Funktion wird bald verfügbar sein.';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get pleaseEnterCurrentPassword =>
      'Bitte geben Sie Ihr aktuelles Passwort ein';

  @override
  String get pleaseEnterNewPassword => 'Bitte geben Sie ein neues Passwort ein';

  @override
  String get passwordTooShort => 'Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get currentPasswordIncorrect => 'Aktuelles Passwort ist falsch';

  @override
  String get privacyVisibility => 'Datenschutz & Sichtbarkeit';

  @override
  String get publicProfile => 'Öffentliches Profil';

  @override
  String get searchVisibility => 'Suchsichtbarkeit';

  @override
  String get dataAndAnalytics => 'Daten & Analytik';

  @override
  String get communicationPreferences => 'Kommunikationspräferenzen';

  @override
  String get marketingEmails => 'Marketing-E-Mails';

  @override
  String get dataManagement => 'Datenverwaltung';

  @override
  String get exportMyData => 'Meine Daten exportieren';

  @override
  String get requestDataExport => 'Datenexport anfordern';

  @override
  String get dangerZone => 'Gefahrenzone';

  @override
  String get thisActionCannotBeUndone =>
      'Diese Aktion kann nicht rückgängig gemacht werden.';

  @override
  String get pleaseTypeConfirmToDelete =>
      'Bitte tippen Sie \'BESTÄTIGEN\', um das Konto zu löschen:';

  @override
  String get typeConfirmHere => 'Hier \'BESTÄTIGEN\' eingeben...';

  @override
  String get pleaseTypeConfirm => 'Bitte tippen Sie \'BESTÄTIGEN\'';

  @override
  String get accountDeletion => 'Kontolöschung';

  @override
  String get areYouSureDeleteAccount =>
      'Sind Sie sicher, dass Sie Ihr Konto löschen möchten?';

  @override
  String get thisWillPermanentlyDelete =>
      'Dies wird dauerhaft alle Ihre Daten löschen, einschließlich:';

  @override
  String get allProperties => '• Alle Immobilien';

  @override
  String get allConversations => '• Alle Unterhaltungen';

  @override
  String get allDocuments => '• Alle Dokumente';

  @override
  String get allPaymentHistory => '• Alle Zahlungshistorie';

  @override
  String get profileInformation => '• Profilinformationen';

  @override
  String get requestDeletion => 'Löschung anfordern';

  @override
  String get editProfileInfo => 'Bearbeiten Sie Ihre Profilinformationen';

  @override
  String get firstName => 'Vorname';

  @override
  String get lastName => 'Nachname';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get bio => 'Biografie';

  @override
  String get bioHint => 'Erzählen Sie anderen etwas über sich...';

  @override
  String get pleaseEnterFirstName => 'Bitte geben Sie Ihren Vornamen ein';

  @override
  String get pleaseEnterLastName => 'Bitte geben Sie Ihren Nachnamen ein';

  @override
  String get pleaseEnterValidEmail =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get phoneNumberOptional => 'Telefonnummer (optional)';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get profileUpdated => 'Profil aktualisiert';

  @override
  String get profileUpdatedSuccessfully => 'Profil erfolgreich aktualisiert';

  @override
  String get failedToUpdateProfile => 'Profil konnte nicht aktualisiert werden';

  @override
  String get uploadProfileImage => 'Profilbild hochladen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get chooseFromGallery => 'Aus Galerie wählen';

  @override
  String get removePhoto => 'Foto entfernen';

  @override
  String get tenantSortNameAz => 'Name (A–Z)';

  @override
  String tenantStartingConversation(Object fullName) {
    return 'Unterhaltung mit $fullName wird gestartet...';
  }

  @override
  String tenantNoPhoneAvailable(Object fullName) {
    return 'Keine Telefonnummer für $fullName verfügbar';
  }

  @override
  String tenantCallTitle(Object fullName) {
    return 'Anruf $fullName';
  }

  @override
  String tenantCallConfirmation(Object phone) {
    return 'Möchten Sie $phone anrufen?';
  }

  @override
  String tenantCallError(Object error) {
    return 'Telefonanruf konnte nicht gestartet werden: $error';
  }

  @override
  String get tenantFilterTitle => 'Mieter filtern';

  @override
  String get tenantServicesServiceProviderLabel => 'Dienstleister';

  @override
  String get tenantServicesErrorLoadingProperties =>
      'Fehler beim Laden der Immobilien';

  @override
  String get tenantServicesNoPropertiesTitle => 'Keine zugewiesenen Immobilien';

  @override
  String get tenantServicesNoPropertiesBody =>
      'Sie müssen einer Immobilie zugeordnet sein, um verfügbare Services zu sehen.';

  @override
  String get tenantServicesErrorLoadingServices =>
      'Fehler beim Laden der Services';

  @override
  String get tenantServicesHeaderTitle => 'Verfügbare Services';

  @override
  String get tenantServicesHeaderSubtitle =>
      'Buchen Sie Services, die Ihr Vermieter für Mieter freigegeben hat. Alle Services sind vorab genehmigt und professionell betreut.';

  @override
  String get tenantServicesSearchHint => 'Services durchsuchen...';

  @override
  String get tenantServicesCategoryAll => 'Alle';

  @override
  String get tenantServicesCategoryMaintenance => 'Wartung';

  @override
  String get tenantServicesCategoryCleaning => 'Reinigung';

  @override
  String get tenantServicesCategoryRepair => 'Reparatur';

  @override
  String get tenantServicesCategoryGeneral => 'Allgemein';

  @override
  String get tenantServicesBookServiceButton => 'Service buchen';

  @override
  String get tenantServicesUnavailableLabel => 'Nicht verfügbar';

  @override
  String get tenantServicesNoServicesTitle => 'Keine Services verfügbar';

  @override
  String get tenantServicesNoServicesBody =>
      'Ihr Vermieter hat noch keine Services eingerichtet.';

  @override
  String tenantServicesBookDialogTitle(Object serviceName) {
    return 'Service $serviceName buchen';
  }

  @override
  String tenantServicesServiceLine(Object serviceName) {
    return 'Service: $serviceName';
  }

  @override
  String tenantServicesProviderLine(Object provider) {
    return 'Anbieter: $provider';
  }

  @override
  String tenantServicesPriceLine(Object price) {
    return 'Preis: $price';
  }

  @override
  String get tenantServicesContactInfoLabel => 'Kontaktinformationen:';

  @override
  String get tenantServicesContactInfoUnavailable =>
      'Keine Kontaktinformationen verfügbar';

  @override
  String get tenantServicesContactProviderButton => 'Anbieter kontaktieren';

  @override
  String tenantServicesContactInfoProvided(
      Object provider, Object serviceName) {
    return 'Kontaktinformationen für $serviceName wurden bereitgestellt. Bitte wenden Sie sich direkt an $provider.';
  }

  @override
  String get tenant => 'Mieter';

  @override
  String get profileImageUpload => 'Profilbild-Upload kommt bald';

  @override
  String get profilePicture => 'Profilbild';

  @override
  String get selectProfilePictureSource => 'Quelle für Profilbild auswählen';

  @override
  String get failedToPickImage => 'Bild konnte nicht ausgewählt werden';

  @override
  String get failedToCaptureImage => 'Bild konnte nicht aufgenommen werden';

  @override
  String get profileImageUploaded => 'Profilbild hochgeladen';

  @override
  String get failedToUploadImage => 'Bild konnte nicht hochgeladen werden';

  @override
  String get forgotPasswordTitle => 'Passwort vergessen?';

  @override
  String get forgotPasswordDescription =>
      'Geben Sie Ihre E-Mail-Adresse ein und wir senden Ihnen einen Link zum Zurücksetzen Ihres Passworts.';

  @override
  String get sendResetEmail => 'E-Mail zum Zurücksetzen senden';

  @override
  String get backToLogin => 'Zurück zum Login';

  @override
  String get welcomeBackTitle => 'Willkommen zurück';

  @override
  String get signInToManageYourProperties =>
      'Melden Sie sich an, um Ihre Immobilien zu verwalten.';

  @override
  String get emailAddress => 'E-Mail-Adresse';

  @override
  String get emailRequired => 'E-Mail ist erforderlich';

  @override
  String get enterValidEmail =>
      'Bitte geben Sie eine gültige E-Mail-Adresse ein';

  @override
  String get password => 'Passwort';

  @override
  String get passwordRequired => 'Passwort ist erforderlich';

  @override
  String get passwordMinLength =>
      'Passwort muss mindestens 6 Zeichen lang sein';

  @override
  String get fullName => 'Vollständiger Name';

  @override
  String get fullNameRequired => 'Vollständiger Name ist erforderlich';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signUpTitle => 'Konto erstellen';

  @override
  String get signUpSubtitle => 'Treten Sie ImmoLink noch heute bei.';

  @override
  String get signInWithApple => 'Mit Apple anmelden';

  @override
  String get signInWithGoogle => 'Mit Google anmelden';

  @override
  String get dontHaveAccount => 'Noch kein Konto?';

  @override
  String get createOne => 'Erstellen';

  @override
  String get accountCreatedPleaseSignIn =>
      'Konto erstellt. Bitte melden Sie sich an.';

  @override
  String get alreadyHaveAccount => 'Sie haben bereits ein Konto?';

  @override
  String get signUpFailedCheckDetails =>
      'Registrierung fehlgeschlagen. Bitte prüfen Sie Ihre Angaben.';

  @override
  String get networkErrorCheckConnection =>
      'Netzwerkfehler. Bitte prüfen Sie Ihre Verbindung.';

  @override
  String get signUpFailedTryAgain =>
      'Registrierung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get passwordResetEmailSent =>
      'E-Mail zum Zurücksetzen gesendet! Bitte prüfen Sie Ihren Posteingang.';

  @override
  String get pleaseEnterYourEmail => 'Bitte geben Sie Ihre E-Mail ein';

  @override
  String get searchPropertiesLandlords =>
      'Immobilien, Vermieter, Nachrichten suchen...';

  @override
  String get startTypingToFindResults =>
      'Beginnen Sie zu tippen, um Ergebnisse zu finden';

  @override
  String get tryDifferentSearchTerm =>
      'Versuchen Sie einen anderen Suchbegriff';

  @override
  String get twoFactorAuthentication => 'Zwei-Faktor-Authentifizierung';

  @override
  String get privacySettingsTitle => 'Datenschutzeinstellungen';

  @override
  String get privacySettingsIntro =>
      'Bestimmen Sie, wer Ihre Profilinformationen sehen kann und wie Sie anderen Benutzern angezeigt werden.';

  @override
  String get privacyProfileVisibilityTitle => 'Profil anderen Benutzern zeigen';

  @override
  String get privacyProfileVisibilityDescription =>
      'Erlaubt anderen Benutzern, mit denen Sie interagieren, Ihre Profildaten zu sehen.';

  @override
  String get privacyContactInfoTitle => 'Kontaktinformationen anzeigen';

  @override
  String get privacyContactInfoDescription =>
      'E-Mail und Telefonnummer für verbundene Benutzer anzeigen';

  @override
  String get privacyDataSharingSectionTitle => 'Datennutzung';

  @override
  String get privacyDataSharingDescription =>
      'Legen Sie fest, wie Ihre Daten zur Verbesserung von ImmoLink verwendet werden.';

  @override
  String get privacyAllowPropertySearchTitle => 'Immobiliensuche erlauben';

  @override
  String get privacyAllowPropertySearchDescription =>
      'Ermöglicht anderen Benutzern, Ihre Immobilien in Suchergebnissen zu finden';

  @override
  String get privacyUsageAnalyticsTitle => 'Nutzungsanalysen teilen';

  @override
  String get privacyUsageAnalyticsDescription =>
      'Helfen Sie mit, ImmoLink zu verbessern, indem Sie anonyme Nutzungsdaten teilen';

  @override
  String get privacyMarketingSectionTitle => 'Marketing & Kommunikation';

  @override
  String get privacyMarketingDescription =>
      'Steuern Sie, wie wir Sie über neue Funktionen und Angebote informieren.';

  @override
  String get privacyMarketingEmailsTitle => 'Marketing-E-Mails erhalten';

  @override
  String get privacyMarketingEmailsDescription =>
      'Updates zu neuen Funktionen, Tipps und Angeboten erhalten';

  @override
  String get privacyDataManagementSectionTitle => 'Datenverwaltung';

  @override
  String get privacyDataManagementDescription =>
      'Verwalten Sie Ihre personenbezogenen Daten und exportieren Sie Ihre Informationen.';

  @override
  String get privacyExportDataTitle => 'Meine Daten exportieren';

  @override
  String get privacyExportDataSubtitle =>
      'Laden Sie eine Kopie Ihrer persönlichen Daten herunter';

  @override
  String get privacyDeleteAccountTitle => 'Konto löschen';

  @override
  String get privacyDeleteAccountSubtitle =>
      'Ihr Konto und alle Daten dauerhaft löschen';

  @override
  String get privacyExportDialogTitle => 'Daten exportieren';

  @override
  String get privacyExportDialogDescription =>
      'Wir erstellen einen Download-Link mit allen Ihren persönlichen Daten, einschließlich:';

  @override
  String get privacyExportIncludesProfile => 'Profilinformationen';

  @override
  String get privacyExportIncludesProperty => 'Immobiliendaten';

  @override
  String get privacyExportIncludesMessages => 'Nachrichten und Unterhaltungen';

  @override
  String get privacyExportIncludesPayments => 'Zahlungshistorie';

  @override
  String get privacyExportIncludesSettings => 'Einstellungen und Präferenzen';

  @override
  String get privacyExportDialogNote =>
      'Der Export kann bis zu 24 Stunden dauern. Sie erhalten einen E-Mail-Link zum Download.';

  @override
  String get privacyExportSuccess =>
      'Datenexport angefordert. Sie erhalten bald einen Download-Link per E-Mail.';

  @override
  String get privacyExportButton => 'Export anfordern';

  @override
  String get privacyDeleteDialogTitle => 'Konto löschen';

  @override
  String get privacyDeleteDialogQuestion =>
      'Sind Sie sicher, dass Sie Ihr Konto löschen möchten?';

  @override
  String get privacyDeleteDialogWarningTitle =>
      'Folgende Daten werden dauerhaft gelöscht:';

  @override
  String get privacyDeleteDialogDeleteProfile =>
      'Ihr Profil und alle persönlichen Daten';

  @override
  String get privacyDeleteDialogDeleteProperties =>
      'Alle Immobilien und Immobiliendaten';

  @override
  String get privacyDeleteDialogDeleteMessages =>
      'Nachrichten und Unterhaltungen';

  @override
  String get privacyDeleteDialogDeletePayments => 'Zahlungshistorie';

  @override
  String get privacyDeleteDialogDeleteDocuments =>
      'Alle hochgeladenen Dokumente und Bilder';

  @override
  String get privacyDeleteDialogIrreversible =>
      'Diese Aktion kann nicht rückgängig gemacht werden. Exportieren Sie Ihre Daten, wenn Sie eine Kopie behalten möchten.';

  @override
  String get privacyDeleteRequestSubmitted =>
      'Antrag zum Löschen des Kontos eingereicht. Diese Funktion wird bald verfügbar sein.';

  @override
  String get privacyDeleteButton => 'Konto löschen';

  @override
  String get changePasswordPageTitle => 'Passwort ändern';

  @override
  String get changePasswordSubtitle =>
      'Geben Sie Ihr aktuelles Passwort ein und wählen Sie ein neues';

  @override
  String get changePasswordCurrentLabel => 'Aktuelles Passwort';

  @override
  String get changePasswordCurrentRequired =>
      'Bitte aktuelles Passwort eingeben';

  @override
  String get changePasswordNewLabel => 'Neues Passwort';

  @override
  String get changePasswordNewRequired => 'Bitte ein neues Passwort eingeben';

  @override
  String get changePasswordNewLength =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get changePasswordNewComplexity =>
      'Das Passwort muss Groß-, Kleinbuchstaben und Zahlen enthalten';

  @override
  String get changePasswordConfirmRequired => 'Bitte neues Passwort bestätigen';

  @override
  String get changePasswordConfirmMismatch =>
      'Passwörter stimmen nicht überein';

  @override
  String get passwordRequirementsTitle => 'Passwortrichtlinien';

  @override
  String get passwordRequirementLength => 'Mindestens 8 Zeichen lang';

  @override
  String get passwordRequirementUppercase => 'Enthält Großbuchstaben (A-Z)';

  @override
  String get passwordRequirementLowercase => 'Enthält Kleinbuchstaben (a-z)';

  @override
  String get passwordRequirementNumbers => 'Enthält Zahlen (0-9)';

  @override
  String get changePasswordButton => 'Passwort ändern';

  @override
  String get removeTenant => 'Mieter entfernen';

  @override
  String get removeTenantConfirmation =>
      'Sind Sie sicher, dass Sie diesen Mieter von der Immobilie entfernen möchten?';

  @override
  String get tenantRemovedSuccessfully => 'Mieter erfolgreich entfernt';

  @override
  String get failedToRemoveTenant => 'Fehler beim Entfernen des Mieters';

  @override
  String get invitations => 'Einladungen';

  @override
  String get subscriptionPageTitle => 'Abonnement';

  @override
  String get subscriptionLoginPrompt => 'Bitte melden Sie sich an';

  @override
  String get subscriptionNoActiveTitle => 'Kein aktives Abonnement';

  @override
  String get subscriptionNoActiveDescription =>
      'Sie haben derzeit kein aktives Abonnement.';

  @override
  String get subscriptionViewPlansButton => 'Pläne anzeigen';

  @override
  String get subscriptionStatusActive => 'Abonnement aktiv';

  @override
  String subscriptionStatusValue(Object status) {
    return 'Abonnement $status';
  }

  @override
  String get subscriptionPlanLabel => 'Tarif';

  @override
  String get subscriptionAmountLabel => 'Betrag';

  @override
  String get subscriptionBillingLabel => 'Abrechnung';

  @override
  String get subscriptionBillingMonthly => 'Monatlich';

  @override
  String get subscriptionBillingYearly => 'Jährlich';

  @override
  String get subscriptionNextBillingLabel => 'Nächste Abrechnung';

  @override
  String get subscriptionDetailsTitle => 'Abonnementdetails';

  @override
  String get subscriptionIdLabel => 'Abonnement-ID';

  @override
  String get subscriptionCustomerIdLabel => 'Kunden-ID';

  @override
  String get subscriptionCustomerIdUnavailable => 'N/V';

  @override
  String get subscriptionStartedLabel => 'Gestartet';

  @override
  String get subscriptionEndsLabel => 'Endet';

  @override
  String get subscriptionManageButton => 'Abonnement verwalten';

  @override
  String get subscriptionCancelButton => 'Abonnement kündigen';

  @override
  String get subscriptionErrorLoading => 'Fehler beim Laden des Abonnements';

  @override
  String get subscriptionNoCustomerIdMessage => 'Keine Kunden-ID gefunden';

  @override
  String get subscriptionOpeningPortal => 'Stripe-Portal wird geöffnet...';

  @override
  String subscriptionFailedToOpenPortal(Object error) {
    return 'Portal konnte nicht geöffnet werden: $error';
  }

  @override
  String get subscriptionCancelDialogTitle => 'Abonnement kündigen?';

  @override
  String get subscriptionCancelDialogBody =>
      'Sind Sie sicher, dass Sie Ihr Abonnement kündigen möchten? Sie verlieren am Ende des aktuellen Abrechnungszeitraums den Zugriff auf Premium-Funktionen.';

  @override
  String get subscriptionKeepButton => 'Abonnement behalten';

  @override
  String get subscriptionCancelledMessage => 'Abonnement gekündigt';

  @override
  String subscriptionCancelErrorMessage(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get analyticsAndReports => 'Analysen & Berichte';

  @override
  String get exportReportsTitle => 'Berichte exportieren';

  @override
  String get exportFormatPrompt => 'Exportformat wählen';

  @override
  String get exportPdf => 'PDF exportieren';

  @override
  String get generatingPdfReport => 'PDF-Bericht wird erstellt...';

  @override
  String get pdfExportInfo =>
      'PDF-Exportfunktion wird mit dem pdf-Paket implementiert';

  @override
  String get propertyOverview => 'Immobilienübersicht';

  @override
  String get financialOverview => 'Finanzübersicht';

  @override
  String get maintenanceOverview => 'Wartungsübersicht';

  @override
  String get recentPayments => 'Letzte Zahlungen';

  @override
  String get paymentDashboard => 'Zahlungsübersicht';

  @override
  String get stripeAccountActive => 'Konto aktiv';

  @override
  String get stripeSetupRequired => 'Einrichtung erforderlich';

  @override
  String get stripeAcceptPayments => 'Zahlungen akzeptieren';

  @override
  String get stripeReceivePayouts => 'Auszahlungen erhalten';

  @override
  String get stripeSetUpPaymentAccountTitle => 'Zahlungskonto einrichten';

  @override
  String get stripeSetUpPaymentAccountDescription =>
      'Verbinden Sie Ihr Bankkonto, um Zahlungen von Mietern zu erhalten';

  @override
  String get startSetup => 'Einrichtung starten';

  @override
  String get loadingAccountSetup => 'Kontoeinrichtung wird geladen...';

  @override
  String get unableToLoadEmbeddedSetup =>
      'Eingebettete Einrichtung konnte nicht geladen werden';

  @override
  String get stripeOnboardingComponentWillAppearHere =>
      'Die Stripe-Onboarding-Komponente wird hier angezeigt';

  @override
  String get errorLoadingDashboard => 'Fehler beim Laden des Dashboards';

  @override
  String get stripeDashboardPaymentManagementTitle => 'Zahlungsverwaltung';

  @override
  String get stripeDashboardPayoutsAndBalanceTitle => 'Auszahlungen & Guthaben';

  @override
  String get stripeDashboardComponentWillAppearHere =>
      'Die Stripe-Dashboard-Komponente wird hier angezeigt';

  @override
  String get accountBalance => 'Kontostand';

  @override
  String get errorLoadingBalance => 'Fehler beim Laden des Kontostands';

  @override
  String get openingStripeConnectSetup =>
      'Stripe Connect-Einrichtung wird geöffnet...';

  @override
  String get couldNotOpenBrowser => 'Browser konnte nicht geöffnet werden';

  @override
  String get failedToCreateStripeAccount =>
      'Stripe-Konto konnte nicht erstellt werden. Bitte prüfen Sie Ihre Internetverbindung und versuchen Sie es erneut.';

  @override
  String get failedToCreateOnboardingLink =>
      'Onboarding-Link konnte nicht erstellt werden. Bitte versuchen Sie es erneut.';

  @override
  String get setupFailedTryAgain =>
      'Einrichtung fehlgeschlagen. Bitte versuchen Sie es erneut.';

  @override
  String get requestTimeoutTryAgain =>
      'Zeitüberschreitung der Anfrage. Bitte versuchen Sie es erneut.';

  @override
  String get serviceNotAvailableContactSupport =>
      'Dienst nicht verfügbar. Bitte kontaktieren Sie den Support.';

  @override
  String get requestPayout => 'Auszahlung anfordern';

  @override
  String get transferAvailableBalanceToBankQuestion =>
      'Ihr verfügbares Guthaben auf Ihr Bankkonto überweisen?';

  @override
  String get arrival => 'Ankunft';

  @override
  String get payoutArrivalEstimate => '2–3 Werktage';

  @override
  String payoutRequestedWithAmount(Object amount) {
    return 'Auszahlung angefordert: $amount';
  }

  @override
  String get failedToCreatePayout => 'Auszahlung konnte nicht erstellt werden';

  @override
  String get balanceInformation => 'Informationen zum Kontostand';

  @override
  String get availableFundsDescription =>
      'Guthaben, das zur Überweisung auf Ihr Bankkonto bereit ist';

  @override
  String get pendingFundsDescription =>
      'Guthaben, das noch freigegeben werden muss (in der Regel 2–3 Tage)';

  @override
  String errorWithDetails(Object error) {
    return 'Fehler: $error';
  }

  @override
  String get noPaymentsFound => 'Keine Zahlungen gefunden';

  @override
  String get collected => 'Eingezogen';

  @override
  String get totalPaid => 'Gesamt bezahlt';

  @override
  String get totalPayments => 'Gesamtzahlungen';

  @override
  String get totalRequests => 'Gesamtanfragen';

  @override
  String get revenueAnalytics => 'Umsatzanalysen';

  @override
  String get revenueChartComingSoon => 'Umsatzdiagramm folgt';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Diesen Monat';

  @override
  String get thisQuarter => 'Dieses Quartal';

  @override
  String get thisYear => 'Dieses Jahr';

  @override
  String get reportPeriod => 'Berichtszeitraum';

  @override
  String get financialSummary => 'Finanzübersicht';

  @override
  String get totalIncome => 'Gesamte Einnahmen';

  @override
  String get paymentSummary => 'Zahlungsübersicht';

  @override
  String get dashboardComponentsRequireBrowser =>
      'Dashboard-Komponenten erfordern einen Webbrowser';

  @override
  String get dashboardAvailableOnWeb => 'Dashboard im Web verfügbar';

  @override
  String visitWebForFullDashboard(Object component) {
    return 'Besuchen Sie die Webversion, um das vollständige $component-Dashboard zu nutzen';
  }

  @override
  String get planBasic => 'Basic';

  @override
  String get planProfessional => 'Professional';

  @override
  String get planEnterprise => 'Enterprise';

  @override
  String get planBasicDescription => 'Perfekt für einzelne Vermieter';

  @override
  String get planProfessionalDescription =>
      'Ideal für wachsende Immobilienportfolios';

  @override
  String get planEnterpriseDescription =>
      'Für große Immobilienverwaltungsunternehmen';

  @override
  String get featureUpToThreeProperties => 'Bis zu 3 Immobilien';

  @override
  String get featureBasicTenantManagement => 'Basis-Mieterverwaltung';

  @override
  String get featurePaymentTracking => 'Zahlungsverfolgung';

  @override
  String get featureEmailSupport => 'E-Mail-Support';

  @override
  String get featureUpToFifteenProperties => 'Bis zu 15 Immobilien';

  @override
  String get featureAdvancedTenantManagement => 'Erweiterte Mieterverwaltung';

  @override
  String get featureAutomatedRentCollection => 'Automatisierte Mietinkasso';

  @override
  String get featureMaintenanceRequestTracking =>
      'Verfolgung von Wartungsanfragen';

  @override
  String get featureFinancialReports => 'Finanzberichte';

  @override
  String get featurePrioritySupport => 'Priorisierter Support';

  @override
  String get featureUnlimitedProperties => 'Unbegrenzte Immobilien';

  @override
  String get featureMultiUserAccounts => 'Mehrbenutzerkonten';

  @override
  String get featureAdvancedAnalytics => 'Erweiterte Analysen';

  @override
  String get featureApiAccess => 'API-Zugriff';

  @override
  String get featureCustomIntegrations => 'Individuelle Integrationen';

  @override
  String get featureDedicatedSupport => 'Dedizierter Support';

  @override
  String documentDownloadedTo(Object path) {
    return 'Dokument gespeichert unter: $path';
  }

  @override
  String get openFolder => 'Ordner öffnen';

  @override
  String get downloadFailed => 'Download fehlgeschlagen';

  @override
  String get failedToOpen => 'Öffnen fehlgeschlagen';

  @override
  String get openInExternalApp => 'In externer App öffnen';

  @override
  String get loadingDocument => 'Dokument wird geladen...';

  @override
  String get unableToLoadDocument => 'Dokument konnte nicht geladen werden';

  @override
  String get downloadInstead => 'Stattdessen herunterladen';

  @override
  String get viewImage => 'Bild anzeigen';

  @override
  String get loadPreview => 'Vorschau laden';

  @override
  String get downloadToDevice => 'Auf Gerät herunterladen';

  @override
  String get failedToDisplayImage => 'Bild konnte nicht angezeigt werden';

  @override
  String get pdfDocument => 'PDF-Dokument';

  @override
  String get imageFile => 'Bilddatei';

  @override
  String get textFile => 'Textdatei';

  @override
  String get wordDocument => 'Word-Dokument';

  @override
  String get excelSpreadsheet => 'Excel-Tabelle';

  @override
  String get powerPointPresentation => 'PowerPoint-Präsentation';

  @override
  String get documentFile => 'Dokumentdatei';

  @override
  String get expiringSoon => 'Läuft bald ab';

  @override
  String get expired => 'Abgelaufen';

  @override
  String expiresOn(Object date) {
    return 'Läuft ab $date';
  }

  @override
  String tenantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mieter',
      one: 'Mieter',
    );
    return '$count $_temp0';
  }

  @override
  String propertiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Immobilien',
      one: 'Immobilie',
    );
    return '$count $_temp0';
  }

  @override
  String daysAgo(Object days) {
    return '${days}T her';
  }

  @override
  String weeksAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vor $count Wochen',
      one: 'Vor 1 Woche',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionRequired => 'Abonnement erforderlich';

  @override
  String get subscriptionRequiredMessage =>
      'Diese Funktion ist mit einem Abonnement verfügbar.';

  @override
  String get subscriptionChoosePlanMessage =>
      'Wählen Sie einen Plan, um alle Funktionen freizuschalten.';

  @override
  String get viewPlans => 'Pläne ansehen';

  @override
  String get total => 'Summe';

  @override
  String get viewAllProperties => 'Alle Objekte anzeigen';

  @override
  String get noRecentMessages => 'Keine aktuellen Nachrichten';

  @override
  String get noPendingMaintenanceRequests => 'Keine offenen Wartungsanfragen';

  @override
  String get errorLoadingMaintenanceRequest =>
      'Fehler beim Laden der Wartungsanfrage';

  @override
  String get goBack => 'Zurück';

  @override
  String get contractorInformation => 'Handwerker Informationen';

  @override
  String get contact => 'Kontakt';

  @override
  String get company => 'Unternehmen';

  @override
  String get notes => 'Notizen';

  @override
  String get reported => 'Gemeldet';

  @override
  String get loadingAddress => 'Adresse wird geladen...';

  @override
  String get propertyIdLabel => 'Objekt-ID';

  @override
  String get urgency => 'Dringlichkeit';

  @override
  String get scheduled => 'Geplant';

  @override
  String get estimated => 'Geschätzt';

  @override
  String get actualCost => 'Tatsächliche Kosten';

  @override
  String get markAsInProgress => 'Als in Arbeit markieren';

  @override
  String get markAsCompleted => 'Als abgeschlossen markieren';

  @override
  String get enterNoteHint => 'Notiz eingeben...';

  @override
  String get addingNote => 'Füge Notiz hinzu...';

  @override
  String get completePayment => 'Zahlung abschließen';

  @override
  String get perYearSuffix => 'pro Jahr';

  @override
  String get perMonthSuffix => 'pro Monat';

  @override
  String youSavePerYear(Object savings) {
    return 'Sie sparen $savings pro Jahr';
  }

  @override
  String get includedFeatures => 'Enthaltene Funktionen';

  @override
  String get paymentMethod => 'Zahlungsmethode';

  @override
  String get paymentDetailsTitle => 'Zahlungsdetails';

  @override
  String get autoPaymentSetupTitle => 'Automatische Zahlung einrichten';

  @override
  String get automaticPayments => 'Automatische Zahlungen';

  @override
  String get neverMissRentPayment => 'Verpasse nie eine Mietzahlung';

  @override
  String get encryptedSecurePaymentProcessing =>
      'Verschlüsselte und sichere Zahlungsabwicklung';

  @override
  String get bankAccount => 'Bankkonto';

  @override
  String get achTransfer => 'Banküberweisung (ACH)';

  @override
  String get instantPayment => 'Sofortzahlung';

  @override
  String get bankAccountInformation => 'Bankkontoinformationen';

  @override
  String get accountNumber => 'Kontonummer';

  @override
  String get enterBankAccountNumber => 'Gib deine Kontonummer ein';

  @override
  String get accountNumberIsRequired => 'Kontonummer ist erforderlich';

  @override
  String get routingNumber => 'Routing-Nummer';

  @override
  String get enterBankRoutingNumber => 'Gib deine Bank-Routing-Nummer ein';

  @override
  String get routingNumberIsRequired => 'Routing-Nummer ist erforderlich';

  @override
  String get cardInformation => 'Karteninformationen';

  @override
  String get cardholderName => 'Name des Karteninhabers';

  @override
  String get enterNameOnCard => 'Name auf der Karte eingeben';

  @override
  String get cardholderNameIsRequired =>
      'Name des Karteninhabers ist erforderlich';

  @override
  String get cardNumber => 'Kartennummer';

  @override
  String get cardNumberIsRequired => 'Kartennummer ist erforderlich';

  @override
  String get expiryDate => 'Ablaufdatum';

  @override
  String get expiryDateIsRequired => 'Ablaufdatum ist erforderlich';

  @override
  String get cvv => 'CVV';

  @override
  String get cvvIsRequired => 'CVV ist erforderlich';

  @override
  String get setUpAutoPayment => 'Automatische Zahlung einrichten';

  @override
  String get secureAndEncrypted => 'Sicher & verschlüsselt';

  @override
  String get autoPaymentSecurityDescription =>
      'Deine Zahlungsinformationen werden mit Sicherheit auf Bankniveau verschlüsselt. Du kannst automatische Zahlungen jederzeit ändern oder kündigen.';

  @override
  String get setupCompleteTitle => 'Einrichtung abgeschlossen';

  @override
  String get setupCompleteMessage =>
      'Deine automatische Zahlung wurde erfolgreich mit Stripe eingerichtet. Du erhältst in Kürze eine Bestätigungs-E-Mail.';

  @override
  String get done => 'Fertig';

  @override
  String get unableToSetupPaymentNoPropertyInfo =>
      'Zahlung kann nicht eingerichtet werden: Keine Objekt- oder Vermieterinformationen gefunden.';

  @override
  String get setupFailedTitle => 'Einrichtung fehlgeschlagen';

  @override
  String setupFailedWithError(Object error) {
    return 'Einrichtung fehlgeschlagen: $error';
  }

  @override
  String get makePayment => 'Zahlung ausführen';

  @override
  String get submitPayment => 'Zahlung senden';

  @override
  String get paymentType => 'Zahlungsart';

  @override
  String get enterAmount => 'Betrag eingeben';

  @override
  String get pleaseEnterAmount => 'Bitte einen Betrag eingeben';

  @override
  String get pleaseEnterValidNumber => 'Bitte eine gültige Zahl eingeben';

  @override
  String get amountMustBeGreaterThanZero => 'Der Betrag muss größer als 0 sein';

  @override
  String get notesOptional => 'Notizen (optional)';

  @override
  String get addAdditionalNotes => 'Zusätzliche Notizen hinzufügen...';

  @override
  String get processingPayment => 'Zahlung wird verarbeitet...';

  @override
  String get userNotAuthenticated => 'Benutzer nicht authentifiziert';

  @override
  String get paymentSubmittedSuccessfully => 'Zahlung erfolgreich gesendet';

  @override
  String failedToSubmitPayment(Object error) {
    return 'Zahlung konnte nicht gesendet werden: $error';
  }

  @override
  String get noPropertiesToMakePaymentsFor =>
      'Du hast keine Objekte, für die du Zahlungen tätigen kannst.';

  @override
  String outstandingPaymentsWithAmount(Object amount) {
    return 'Offene Zahlungen: $amount';
  }

  @override
  String get bankTransfer => 'Banküberweisung';

  @override
  String get paypal => 'PayPal';

  @override
  String get payNow => 'Jetzt bezahlen';

  @override
  String get recordPayment => 'Zahlung erfassen';

  @override
  String get viewPayments => 'Zahlungen ansehen';

  @override
  String get paymentProcessedSecurelyByStripe =>
      'Ihre Zahlung wird sicher über Stripe verarbeitet';

  @override
  String get bankTransferInstructionsTitle => 'Anweisungen für Banküberweisung';

  @override
  String get bankTransferInstructionsDescription =>
      'Überweisen Sie den Betrag auf das folgende Konto und geben Sie Ihre Zahlungsreferenz an:';

  @override
  String get bankTransferInstructionsAccountDetails =>
      'Konto: ImmoLink Payments\nIBAN: CH12 3456 7890 1234 5678\nReferenz: Ihre Objekt-ID';

  @override
  String get paymentProcessedSuccessfully =>
      'Ihre Zahlung wurde erfolgreich verarbeitet.';

  @override
  String get paymentRecordedCompleteBankTransfer =>
      'Ihre Zahlung wurde erfasst. Bitte führen Sie die Banküberweisung mit den angegebenen Details aus.';

  @override
  String get utilities => 'Nebenkosten';

  @override
  String get maintenanceFee => 'Wartungsgebühr';

  @override
  String get lateFee => 'Verspätungsgebühr';

  @override
  String paymentTypeLabel(Object type) {
    return '$type-Zahlung';
  }

  @override
  String payPaymentTypeTitle(Object type) {
    return 'Zahle $type';
  }

  @override
  String get processingFee => 'Bearbeitungsgebühr';

  @override
  String get instant => 'Sofort';

  @override
  String payAmount(Object amount) {
    return 'Zahle $amount';
  }

  @override
  String get noPaymentMethodsLoaded =>
      'Keine Zahlungsmethoden verfügbar. Prüfen Sie Ihre Netzwerk-/API-Konfiguration.';

  @override
  String get paymentInitiated =>
      'Zahlung initiiert! Sie wird innerhalb von 1–3 Werktagen verarbeitet.';

  @override
  String get paymentCompletedSuccessfully =>
      'Zahlung erfolgreich abgeschlossen!';

  @override
  String get paymentSuccessful => 'Zahlung erfolgreich!';

  @override
  String get creditDebitCard => 'Kredit-/Debitkarte';

  @override
  String get standardCardPayment => 'Standard-Kartenzahlung';

  @override
  String get paymentInfoSecure => 'Ihre Zahlungsinformationen sind sicher';

  @override
  String get desktopPaymentNotSupported => 'Desktop-Zahlung nicht unterstützt';

  @override
  String get desktopPaymentUseWebOrMobile =>
      'Bitte nutzen Sie Web oder mobile App für die Zahlung.';

  @override
  String get openWebVersion => 'Webversion öffnen';

  @override
  String get redirectingToSecurePaymentPage =>
      'Weiterleitung zur sicheren Zahlungsseite...';

  @override
  String get subscriptionTerms => 'Abonnementbedingungen';

  @override
  String subscriptionBulletAutoRenews(Object interval) {
    return 'Verlängert sich automatisch jedes $interval';
  }

  @override
  String get yearlyInterval => 'Jahr';

  @override
  String get monthlyInterval => 'Monat';

  @override
  String get subscriptionBulletCancelAnytime => 'Jederzeit kündbar';

  @override
  String get subscriptionBulletRefundPolicy =>
      'Nicht erstattbar nach Beginn des Abrechnungszeitraums';

  @override
  String get subscriptionBulletAgreeTerms =>
      'Mit dem Abonnement stimmen Sie unseren Bedingungen zu';

  @override
  String get subscribeNow => 'Jetzt abonnieren';

  @override
  String get continueOnWeb => 'Im Web fortfahren';

  @override
  String paymentFailed(Object error) {
    return 'Zahlung fehlgeschlagen: $error';
  }

  @override
  String subscriptionActivated(Object planName) {
    return 'Ihr $planName Abonnement ist aktiv!';
  }

  @override
  String get getStarted => 'Loslegen';

  @override
  String get subscription => 'Abonnement';

  @override
  String get manageSubscriptionTitle => 'Abonnement verwalten';

  @override
  String get chooseYourPlanTitle => 'Wählen Sie Ihren Plan';

  @override
  String get subscriptionLoadError =>
      'Abonnementdaten konnten nicht geladen werden';

  @override
  String get upgradeUnlockFeaturesMessage =>
      'Upgrade für mehr Funktionen und Immobilienlimits';

  @override
  String get selectPlanIntro =>
      'Wählen Sie den perfekten Plan für Ihre Immobilienverwaltung';

  @override
  String get highestPlanTitle => 'Sie sind auf dem höchsten Plan!';

  @override
  String get highestPlanDescription =>
      'Sie haben Zugriff auf alle Premium-Funktionen und unbegrenzte Immobilienverwaltung.';

  @override
  String get premiumThanksMessage => 'Danke, dass Sie Premium-Abonnent sind!';

  @override
  String get billingMonthly => 'Monatlich';

  @override
  String get billingYearly => 'Jährlich';

  @override
  String savePercent(Object percent) {
    return 'Sparen Sie $percent%';
  }

  @override
  String get currentPlanLabel => 'Aktueller Plan';

  @override
  String get statusLabel => 'Status';

  @override
  String get nextBillingLabel => 'Nächste Abrechnung';

  @override
  String get popularBadge => 'Beliebt';

  @override
  String get upgradeBadge => 'Upgrade';

  @override
  String get upgradePlanButton => 'Plan upgraden';

  @override
  String get continueToPayment => 'Weiter zur Zahlung';

  @override
  String get yourProperty => 'Ihre Immobilie';

  @override
  String get recentActivity => 'Letzte Aktivitäten';

  @override
  String get statusActiveUpper => 'AKTIV';

  @override
  String get myDocuments => 'Meine Dokumente';

  @override
  String welcomeUser(Object userName) {
    return 'Willkommen, $userName';
  }

  @override
  String get tenantDocumentsIntro =>
      'Verwalten Sie hier alle Ihre Mietdokumente, Verträge und wichtigen Unterlagen.';

  @override
  String get documentCategories => 'Dokumentenkategorien';

  @override
  String get leaseAgreement => 'Mietvertrag';

  @override
  String get leaseAgreementSubtitle => 'Ihr aktueller Mietvertrag';

  @override
  String get operatingCosts => 'Nebenkosten';

  @override
  String get operatingCostsSubtitle => 'Abrechnungen und Belege';

  @override
  String get protocols => 'Protokolle';

  @override
  String get protocolsSubtitle => 'Übergabe- und Abnahmeprotokolle';

  @override
  String get correspondence => 'Korrespondenz';

  @override
  String get correspondenceSubtitle => 'E-Mails und Briefe';

  @override
  String documentsCount(Object count, Object pluralSuffix) {
    return '$count Dokument$pluralSuffix';
  }

  @override
  String get enterSearchTerm => 'Geben Sie einen Suchbegriff ein';

  @override
  String get noDocumentsFound => 'Keine Dokumente gefunden';

  @override
  String get documentSearch => 'Dokumentensuche';

  @override
  String get useDocumentsTabForDetailedSearch =>
      'Verwenden Sie die Dokumente-Registerkarte für eine detaillierte Suche';

  @override
  String get recentDocuments => 'Aktuelle Dokumente';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get more => 'Mehr';

  @override
  String get noRecentDocuments => 'Keine aktuellen Dokumente';

  @override
  String get allDocumentsHeader => 'Alle Dokumente';

  @override
  String get noDocumentsAvailable => 'Keine Dokumente verfügbar';

  @override
  String get documentsSharedByLandlord =>
      'Vom Vermieter geteilte Dokumente erscheinen hier';

  @override
  String get loadingDocuments => 'Dokumente werden geladen...';

  @override
  String get errorLoadingDocuments => 'Fehler beim Laden der Dokumente';

  @override
  String get pleaseLoginToUploadDocuments =>
      'Bitte melden Sie sich an, um Dokumente hochzuladen';

  @override
  String downloadingDocument(Object name) {
    return 'Lade $name herunter...';
  }

  @override
  String documentDownloadedSuccessfully(Object name) {
    return '$name erfolgreich heruntergeladen';
  }

  @override
  String failedToDownloadDocument(Object name) {
    return 'Fehler beim Herunterladen von $name';
  }

  @override
  String documentUploadedSuccessfully(Object name) {
    return 'Dokument \"$name\" erfolgreich hochgeladen';
  }

  @override
  String failedToUploadDocument(Object error) {
    return 'Fehler beim Hochladen des Dokuments: $error';
  }

  @override
  String get featureComingSoonTitle => 'Bald verfügbar';

  @override
  String get featureComingSoonMessage =>
      'Diese Funktion wird in einem zukünftigen Update verfügbar sein.';

  @override
  String get ok => 'OK';

  @override
  String get expiring => 'Läuft bald ab';

  @override
  String get uploadDocument => 'Dokument hochladen';

  @override
  String get noSpecificProperty => 'Keine spezifische Immobilie';

  @override
  String failedToUploadDocumentGeneric(Object error) {
    return 'Fehler beim Hochladen des Dokuments: $error';
  }

  @override
  String documentsStorageSubtitle(Object count, Object size) {
    return '$count Dateien • $size verwendet';
  }

  @override
  String get uploadNew => 'Neu hochladen';

  @override
  String get recentFiles => 'Letzte Dateien';

  @override
  String get insurance => 'Versicherung';

  @override
  String get inspectionReports => 'Inspektionsberichte';

  @override
  String get legalDocuments => 'Rechtliche Dokumente';

  @override
  String get otherCategory => 'Sonstige';

  @override
  String get documentManagement => 'Dokumentenverwaltung';

  @override
  String welcomeBack(Object name) {
    return 'Willkommen zurück, $name';
  }

  @override
  String get quickUpload => 'Schnell-Upload';

  @override
  String get notice => 'Mitteilung';

  @override
  String get receipt => 'Beleg';

  @override
  String get filterDocuments => 'Dokumente filtern';

  @override
  String get loadingProperties => 'Lade Objekte...';

  @override
  String get documentLibrary => 'Dokumentbibliothek';

  @override
  String get uploadFirstDocument =>
      'Laden Sie Ihr erstes Dokument hoch, um zu beginnen';

  @override
  String get fileLabel => 'Datei';

  @override
  String get selectFile => 'Datei auswählen';

  @override
  String get sizeLabel => 'Größe';

  @override
  String get recentLabel => 'Neueste';

  @override
  String get importantLabel => 'Wichtig';

  @override
  String get documentName => 'Dokumentname';

  @override
  String get descriptionOptional => 'Beschreibung (optional)';

  @override
  String errorPickingFile(Object error) {
    return 'Fehler beim Auswählen der Datei: $error';
  }

  @override
  String get pleaseSelectFile => 'Bitte wählen Sie eine Datei aus';

  @override
  String get pleaseEnterName => 'Bitte geben Sie einen Namen ein';

  @override
  String get assignToPropertyOptional => 'Objekt zuweisen (optional)';

  @override
  String get areYouSure => 'Sind Sie sicher?';

  @override
  String documentDeletedSuccessfully(Object name) {
    return 'Dokument \"$name\" erfolgreich gelöscht';
  }

  @override
  String failedToDeleteDocument(Object error) {
    return 'Dokument konnte nicht gelöscht werden: $error';
  }

  @override
  String get noAppToOpenFile => 'Keine App zum Öffnen dieser Datei gefunden';

  @override
  String get subscriptionStatus => 'Status';

  @override
  String get subscriptionMonthlyAmount => 'Monatlicher Betrag';

  @override
  String get subscriptionYearlyCost => 'Jährliche Kosten';

  @override
  String get subscriptionMonthlyCost => 'Monatliche Kosten';

  @override
  String get subscriptionNextBilling => 'Nächste Abrechnung';

  @override
  String get subscriptionBillingInterval => 'Abrechnungsintervall';

  @override
  String get subscriptionMySubscription => 'Mein Abonnement';

  @override
  String get subscriptionActive => 'Aktiv';

  @override
  String get subscriptionPastDue => 'Zahlungsrückstand';

  @override
  String get subscriptionCanceled => 'Gekündigt';

  @override
  String get subscriptionPaymentDue => 'Zahlung fällig!';

  @override
  String get subscriptionNextPayment => 'Nächste Zahlung';

  @override
  String subscriptionInDays(Object days) {
    return 'In $days Tagen';
  }

  @override
  String get subscriptionToday => 'Heute';

  @override
  String get subscriptionOverdue => 'Überfällig';

  @override
  String get subscriptionMemberSince => 'Mitglied seit';

  @override
  String get subscriptionMonthly => 'Monatlich';

  @override
  String get subscriptionYearly => 'Jährlich';

  @override
  String get noActiveSubscription => 'Kein aktives Abonnement';

  @override
  String get noActiveSubscriptionLandlord =>
      'Abonnieren Sie, um Premium-Funktionen freizuschalten und Ihre Immobilien effizienter zu verwalten.';

  @override
  String get noActiveSubscriptionTenant =>
      'Abonnieren Sie, um auf alle Funktionen zuzugreifen und ein nahtloses Erlebnis zu genießen.';

  @override
  String get tenantPayments => 'Mieter-Zahlungen';

  @override
  String get totalOutstanding => 'Gesamt ausstehend';

  @override
  String get pendingPayments => 'Ausstehende Zahlungen';

  @override
  String get overduePayments => 'Überfällige Zahlungen';

  @override
  String get noTenantsYetMessage =>
      'Fügen Sie Mieter zu Ihren Immobilien hinzu, um deren Abonnementzahlungen zu verfolgen.';

  @override
  String get invitationSent => 'Einladung gesendet';

  @override
  String get propertyInvitation => 'Immobilien-Einladung';

  @override
  String toTenant(Object tenantName, Object propertyAddress) {
    return 'An $tenantName • $propertyAddress';
  }

  @override
  String fromLandlord(Object landlordName) {
    return 'Von $landlordName';
  }

  @override
  String get unknownTenant => 'Unbekannter Mieter';

  @override
  String get invitationAccepted => 'Akzeptiert';

  @override
  String get invitationPending => 'Ausstehend';

  @override
  String get messageLabel => 'Nachricht';

  @override
  String get decline => 'Ablehnen';

  @override
  String get accept => 'Annehmen';

  @override
  String get invitationExpired => 'Diese Einladung ist abgelaufen';

  @override
  String acceptedOn(Object date) {
    return 'Akzeptiert $date';
  }

  @override
  String declinedOn(Object date) {
    return 'Abgelehnt $date';
  }

  @override
  String receivedOn(Object date) {
    return 'Erhalten $date';
  }

  @override
  String get justNow => 'gerade eben';

  @override
  String minutesAgo(Object minutes) {
    return '${minutes}m her';
  }

  @override
  String hoursAgo(Object hours) {
    return '${hours}h her';
  }

  @override
  String get imageRemoved => 'Bild entfernt';

  @override
  String get upgradePlan => 'Plan upgraden';

  @override
  String get editProperty => 'Immobilie bearbeiten';

  @override
  String get newProperty => 'Neue Immobilie';

  @override
  String get addPropertyDetails =>
      'Immobiliendetails hinzufügen, um zu beginnen';

  @override
  String get updatePropertyDetails => 'Immobiliendetails aktualisieren';

  @override
  String get streetAddress => 'Straße';

  @override
  String get city => 'Stadt';

  @override
  String get postalCode => 'Postleitzahl';

  @override
  String get images => 'Bilder';

  @override
  String get addressRequired => 'Adresse ist erforderlich';

  @override
  String get cityRequired => 'Stadt ist erforderlich';

  @override
  String get postalCodeRequired => 'Postleitzahl ist erforderlich';

  @override
  String get rentRequired => 'Miete ist erforderlich';

  @override
  String get sizeRequired => 'Größe ist erforderlich';

  @override
  String get roomsRequired => 'Zimmer sind erforderlich';

  @override
  String get updatingProperty => 'Immobilie wird aktualisiert...';

  @override
  String get creatingProperty => 'Immobilie wird erstellt...';

  @override
  String get selectAmenities => 'Ausstattungsmerkmale auswählen';

  @override
  String get addPhotos => 'Fotos hinzufügen';

  @override
  String get selectPhotosDescription =>
      'Wählen Sie Fotos aus, um Ihre Immobilie zu präsentieren';

  @override
  String get tapToUploadImages => 'Tippen, um Bilder hochzuladen';

  @override
  String get saveProperty => 'Immobilie speichern';

  @override
  String get updateProperty => 'Immobilie aktualisieren';

  @override
  String get payments => 'Zahlungen';

  @override
  String get overview => 'Übersicht';

  @override
  String get payouts => 'Auszahlungen';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get revenueDetails => 'Einnahmen Details';

  @override
  String get outstandingPaymentsDetails => 'Ausstehende Zahlungen Details';

  @override
  String get totalRevenuePerMonth => 'Gesamteinnahmen pro Monat';

  @override
  String get averagePerProperty => 'Durchschnitt pro Immobilie';

  @override
  String get numberOfProperties => 'Anzahl Immobilien';

  @override
  String get revenueByProperty => 'Einnahmen nach Immobilie';

  @override
  String get revenueDistribution => 'Einnahmenverteilung';

  @override
  String get rentIncome => 'Mieteinnahmen';

  @override
  String get utilityCosts => 'Nebenkosten';

  @override
  String get otherIncome => 'Sonstige Einnahmen';

  @override
  String get unknownAddress => 'Unbekannte Adresse';

  @override
  String get openPayments => 'Offene Zahlungen';

  @override
  String get totalAmount => 'Gesamtbetrag';

  @override
  String get noOutstandingPayments => 'Keine ausstehenden Zahlungen';

  @override
  String get allRentPaymentsCurrent => 'Alle Mietzahlungen sind aktuell.';
}
