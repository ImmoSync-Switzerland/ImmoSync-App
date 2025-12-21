// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'ImmoSync';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get properties => 'Proprietà';

  @override
  String get tenants => 'Inquilini';

  @override
  String get services => 'Servizi';

  @override
  String get messages => 'Messaggi';

  @override
  String get reports => 'Rapporti';

  @override
  String get profile => 'Profilo';

  @override
  String get settings => 'Impostazioni';

  @override
  String get language => 'Lingua';

  @override
  String get theme => 'Tema';

  @override
  String get dashboardDesign => 'Design della dashboard';

  @override
  String get currency => 'Valuta';

  @override
  String get preferences => 'Preferenze';

  @override
  String get security => 'Sicurezza';

  @override
  String get notifications => 'Notifiche';

  @override
  String get about => 'Informazioni';

  @override
  String get logout => 'Esci';

  @override
  String get light => 'Chiaro';

  @override
  String get dark => 'Scuro';

  @override
  String get system => 'Sistema';

  @override
  String get english => 'Inglese';

  @override
  String get german => 'Tedesco';

  @override
  String get french => 'Francese';

  @override
  String get italian => 'Italiano';

  @override
  String get selectLanguage => 'Seleziona lingua';

  @override
  String get selectTheme => 'Seleziona tema';

  @override
  String get selectDashboardDesign => 'Seleziona il design della dashboard';

  @override
  String get selectCurrency => 'Seleziona valuta';

  @override
  String get cancel => 'Annulla';

  @override
  String languageChangedTo(Object language) {
    return 'Lingua cambiata in $language';
  }

  @override
  String themeChangedTo(Object theme) {
    return 'Tema cambiato in $theme';
  }

  @override
  String dashboardDesignChangedTo(Object design) {
    return 'Design della dashboard cambiato in $design';
  }

  @override
  String currencyChangedTo(Object currency) {
    return 'Valuta cambiata in $currency';
  }

  @override
  String get dashboardDesignGlass => 'Glass (moderno)';

  @override
  String get dashboardDesignClassic => 'Classico (standard)';

  @override
  String get dashboardDesignPromptDescription =>
      'Scegli lo stile dell\'interfaccia che preferisci. Potrai cambiarlo in seguito nelle impostazioni.';

  @override
  String get dashboardDesignGlassDescription =>
      'Aspetto moderno effetto vetro con gradienti intensi.';

  @override
  String get dashboardDesignClassicDescription =>
      'Card luminose con un layout professionale pulito.';

  @override
  String get messageStatusSending => 'Invio in corso...';

  @override
  String messageStatusDeliveredAt(Object time) {
    return 'Consegnato alle $time';
  }

  @override
  String messageStatusReadAt(Object time) {
    return 'Letto alle $time';
  }

  @override
  String get welcome => 'Benvenuto';

  @override
  String get totalProperties => 'Proprietà totali';

  @override
  String get monthlyRevenue => 'Entrate mensili';

  @override
  String get revenueVsExpenses => 'Entrate vs Spese';

  @override
  String get totalRevenue => 'Entrate totali';

  @override
  String get totalExpenses => 'Spese totali';

  @override
  String get netIncome => 'Reddito netto';

  @override
  String get monthlyRentDue => 'Affitto mensile dovuto';

  @override
  String get month => 'Mese';

  @override
  String get revenue => 'Entrate';

  @override
  String get expenses => 'Spese';

  @override
  String get net => 'Netto';

  @override
  String get occupancyRate => 'Tasso di occupazione';

  @override
  String get maintenanceRequests => 'Richieste di manutenzione';

  @override
  String get search => 'Cerca';

  @override
  String get searchConversations => 'Cerca conversazioni...';

  @override
  String get searchProperties => 'Cerca proprietà...';

  @override
  String get noConversations => 'Nessuna conversazione trovata';

  @override
  String get noProperties => 'Nessuna proprietà trovata';

  @override
  String get propertyDetails => 'Dettagli della proprietà';

  @override
  String get address => 'Indirizzo';

  @override
  String get type => 'Tipo';

  @override
  String get status => 'Stato';

  @override
  String get rent => 'Affitto';

  @override
  String get available => 'Disponibile';

  @override
  String get occupied => 'Occupato';

  @override
  String get maintenance => 'Manutenzione';

  @override
  String get area => 'Area';

  @override
  String get mapNotAvailable => 'Mappa non disponibile';

  @override
  String get contactLandlord => 'Contatta proprietario';

  @override
  String get statusAvailable => 'Disponibile';

  @override
  String get statusRented => 'Affittato';

  @override
  String get statusMaintenance => 'Manutenzione';

  @override
  String get newMessage => 'Nuovo messaggio';

  @override
  String get typeMessage => 'Scrivi un messaggio...';

  @override
  String get send => 'Invia';

  @override
  String get revenueReport => 'Rapporto entrate';

  @override
  String get occupancyReport => 'Rapporto occupazione';

  @override
  String get maintenanceReport => 'Rapporto manutenzione';

  @override
  String get generateReport => 'Genera rapporto';

  @override
  String get actual => 'Reale';

  @override
  String get planned => 'Pianificato';

  @override
  String get emailNotifications => 'Notifiche email';

  @override
  String get pushNotifications => 'Notifiche push';

  @override
  String get paymentReminders => 'Promemoria pagamenti';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get privacyPolicyLastUpdated => 'Ultimo aggiornamento: 3 ottobre 2025';

  @override
  String get privacyPolicyContent =>
      'La presente Informativa sulla Privacy spiega come ImmoSync KLG (\"ImmoSync\", \"noi\") tratta i dati personali quando utilizzi il nostro sito web, le applicazioni e i servizi (i \"Servizi\").\n\nImmoSync KLG, Hauptstrasse 38, 4411 Seltisberg, Basilea Campagna, Svizzera · Tel: +41 76 391 94 00 · E‑mail: info@immosync.ch\n\nIndice\n1. Titolare del trattamento\n2. Quali dati trattiamo\n3. Finalità e basi giuridiche\n4. Cookie e tracciamento\n5. Analisi e terze parti\n6. Condivisione dei dati\n7. Trasferimenti internazionali\n8. Conservazione\n9. Sicurezza dei dati\n10. Minori\n11. I tuoi diritti\n12. Esercizio dei tuoi diritti\n13. Modifiche alla presente informativa\n14. Contatti\n1. Titolare del trattamento\nIl titolare del trattamento in relazione ai Servizi è ImmoSync KLG. Per alcune funzioni (es. pagamenti con Stripe o notifiche push) fornitori esterni agiscono come titolari autonomi o responsabili del trattamento.\n\n2. Quali dati trattiamo\nA seconda dell’uso dei Servizi trattiamo, tra gli altri:\n\nDati di account e profilo (nome, e‑mail, telefono, indirizzo, ruoli)\nDati di autenticazione (hash delle password, token)\nDati di utilizzo e log (indirizzo IP, info dispositivo/browser, azioni, timestamp)\nContenuti che fornisci (messaggi, ticket, documenti, media)\nDati relativi ai pagamenti (tramite Stripe; non memorizziamo l’intero numero di carta)\nDati dispositivo/app per funzioni mobili (notifiche, contatti – solo con consenso)\nDati di comunicazione (richieste al supporto, feedback)\n\n3. Finalità e basi giuridiche (GDPR / LPD svizzera)\nFornitura e gestione dei Servizi; esecuzione del contratto (Art. 6(1)(b) GDPR)\nMiglioramento di sicurezza, stabilità, performance; difesa legale (legittimo interesse, Art. 6(1)(f))\nComunicazioni con te (contratto, interesse legittimo o consenso)\nFatturazione e obblighi legali (Art. 6(1)(c))\nFunzionalità opzionali previo consenso (Art. 6(1)(a)); revocabile in qualsiasi momento\n\n4. Cookie e tracciamento\nUtilizziamo cookie necessari per funzioni di base ed eventualmente cookie analitici per comprendere l’uso. Puoi gestire i cookie nelle impostazioni del browser. Disattivare cookie non essenziali può limitare funzioni.\n\n5. Analisi e terze parti\nUtilizziamo fornitori affidabili per infrastruttura, analisi, pagamenti, messaggistica e monitoraggio errori. Trattano i dati solo quanto necessario e nel rispetto della normativa applicabile.\n\nEsempi: Hosting (es. Vercel/AWS), Pagamenti (Stripe), Analisi (strumenti privacy-friendly o – dove consentito – Google Analytics).\n\n6. Condivisione dei dati\nCondividiamo i dati se necessario con responsabili esterni e partner per fornire i Servizi, adempiere obblighi legali o in operazioni societarie. Non vendiamo dati personali.\n\n7. Trasferimenti internazionali\nPer trasferimenti verso paesi senza livello adeguato di protezione applichiamo garanzie idonee (es. Clausole Contrattuali Standard con allegati svizzeri).\n\n8. Conservazione\nConserviamo i dati personali solo per il tempo necessario alle finalità descritte o richiesto dalla legge; poi li eliminiamo o anonimizzamo, oppure li custodiamo in modo sicuro finché la cancellazione è possibile (es. backup).\n\n9. Sicurezza dei dati\nMisure tecniche e organizzative adeguate (cifratura, controlli accesso, monitoraggio). Nessun sistema è sicuro al 100 %; l’uso dei Servizi avviene a tuo rischio.\n\n10. Minori\nI Servizi non sono destinati a minori di 18 anni. Non raccogliamo consapevolmente dati di minori. Se ritieni il contrario contattaci per la cancellazione.\n\n11. I tuoi diritti\nIn base alla tua residenza: accesso, rettifica, cancellazione, limitazione, portabilità, opposizione; reclamo a un’autorità di controllo (es. Incaricato federale in Svizzera; autorità UE; ICO UK).\n\n12. Esercizio dei tuoi diritti\nContattaci a info@immosync.ch o tramite il modulo su immosync.ch/contact. Le richieste vengono gestite secondo legge.\n\n13. Modifiche alla presente informativa\nAggiorniamo questa informativa quando necessario per riflettere cambiamenti nei trattamenti o obblighi legali. La data \"Ultimo aggiornamento\" indica la versione corrente.\n\n14. Contatti\n\nImmoSync KLG\n\nHauptstrasse 38\n\n4411 Seltisberg (Basilea Campagna)\n\nSvizzera\n\nTel: +41 76 391 94 00\n\nE‑mail: info@immosync.ch';

  @override
  String get termsOfService => 'Termini di servizio';

  @override
  String get termsOfServiceLastUpdated =>
      'Ultimo aggiornamento: 1 ottobre 2025';

  @override
  String get termsOfServiceContent =>
      'Termini di Servizio (TdS)\nUltimo aggiornamento: 1 ottobre 2025\n\nI presenti Termini di Servizio (\"Termini\") disciplinano l\'uso di tutti i prodotti, servizi e applicazioni di ImmoSync KLG (\"ImmoSync\", \"noi\"). Accedendo o utilizzando i Servizi accetti questi Termini. In caso di mancato accordo non puoi usare i Servizi.\n\nImmoSync KLG, Hauptstrasse 38, 4411 Seltisberg, Basilea Campagna, Svizzera.\nTel: +41 76 391 94 00 · E-mail: info@immosync.ch\n\nIndice\nDisposizioni Fondamentali\n1. I Nostri Servizi\n2. Diritti di Proprietà Intellettuale\n3. Dichiarazioni dell\'Utente\n4. Registrazione Utente\n5. Acquisti e Pagamenti\n6. Abbonamenti\n7. Software\n8. Attività Proibite\n9. Contenuti Generati dagli Utenti\n10. Licenza sui Contributi\n11. Linee Guida sulle Recensioni\n12. Applicazione Mobile\n13. Siti e Contenuti di Terzi\n14. Gestione dei Servizi\n15. Protezione dei Dati\n16. Violazioni di Copyright\n17. Durata e Cessazione\n18. Modifiche e Interruzioni\n19. Legge Applicabile\n20. Risoluzione delle Controversie\n21. Correzioni\n22. Dichiarazione di Esclusione di Garanzia\n23. Limitazione di Responsabilità\n24. Manleva\n25. Dati dell\'Utente\n26. Comunicazioni Elettroniche\n27. Notifiche SMS\n28. Disposizioni Finali\n29. Contatti\nDisposizioni Fondamentali\nAccedendo al nostro sito https://immosync.ch, alle nostre app mobili o ad altre offerte (collettivamente i \"Servizi\") dichiari di avere almeno 18 anni, di avere capacità giuridica e di aver letto e accettato i presenti Termini. Se agisci per conto di un\'entità giuridica, dichiari di essere autorizzato a vincolarla.\n\nPossiamo aggiornare i Termini in qualsiasi momento. Le modifiche saranno pubblicate sul sito o inviate via e-mail. L\'uso continuato dopo l\'entrata in vigore delle modifiche costituisce accettazione dei Termini aggiornati.\n\n1. I Nostri Servizi\nImmoSync offre una piattaforma digitale che facilita comunicazione e collaborazione tra proprietari, inquilini, fornitori di servizi e altri soggetti. La piattaforma evolve continuamente e può includere messaggistica, ticketing, gestione documenti, pianificazione, integrazioni, automazioni o prenotazioni.\n\nLe informazioni fornite non sono destinate a giurisdizioni in cui accesso o uso sarebbero contrari alla legge. Gli utenti fuori dalla Svizzera sono responsabili del rispetto delle leggi locali.\n\n2. Diritti di Proprietà Intellettuale\nTutti i contenuti, marchi, design, software e database dei Servizi appartengono a ImmoSync KLG o sono utilizzati sotto licenza e sono protetti da leggi sulla proprietà intellettuale.\n\nConcediamo una licenza non esclusiva, revocabile e non trasferibile per usare i Servizi per fini interni. Qualsiasi riproduzione, modifica, pubblicazione o sfruttamento oltre il perimetro contrattuale richiede consenso scritto.\n\n3. Dichiarazioni dell\'Utente\nGarantisci che le informazioni fornite siano veritiere, aggiornate e complete e che verranno aggiornate in caso di cambiamenti. Ti impegni a usare i Servizi in conformità alla legge e a non violare diritti di terzi.\n\nAccesso tramite strumenti automatici o bot vietato. Possiamo sospendere o eliminare account in caso di violazioni.\n\n4. Registrazione Utente\nAlcune funzioni richiedono registrazione. Le credenziali devono restare riservate. Sei responsabile di tutte le attività del tuo account. Possiamo rifiutare o modificare nomi utente ingannevoli o lesivi.\n\n5. Acquisti e Pagamenti\nI pagamenti devono essere effettuati in franchi svizzeri (CHF) ai prezzi indicati. Metodi accettati mostrati nel checkout. Tasse e imposte calcolate secondo legge.\n\nDevi mantenere aggiornati i dati di pagamento e autorizzi l\'addebito degli importi dovuti. Possiamo esaminare, limitare o rifiutare ordini.\n\n6. Abbonamenti\nSi rinnovano automaticamente salvo disdetta tempestiva. La disdetta via account ha effetto a fine periodo di fatturazione.\n\nPeriodi di prova gratuiti possono essere modificati o terminati. Alla scadenza, conversione automatica in abbonamento a pagamento salvo annullamento.\n\n7. Software\nPossiamo fornire software o app. Eventuali EULA prevalgono. Vietato decompilare, reverse engineer o ridistribuire senza autorizzazione.\n\n8. Attività Proibite\nUso illecito, fraudolento o molesto vietato, incluso:\nRaccolta o scraping non autorizzati\nContenuti illeciti, diffamatori o discriminatori\nTentativi di elusione sicurezza o diffusione malware\nAbuso supporto, segnalazioni false, furto d\'identità.\nPossiamo intervenire (rimozione, sospensione, azioni legali).\n\n9. Contenuti Generati dagli Utenti\nPuoi caricare contenuti (testi, immagini, documenti). Sei responsabile della conformità legale e del rispetto dei diritti.\n\n10. Licenza sui Contributi\nCaricando contenuti concedi licenza mondiale, gratuita, trasferibile e perpetua a usare, memorizzare, adattare e pubblicare per l\'operatività dei Servizi. Mantieni la titolarità.\n\n11. Linee Guida sulle Recensioni\nDevono riflettere esperienze reali, essere accurate e prive di offese. Possiamo rimuovere recensioni non conformi.\n\n12. Applicazione Mobile\nLicenza limitata e revocabile per installare e usare sui tuoi dispositivi. Vietato modificare o ridistribuire. Marketplace terzi non responsabili del supporto.\n\n13. Siti e Contenuti di Terzi\nPossibili link a contenuti terzi. Nessuna responsabilità per accuratezza, disponibilità o privacy. Uso a tuo rischio.\n\n14. Gestione dei Servizi\nPossiamo monitorare, limitare accesso, cancellare dati o adeguare tecnicamente per sicurezza e buon funzionamento. Nessun obbligo di monitoraggio totale.\n\n15. Protezione dei Dati\nVedi Informativa Privacy (parte integrante) per trattamento dati personali.\n\n16. Violazioni di Copyright\nSegnala presunte violazioni con dettagli adeguati. Segnalazioni abusive possono avere conseguenze legali.\n\n17. Durata e Cessazione\nValidi finché usi i Servizi. Possiamo sospendere o terminare per violazioni. Puoi terminare in qualsiasi momento; obblighi dovuti restano.\n\n18. Modifiche e Interruzioni\nPossiamo modificare, ampliare o cessare parti dei Servizi. Manutenzioni possono causare interruzioni. Nessuna responsabilità per downtime inevitabile.\n\n19. Legge Applicabile\nDiritto svizzero (escluse norme conflitto e Convenzione di Vienna). Tutele imperative del consumatore invariate. Foro: Basilea Campagna.\n\n20. Risoluzione delle Controversie\nPrima soluzione amichevole. In difetto: arbitrato (Regole Corte Europea di Arbitrato, sede Strasburgo), arbitro unico, luogo: Basilea Città, lingua: tedesco. Diritti legali dei consumatori preservati.\n\n21. Correzioni\nPossiamo correggere errori e aggiornare contenuti.\n\n22. Dichiarazione di Esclusione di Garanzia\nServizi \"così come sono\" e \"come disponibili\"; nessuna garanzia ulteriore nei limiti di legge. Uso a tuo rischio.\n\n23. Limitazione di Responsabilità\nResponsabilità solo per dolo o colpa grave e per lesioni a vita, corpo o salute. Colpa lieve: solo obblighi essenziali, limitata a danni prevedibili tipici. Responsabilità legali imperative restano.\n\n24. Manleva\nTienici indenni da reclami di terzi derivanti da uso, contenuti o violazioni, incluse spese legali ragionevoli.\n\n25. Dati dell\'Utente\nBackup a tuo carico. Eseguiamo backup regolari senza garanzia assoluta contro perdita salvo nostra colpa grave.\n\n26. Comunicazioni Elettroniche\nEmail, messaggi in-app o moduli valgono notifica scritta. Consenso a comunicazioni elettroniche (rinuncia carta ove consentito).\n\n27. Notifiche SMS\nMessaggi tecnici (es. 2FA). Possibili costi operatore. Disattivazione può limitare sicurezza/funzionalità.\n\n28. Disposizioni Finali\nAccordo completo. Invalidità parziale non incide sul resto. Cessione soggetta a consenso. Mancata azione non vale rinuncia futura.\n\n29. Contatti\nImmoSync KLG\nHauptstrasse 38\n4411 Seltisberg (Basilea Campagna)\nSvizzera\nTel: +41 76 391 94 00\nE-mail: info@immosync.ch';

  @override
  String get copy => 'Copia';

  @override
  String get copied => 'Copiato';

  @override
  String get export => 'Esporta';

  @override
  String get exportComingSoon => 'Funzione di esportazione in arrivo';

  @override
  String get tableOfContents => 'Indice';

  @override
  String get yourPrivacyMatters => 'La tua privacy è importante';

  @override
  String get trustBadgeText =>
      'Proteggiamo i tuoi dati e ti diamo il controllo sulla tua privacy.';

  @override
  String get version => 'Versione';

  @override
  String get unknownProperty => 'Proprietà sconosciuta';

  @override
  String get user => 'Utente';

  @override
  String get tenantManagement => 'Gestione inquilini';

  @override
  String get manageTenantDescription =>
      'Gestisci i tuoi inquilini e le loro assegnazioni di proprietà';

  @override
  String get totalTenants => 'Inquilini totali';

  @override
  String get activeTenants => 'Inquilini attivi';

  @override
  String get occupiedUnits => 'Unità occupate';

  @override
  String get pendingIssues => 'Problemi in sospeso';

  @override
  String get propertiesAssigned => 'Proprietà assegnate';

  @override
  String get empty => 'Vuoto';

  @override
  String get noTenantsFound => 'Nessun inquilino trovato';

  @override
  String get noTenantsYet => 'Nessun inquilino ancora';

  @override
  String get addPropertiesInviteTenants =>
      'Aggiungi proprietà e invita inquilini per iniziare';

  @override
  String get addProperty => 'Aggiungi proprietà';

  @override
  String get addTenant => 'Aggiungi inquilino';

  @override
  String get loadingTenants => 'Caricamento inquilini...';

  @override
  String get errorLoadingTenants => 'Errore nel caricamento degli inquilini';

  @override
  String get pleaseTryAgainLater => 'Si prega di riprovare più tardi';

  @override
  String get retryLoading => 'Riprova';

  @override
  String get editTenant => 'Modifica inquilino';

  @override
  String get deleteTenant => 'Elimina inquilino';

  @override
  String get tenantDetails => 'Dettagli inquilino';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Telefono';

  @override
  String get viewDetails => 'Visualizza dettagli';

  @override
  String get searchTenants => 'Cerca inquilini...';

  @override
  String get myProperties => 'Le mie proprietà';

  @override
  String get all => 'Tutti';

  @override
  String get rented => 'AFFITTATO';

  @override
  String get monthlyRent => 'Affitto mensile';

  @override
  String get size => 'Dimensione';

  @override
  String get rooms => 'Stanze';

  @override
  String get noPropertiesFound => 'Nessuna proprietà trovata';

  @override
  String get addFirstProperty => 'Aggiungi la tua prima proprietà per iniziare';

  @override
  String get noPropertiesAssigned => 'Nessuna proprietà assegnata';

  @override
  String get contactLandlordForAccess =>
      'Contatta il tuo proprietario per accedere alla tua proprietà';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto';

  @override
  String get retry => 'Riprova';

  @override
  String get noConversationsYet => 'Nessuna conversazione ancora';

  @override
  String get tryAdjustingSearch =>
      'Prova ad aggiustare i tuoi termini di ricerca';

  @override
  String get startConversation =>
      'Inizia una conversazione con le tue proprietà';

  @override
  String get newConversation => 'Nuova conversazione';

  @override
  String get propertySelectionMessage =>
      'La selezione delle proprietà sarà implementata con l\'integrazione del database';

  @override
  String get create => 'Crea';

  @override
  String get landlords => 'Proprietari';

  @override
  String get errorLoadingContacts => 'Errore nel caricamento dei contatti';

  @override
  String get noContactsFound => 'Nessun contatto trovato';

  @override
  String get noLandlordsFound => 'Nessun proprietario trovato';

  @override
  String get addPropertiesToConnect =>
      'Aggiungi proprietà per connetterti con gli inquilini';

  @override
  String get landlordContactsAppear =>
      'I tuoi contatti proprietari appariranno qui';

  @override
  String get property => 'Proprietà';

  @override
  String get call => 'Chiama';

  @override
  String get message => 'Messaggio';

  @override
  String get details => 'Dettagli';

  @override
  String get openChat => 'Apri chat';

  @override
  String get phoneCallFunctionality =>
      'La funzionalità di chiamata telefonica sarà implementata';

  @override
  String get contactInformation => 'Informazioni di contatto';

  @override
  String get assignedProperties => 'Proprietà assegnate';

  @override
  String get filterOptions => 'Le opzioni di filtro saranno implementate';

  @override
  String get active => 'Attivo';

  @override
  String get editProfile => 'Modifica profilo';

  @override
  String get role => 'Ruolo';

  @override
  String get disabled => 'disabilitato';

  @override
  String get privacySettings => 'Impostazioni privacy';

  @override
  String get privacySettingsMessage =>
      'Le impostazioni della privacy saranno presto disponibili';

  @override
  String get receiveUpdatesEmail => 'Ricevi aggiornamenti via email';

  @override
  String get goodMorning => 'Buongiorno';

  @override
  String get goodAfternoon => 'Buon pomeriggio';

  @override
  String get goodEvening => 'Buonasera';

  @override
  String get quickActions => 'Azioni rapide';

  @override
  String get viewProperties => 'Visualizza proprietà';

  @override
  String get outstanding => 'In sospeso';

  @override
  String get description => 'Descrizione';

  @override
  String get amenities => 'Servizi';

  @override
  String get balcony => 'Balcone';

  @override
  String get elevator => 'Ascensore';

  @override
  String get laundry => 'Lavanderia';

  @override
  String get location => 'Posizione';

  @override
  String get financialDetails => 'Dettagli finanziari';

  @override
  String get inviteTenant => 'Invita inquilino';

  @override
  String get outstandingPayments => 'Pagamenti in sospeso';

  @override
  String get searchContacts => 'Cerca contatti...';

  @override
  String get searchPropertiesTenantsMessages =>
      'Cerca proprietà, inquilini, messaggi...';

  @override
  String get typeAMessage => 'Scrivi un messaggio...';

  @override
  String get managePropertiesAndTenants =>
      'Gestisci le tue proprietà e inquilini';

  @override
  String get monthlyIncome => 'Entrate mensili';

  @override
  String get squareMeters => 'm²';

  @override
  String get chfPerMonth => 'CHF/mese';

  @override
  String get propertyDescription =>
      'Proprietà moderna situata in una posizione privilegiata con eccellenti servizi e comodo accesso ai trasporti pubblici.';

  @override
  String get landlord => 'Proprietario';

  @override
  String get updateYourInformation => 'Aggiorna le tue informazioni personali';

  @override
  String get appSettings => 'Impostazioni app';

  @override
  String get updatePassword => 'Aggiorna la tua password';

  @override
  String get signOutOfAccount => 'Esci dal tuo account';

  @override
  String get confirmLogout => 'Conferma logout';

  @override
  String get logoutConfirmation => 'Sei sicuro di voler uscire?';

  @override
  String get searchToFindResults => 'Inizia a digitare per trovare risultati';

  @override
  String get searchHint => 'Cerca proprietà, inquilini o messaggi';

  @override
  String get noResultsFound => 'Nessun risultato trovato';

  @override
  String get tryDifferentSearch => 'Prova un termine di ricerca diverso';

  @override
  String get filterProperties => 'Filtra proprietà';

  @override
  String get filterRequests => 'Filtra richieste';

  @override
  String get pending => 'In attesa';

  @override
  String get inProgress => 'In corso';

  @override
  String get completed => 'Completato';

  @override
  String get cancelled => 'Annullato';

  @override
  String get priority => 'Priorità';

  @override
  String get low => 'Bassa';

  @override
  String get medium => 'Media';

  @override
  String get high => 'Alta';

  @override
  String get emergency => 'Emergenza';

  @override
  String get noMaintenanceRequests => 'Nessuna richiesta di manutenzione';

  @override
  String get noMaintenanceRequestsDescription =>
      'Tutte le richieste di manutenzione appariranno qui';

  @override
  String get getDirections => 'Ottieni indicazioni';

  @override
  String get locationNotAvailable => 'Posizione non disponibile';

  @override
  String get addressDisplayOnly => 'Indirizzo mostrato solo per riferimento';

  @override
  String get twoFactorAuth => 'Autenticazione a due fattori';

  @override
  String get helpCenter => 'Centro assistenza';

  @override
  String get contactSupport => 'Contatta il supporto';

  @override
  String get enabled => 'abilitato';

  @override
  String get pushNotificationSubtitle =>
      'Ricevi aggiornamenti sul tuo dispositivo';

  @override
  String get paymentReminderSubtitle =>
      'Ricevi promemoria sui pagamenti in arrivo';

  @override
  String get welcomeToHelpCenter => 'Benvenuto al centro assistenza';

  @override
  String get helpCenterDescription =>
      'Trova risposte alle domande frequenti, impara le funzionalità di ImmoSync e ottieni aiuto quando ne hai bisogno.';

  @override
  String get quickLinks => 'Collegamenti rapidi';

  @override
  String get gettingStarted => 'Iniziare';

  @override
  String get gettingStartedDescription =>
      'Impara le basi dell\'utilizzo di ImmoSync';

  @override
  String get accountSettings => 'Account e impostazioni';

  @override
  String get accountSettingsDescription =>
      'Gestisci il tuo account e le impostazioni sulla privacy';

  @override
  String get propertyManagement => 'Gestione immobiliare';

  @override
  String get propertyManagementDescription =>
      'Come aggiungere e gestire proprietà';

  @override
  String get paymentsBilling => 'Pagamenti e fatturazione';

  @override
  String get paymentsBillingDescription =>
      'Comprendere pagamenti e fatturazione';

  @override
  String get frequentlyAskedQuestions => 'Domande frequenti';

  @override
  String get howToAddProperty => 'Come aggiungere una nuova proprietà?';

  @override
  String get howToAddPropertyAnswer =>
      'Vai alla scheda Proprietà e tocca il pulsante \"+\". Compila i dettagli della proprietà, aggiungi foto e salva.';

  @override
  String get howToInviteTenant => 'Come invitare un inquilino?';

  @override
  String get howToInviteTenantAnswer =>
      'Apri una proprietà e tocca \"Invita inquilino\". Inserisci il loro indirizzo email e riceveranno un invito.';

  @override
  String get howToChangeCurrency => 'Come cambiare la mia valuta?';

  @override
  String get howToChangeCurrencyAnswer =>
      'Vai a Impostazioni > Preferenze > Valuta e seleziona la tua valuta preferita.';

  @override
  String get howToEnable2FA =>
      'Come abilitare l\'autenticazione a due fattori?';

  @override
  String get howToEnable2FAAnswer =>
      'Vai a Impostazioni > Sicurezza > Autenticazione a due fattori e segui le istruzioni di configurazione.';

  @override
  String get howToExportData => 'Come esportare i miei dati?';

  @override
  String get howToExportDataAnswer =>
      'Vai a Impostazioni > Impostazioni Privacy > Gestione Dati > Esporta i miei dati.';

  @override
  String get userGuides => 'Guide utente';

  @override
  String get landlordGuide => 'Guida proprietario';

  @override
  String get landlordGuideDescription => 'Guida completa per proprietari';

  @override
  String get tenantGuide => 'Guida inquilino';

  @override
  String get tenantGuideDescription => 'Guida completa per inquilini';

  @override
  String get securityBestPractices => 'Migliori pratiche di sicurezza';

  @override
  String get securityBestPracticesDescription =>
      'Mantieni il tuo account sicuro';

  @override
  String get needMoreHelp => 'Hai bisogno di ulteriore aiuto?';

  @override
  String get needMoreHelpDescription =>
      'Non riesci a trovare quello che cerchi? Il nostro team di supporto è qui per aiutarti.';

  @override
  String get gotIt => 'Capito';

  @override
  String get gettingStartedWelcome =>
      'Benvenuto su ImmoSync! Ecco come iniziare:';

  @override
  String get gettingStartedStep1 => '1. Completa il tuo profilo';

  @override
  String get gettingStartedStep2 => '2. Aggiungi la tua prima proprietà';

  @override
  String get gettingStartedStep3 =>
      '3. Invita inquilini o connettiti con proprietari';

  @override
  String get gettingStartedStep4 => '4. Inizia a gestire le tue proprietà';

  @override
  String get propertyManagementGuide => 'Gestione proprietà in ImmoSync:';

  @override
  String get propertyManagementTip1 =>
      '• Aggiungere dettagli e foto delle proprietà';

  @override
  String get propertyManagementTip2 =>
      '• Impostare prezzi e condizioni di affitto';

  @override
  String get propertyManagementTip3 =>
      '• Invitare inquilini per visite o affitto';

  @override
  String get propertyManagementTip4 => '• Tracciare richieste di manutenzione';

  @override
  String get propertyManagementTip5 => '• Monitorare stato dei pagamenti';

  @override
  String get paymentsGuide => 'Comprendere i pagamenti in ImmoSync:';

  @override
  String get paymentsTip1 => '• Visualizzare cronologia e stato pagamenti';

  @override
  String get paymentsTip2 => '• Impostare promemoria pagamenti automatici';

  @override
  String get paymentsTip3 => '• Tracciare pagamenti in sospeso';

  @override
  String get paymentsTip4 => '• Generare report sui pagamenti';

  @override
  String get paymentsTip5 => '• Esportare dati di pagamento';

  @override
  String get landlordGuideContent => 'Guida completa per proprietari:';

  @override
  String get landlordTip1 => '• Gestione portafoglio immobiliare';

  @override
  String get landlordTip2 => '• Selezione e onboarding inquilini';

  @override
  String get landlordTip3 => '• Riscossione e tracciamento affitti';

  @override
  String get landlordTip4 => '• Gestione richieste di manutenzione';

  @override
  String get landlordTip5 => '• Reporting finanziario e analytics';

  @override
  String get landlordTip6 => '• Conformità legale e documentazione';

  @override
  String get tenantGuideContent => 'Guida completa per inquilini:';

  @override
  String get tenantTip1 => '• Ricerca e visione proprietà';

  @override
  String get tenantTip2 => '• Processo di candidatura affitto';

  @override
  String get tenantTip3 => '• Contratti di locazione e documentazione';

  @override
  String get tenantTip4 => '• Pagamento affitto e cronologia';

  @override
  String get tenantTip5 => '• Invio richieste di manutenzione';

  @override
  String get tenantTip6 => '• Comunicazione con proprietari';

  @override
  String get securityGuideContent => 'Mantieni il tuo account sicuro:';

  @override
  String get securityTip1 => '• Usa una password forte e unica';

  @override
  String get securityTip2 => '• Abilita l\'autenticazione a due fattori';

  @override
  String get securityTip3 => '• Controlla regolarmente le impostazioni privacy';

  @override
  String get securityTip4 => '• Sii cauto con le informazioni condivise';

  @override
  String get securityTip5 => '• Segnala immediatamente attività sospette';

  @override
  String get securityTip6 => '• Mantieni l\'app aggiornata';

  @override
  String get weAreHereToHelp => 'Siamo qui per aiutarti';

  @override
  String get supportTeamDescription =>
      'Il nostro team di supporto è pronto ad assisterti con qualsiasi domanda o problema. Scegli come vuoi contattarci.';

  @override
  String get quickContact => 'Contatto rapido';

  @override
  String get emailUs => 'Inviaci un\'email';

  @override
  String get callUs => 'Chiamaci';

  @override
  String get liveChat => 'Chat dal vivo';

  @override
  String get submitSupportRequest => 'Invia richiesta di supporto';

  @override
  String get supportFormDescription =>
      'Compila il modulo sottostante e ti risponderemo il prima possibile.';

  @override
  String get accountInformation => 'Informazioni account';

  @override
  String get name => 'Nome';

  @override
  String get notAvailable => 'Non disponibile';

  @override
  String get category => 'Categoria';

  @override
  String get general => 'Generale';

  @override
  String get accountAndSettings => 'Account e impostazioni';

  @override
  String get technicalIssues => 'Problemi tecnici';

  @override
  String get securityConcerns => 'Preoccupazioni di sicurezza';

  @override
  String get featureRequest => 'Richiesta funzionalità';

  @override
  String get bugReport => 'Segnalazione bug';

  @override
  String get urgent => 'Urgente';

  @override
  String get subject => 'Oggetto';

  @override
  String get subjectHint => 'Breve descrizione del tuo problema';

  @override
  String get pleaseEnterSubject => 'Inserisci un oggetto';

  @override
  String get describeYourIssue => 'Descrivi il tuo problema';

  @override
  String get issueDescriptionHint =>
      'Fornisci quanti più dettagli possibili per aiutarci a servirti meglio';

  @override
  String get pleaseDescribeIssue => 'Descrivi il tuo problema';

  @override
  String get provideMoreDetails =>
      'Fornisci più dettagli (almeno 10 caratteri)';

  @override
  String get submitRequest => 'Invia richiesta';

  @override
  String get supportInformation => 'Informazioni supporto';

  @override
  String get responseTime => 'Tempo di risposta';

  @override
  String get responseTimeInfo => 'Solitamente entro 24 ore';

  @override
  String get languages => 'Lingue';

  @override
  String get languagesSupported => 'Tedesco, Inglese, Francese, Italiano';

  @override
  String get supportHours => 'Orari supporto';

  @override
  String get supportHoursInfo => 'Lunedì-Venerdì, 9:00-18:00 CET';

  @override
  String get emergencyInfo => 'Per problemi urgenti, chiama +41 800 123 456';

  @override
  String get couldNotOpenEmail => 'Impossibile aprire l\'app email';

  @override
  String get couldNotOpenPhone => 'Impossibile aprire l\'app telefono';

  @override
  String get liveChatTitle => 'Chat dal vivo';

  @override
  String get liveChatAvailable =>
      'La chat dal vivo è attualmente disponibile durante l\'orario lavorativo (Lunedì-Venerdì, 9:00-18:00 CET).';

  @override
  String get liveChatOutsideHours =>
      'Per assistenza immediata fuori dall\'orario lavorativo, utilizza il modulo di supporto o inviaci un\'email.';

  @override
  String get close => 'Chiudi';

  @override
  String get startChat => 'Inizia chat';

  @override
  String get liveChatSoon => 'Funzionalità chat dal vivo disponibile presto';

  @override
  String get supportRequestSubmitted =>
      'Richiesta di supporto inviata con successo! Ti risponderemo presto.';

  @override
  String get supportRequests => 'Richieste di supporto';

  @override
  String get noSupportRequests => 'Nessuna richiesta di supporto';

  @override
  String get supportRequestStatusOpen => 'Aperta';

  @override
  String get supportRequestStatusInProgress => 'In corso';

  @override
  String get supportRequestStatusClosed => 'Chiusa';

  @override
  String supportRequestStatusChanged(Object status) {
    return 'Stato cambiato in $status';
  }

  @override
  String get myTenants => 'I miei inquilini';

  @override
  String get myLandlords => 'I miei proprietari';

  @override
  String get maintenanceRequestDetails => 'Dettagli richiesta di manutenzione';

  @override
  String get blockUser => 'Blocca utente';

  @override
  String get reportConversation => 'Segnala conversazione';

  @override
  String get deleteConversation => 'Elimina conversazione';

  @override
  String get unblockUser => 'Sblocca utente';

  @override
  String get blockedLabel => 'Bloccato';

  @override
  String get block => 'Blocca';

  @override
  String get unblock => 'Sblocca';

  @override
  String get report => 'Segnala';

  @override
  String get blockConfirmBody =>
      'Sei sicuro di voler bloccare questo utente? Non riceverai più i suoi messaggi.';

  @override
  String get unblockConfirmBody =>
      'Vuoi sbloccare questo utente? Potrai di nuovo scambiare messaggi.';

  @override
  String get reportConfirmBody =>
      'Sei sicuro di voler segnalare questa conversazione? Il nostro team di supporto la esaminerà.';

  @override
  String get deleteConversationConfirmBody =>
      'Sei sicuro di voler eliminare questa conversazione? Questa azione non può essere annullata.';

  @override
  String get chatOptions => 'Opzioni chat';

  @override
  String get gallery => 'Galleria';

  @override
  String get camera => 'Fotocamera';

  @override
  String get document => 'Documento';

  @override
  String get emojis => 'Emoji';

  @override
  String get imageReadyToSend => 'Immagine pronta per l\'invio';

  @override
  String get fileReadyToSend => 'File pronto per l\'invio';

  @override
  String get pleaseSendTextFirst =>
      'Invia prima un messaggio di testo per avviare la conversazione';

  @override
  String get encryptionKeyNotReady =>
      'La chiave di crittografia non è ancora pronta...';

  @override
  String get openFileFailed => 'Apertura non riuscita';

  @override
  String get attachmentFailed => 'Invio allegato non riuscito';

  @override
  String get errorSelectingImage =>
      'Errore durante la selezione dell\'immagine';

  @override
  String get errorTakingPhoto => 'Errore durante lo scatto della foto';

  @override
  String get errorSendingDocument => 'Errore durante l\'invio del documento';

  @override
  String get cannotMakeCallOnDevice =>
      'Impossibile effettuare chiamate su questo dispositivo';

  @override
  String get errorInitiatingCall => 'Errore durante l\'avvio della chiamata';

  @override
  String get invitationSentSuccessfully => 'Invito inviato con successo';

  @override
  String get failedToSendInvitation => 'Invio dell\'invito non riuscito';

  @override
  String get invitationAcceptedSuccessfully => 'Invito accettato con successo!';

  @override
  String get invitationDeclined => 'Rifiutato';

  @override
  String get failedToRespondInvitation => 'Risposta all\'invito non riuscita';

  @override
  String get callPrompt => 'Vuoi effettuare questa chiamata?';

  @override
  String get myMaintenanceRequests => 'Le mie richieste di manutenzione';

  @override
  String get errorLoadingRequests => 'Errore nel caricamento delle richieste';

  @override
  String get createRequest => 'Crea richiesta';

  @override
  String get created => 'Creato';

  @override
  String get updated => 'Aggiornato';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String get statusPending => 'In attesa';

  @override
  String get statusInProgress => 'In corso';

  @override
  String get statusCompleted => 'Completato';

  @override
  String get statusCancelled => 'Annullato';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityLow => 'Bassa';

  @override
  String get addNote => 'Aggiungi nota';

  @override
  String get invalid => 'Non valido';

  @override
  String get failed => 'Fallito';

  @override
  String get success => 'Successo';

  @override
  String get loading => 'Caricamento...';

  @override
  String get error => 'Errore';

  @override
  String get update => 'Aggiorna';

  @override
  String get delete => 'Elimina';

  @override
  String get save => 'Salva';

  @override
  String get edit => 'Modifica';

  @override
  String get view => 'Visualizza';

  @override
  String get back => 'Indietro';

  @override
  String get next => 'Avanti';

  @override
  String get previous => 'Precedente';

  @override
  String get confirm => 'Conferma';

  @override
  String get submit => 'Invia';

  @override
  String get upload => 'Carica';

  @override
  String get download => 'Scarica';

  @override
  String get share => 'Condividi';

  @override
  String get paste => 'Incolla';

  @override
  String get select => 'Seleziona';

  @override
  String get choose => 'Scegli';

  @override
  String get filter => 'Filtra';

  @override
  String get sort => 'Ordina';

  @override
  String get noData => 'Nessun dato';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get searchServices => 'Cerca servizi...';

  @override
  String get confirmBooking => 'Conferma prenotazione';

  @override
  String get bookingConfirmed => 'Prenotazione confermata';

  @override
  String get unableToOpenChat => 'Impossibile aprire la chat. Riprova.';

  @override
  String get failedToSendMessage => 'Invio messaggio fallito';

  @override
  String get chooseExportFormat => 'Scegli formato di esportazione:';

  @override
  String get errorLoadingPayments => 'Errore nel caricamento dei pagamenti';

  @override
  String get errorLoadingProperties => 'Errore nel caricamento delle proprietà';

  @override
  String get errorLoadingPropertyMetrics =>
      'Errore nel caricamento delle metriche delle proprietà';

  @override
  String get errorLoadingMaintenanceData =>
      'Errore nel caricamento dei dati di manutenzione';

  @override
  String get errorLoadingPaymentSummary =>
      'Errore nel caricamento del riepilogo pagamenti';

  @override
  String get errorLoadingMaintenanceRequests =>
      'Errore nel caricamento delle richieste di manutenzione';

  @override
  String get errorLoadingPaymentHistory =>
      'Errore nel caricamento della cronologia pagamenti';

  @override
  String get searchConversationsHint => 'Cerca conversazioni...';

  @override
  String get searchContactsHint => 'Cerca contatti...';

  @override
  String get failedToStartConversation => 'Avvio conversazione fallito';

  @override
  String get failedToLoadImage => 'Caricamento immagine fallito';

  @override
  String get failedToLoadMessages => 'Caricamento messaggi fallito';

  @override
  String get recentMessages => 'Messaggi recenti';

  @override
  String get propertyManager => 'Gestore immobiliare';

  @override
  String get documents => 'Documenti';

  @override
  String get autoPayment => 'Pagamento automatico';

  @override
  String get paymentHistory => 'Storico pagamenti';

  @override
  String get searchPropertiesMaintenanceMessages =>
      'Cerca proprietà, manutenzione, messaggi...';

  @override
  String get errorGeneric => 'Errore';

  @override
  String get pleaseSelectProperty => 'Seleziona una proprietà';

  @override
  String get maintenanceRequestSubmittedSuccessfully =>
      'Richiesta di manutenzione inviata con successo';

  @override
  String get failedToSubmitRequest => 'Invio richiesta fallito';

  @override
  String get statusUpdatedTo => 'Stato aggiornato a';

  @override
  String get failedToUpdateStatus => 'Aggiornamento stato fallito';

  @override
  String get noteAddedSuccessfully => 'Nota aggiunta con successo';

  @override
  String get failedToAddNote => 'Aggiunta nota fallita';

  @override
  String get filterOptionsWillBeImplemented =>
      'Le opzioni di filtro saranno implementate';

  @override
  String imagesSelected(Object count) {
    return '$count immagine/i selezionata/e';
  }

  @override
  String get noImagesSelected => 'Nessuna immagine selezionata';

  @override
  String get errorSelectingImages => 'Errore nella selezione delle immagini';

  @override
  String get propertyUpdatedSuccessfully =>
      'Proprietà aggiornata con successo!';

  @override
  String get propertyCreatedSuccessfully => 'Proprietà creata con successo!';

  @override
  String get deleteService => 'Elimina servizio';

  @override
  String get serviceDeleted => 'Servizio eliminato';

  @override
  String get searchPropertiesLandlordsMessages =>
      'Cerca proprietà, proprietari, messaggi...';

  @override
  String get errorLoadingConversations =>
      'Errore nel caricamento delle conversazioni';

  @override
  String get allowViewBasicProfile =>
      'Permetti ad altri utenti di vedere le tue informazioni di profilo di base';

  @override
  String get letUsersFindsPropertiesInSearch =>
      'Permetti ad altri utenti di trovare le tue proprietà nei risultati di ricerca';

  @override
  String get shareUsageAnalytics => 'Condividi analisi di utilizzo';

  @override
  String get getUpdatesAboutNewFeatures =>
      'Ricevi aggiornamenti su nuove funzionalità, suggerimenti e offerte speciali';

  @override
  String get downloadCopyPersonalData =>
      'Scarica una copia dei tuoi dati personali';

  @override
  String get permanentlyDeleteAccount =>
      'Elimina definitivamente account e tutti i dati';

  @override
  String get dataExportRequestSubmitted =>
      'Richiesta di esportazione dati inviata. Riceverai un\'email con il link di download.';

  @override
  String get accountDeletionRequestSubmitted =>
      'Richiesta di eliminazione account inviata';

  @override
  String get confirmNewPassword => 'Conferma nuova password';

  @override
  String get passwordChangedSuccessfully => 'Password cambiata con successo';

  @override
  String get failedToChangePassword => 'Cambio password fallito';

  @override
  String get profileImageUploadComingSoon =>
      'Caricamento immagine profilo disponibile presto';

  @override
  String get invalidChatParameters => 'Parametri chat non validi';

  @override
  String get allowOtherUsersViewProfile =>
      'Permetti ad altri utenti di vedere il tuo profilo';

  @override
  String get letOtherUsersFindProperties =>
      'Permetti ad altri utenti di trovare le tue proprietà';

  @override
  String get shareUsageAnalyticsDesc =>
      'Condividi analisi di utilizzo per migliorare l\'app';

  @override
  String get getUpdatesNewFeatures =>
      'Ricevi aggiornamenti su nuove funzionalità';

  @override
  String get downloadPersonalData => 'Scarica i tuoi dati personali';

  @override
  String get permanentlyDeleteAccountData =>
      'Elimina definitivamente account e tutti i dati';

  @override
  String get dataExportRequestSubmittedMessage =>
      'Richiesta di esportazione dati inviata con successo';

  @override
  String get accountDeletionRequestSubmittedMessage =>
      'Richiesta di eliminazione account inviata con successo';

  @override
  String get currentPassword => 'Password attuale';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get passwordsDoNotMatch => 'Le password non corrispondono';

  @override
  String get pleaseEnterCurrentPassword => 'Inserisci la password attuale';

  @override
  String get pleaseEnterNewPassword => 'Inserisci la nuova password';

  @override
  String get passwordTooShort => 'Password troppo corta';

  @override
  String get currentPasswordIncorrect => 'Password attuale errata';

  @override
  String get privacyVisibility => 'Privacy e visibilità';

  @override
  String get publicProfile => 'Profilo pubblico';

  @override
  String get searchVisibility => 'Visibilità nella ricerca';

  @override
  String get dataAndAnalytics => 'Dati e analisi';

  @override
  String get communicationPreferences => 'Preferenze di comunicazione';

  @override
  String get marketingEmails => 'Email di marketing';

  @override
  String get dataManagement => 'Gestione dati';

  @override
  String get exportMyData => 'Esporta i miei dati';

  @override
  String get requestDataExport => 'Richiedi esportazione dati';

  @override
  String get dangerZone => 'Zona pericolosa';

  @override
  String get thisActionCannotBeUndone =>
      'Questa azione non può essere annullata';

  @override
  String get pleaseTypeConfirmToDelete => 'Digita \'confirm\' per eliminare';

  @override
  String get typeConfirmHere => 'Digita \'confirm\' qui';

  @override
  String get pleaseTypeConfirm => 'Digita \'confirm\'';

  @override
  String get accountDeletion => 'Eliminazione account';

  @override
  String get areYouSureDeleteAccount =>
      'Sei sicuro di voler eliminare il tuo account?';

  @override
  String get thisWillPermanentlyDelete => 'Questo eliminerà definitivamente:';

  @override
  String get allProperties => 'Tutte le proprietà';

  @override
  String get allConversations => 'Tutte le conversazioni';

  @override
  String get allDocuments => 'Tutti i documenti';

  @override
  String get allPaymentHistory => 'Tutta la cronologia pagamenti';

  @override
  String get profileInformation => 'Informazioni profilo';

  @override
  String get requestDeletion => 'Richiedi eliminazione';

  @override
  String get editProfileInfo => 'Modifica informazioni profilo';

  @override
  String get firstName => 'Nome';

  @override
  String get lastName => 'Cognome';

  @override
  String get phoneNumber => 'Numero di telefono';

  @override
  String get bio => 'Biografia';

  @override
  String get bioHint => 'Raccontaci qualcosa di te';

  @override
  String get pleaseEnterFirstName => 'Inserisci il nome';

  @override
  String get pleaseEnterLastName => 'Inserisci il cognome';

  @override
  String get pleaseEnterValidEmail => 'Inserisci un\'email valida';

  @override
  String get phoneNumberOptional => 'Numero di telefono (opzionale)';

  @override
  String get saveChanges => 'Salva modifiche';

  @override
  String get profileUpdated => 'Profilo aggiornato';

  @override
  String get profileUpdatedSuccessfully => 'Profilo aggiornato con successo';

  @override
  String get failedToUpdateProfile => 'Aggiornamento profilo fallito';

  @override
  String get uploadProfileImage => 'Carica immagine profilo';

  @override
  String get takePhoto => 'Scatta foto';

  @override
  String get chooseFromGallery => 'Scegli dalla galleria';

  @override
  String get removePhoto => 'Rimuovi foto';

  @override
  String get tenantSortNameAz => 'Nome (A–Z)';

  @override
  String tenantStartingConversation(Object fullName) {
    return 'Avvio della conversazione con $fullName...';
  }

  @override
  String tenantNoPhoneAvailable(Object fullName) {
    return 'Nessun numero disponibile per $fullName';
  }

  @override
  String tenantCallTitle(Object fullName) {
    return 'Chiama $fullName';
  }

  @override
  String tenantCallConfirmation(Object phone) {
    return 'Vuoi chiamare $phone?';
  }

  @override
  String tenantCallError(Object error) {
    return 'Impossibile avviare la chiamata: $error';
  }

  @override
  String get tenantFilterTitle => 'Filtra inquilini';

  @override
  String get tenantServicesServiceProviderLabel => 'Fornitore del servizio';

  @override
  String get tenantServicesErrorLoadingProperties =>
      'Errore durante il caricamento delle proprietà';

  @override
  String get tenantServicesNoPropertiesTitle => 'Nessuna proprietà assegnata';

  @override
  String get tenantServicesNoPropertiesBody =>
      'Devi essere associato a una proprietà per visualizzare i servizi disponibili.';

  @override
  String get tenantServicesErrorLoadingServices =>
      'Errore durante il caricamento dei servizi';

  @override
  String get tenantServicesHeaderTitle => 'Servizi disponibili';

  @override
  String get tenantServicesHeaderSubtitle =>
      'Prenota i servizi messi a disposizione dal tuo proprietario. Tutti i servizi sono pre-approvati e gestiti professionalmente.';

  @override
  String get tenantServicesSearchHint => 'Cerca servizi...';

  @override
  String get tenantServicesCategoryAll => 'Tutti';

  @override
  String get tenantServicesCategoryMaintenance => 'Manutenzione';

  @override
  String get tenantServicesCategoryCleaning => 'Pulizia';

  @override
  String get tenantServicesCategoryRepair => 'Riparazione';

  @override
  String get tenantServicesCategoryGeneral => 'Generale';

  @override
  String get tenantServicesBookServiceButton => 'Prenota servizio';

  @override
  String get tenantServicesUnavailableLabel => 'Non disponibile';

  @override
  String get tenantServicesNoServicesTitle => 'Nessun servizio disponibile';

  @override
  String get tenantServicesNoServicesBody =>
      'Il tuo proprietario non ha ancora configurato dei servizi.';

  @override
  String tenantServicesBookDialogTitle(Object serviceName) {
    return 'Prenota $serviceName';
  }

  @override
  String tenantServicesServiceLine(Object serviceName) {
    return 'Servizio: $serviceName';
  }

  @override
  String tenantServicesProviderLine(Object provider) {
    return 'Fornitore: $provider';
  }

  @override
  String tenantServicesPriceLine(Object price) {
    return 'Prezzo: $price';
  }

  @override
  String get tenantServicesContactInfoLabel => 'Informazioni di contatto:';

  @override
  String get tenantServicesContactInfoUnavailable =>
      'Nessuna informazione di contatto disponibile';

  @override
  String get tenantServicesContactProviderButton => 'Contatta il fornitore';

  @override
  String tenantServicesContactInfoProvided(
      Object provider, Object serviceName) {
    return 'Le informazioni di contatto per $serviceName sono state fornite. Contatta direttamente $provider.';
  }

  @override
  String get tenant => 'Inquilino';

  @override
  String get profileImageUpload => 'Caricamento immagine profilo';

  @override
  String get forgotPasswordTitle => 'Password dimenticata?';

  @override
  String get forgotPasswordDescription =>
      'Inserisci il tuo indirizzo email e ti invieremo un link per reimpostare la password.';

  @override
  String get sendResetEmail => 'Invia e-mail di reimpostazione';

  @override
  String get backToLogin => 'Torna al login';

  @override
  String get passwordResetEmailSent =>
      'E-mail di reimpostazione inviata! Controlla la tua casella di posta.';

  @override
  String get pleaseEnterYourEmail => 'Inserisci la tua email';

  @override
  String get searchPropertiesLandlords => 'Cerca proprietà, proprietari';

  @override
  String get startTypingToFindResults =>
      'Inizia a digitare per trovare risultati';

  @override
  String get tryDifferentSearchTerm => 'Prova un termine di ricerca diverso';

  @override
  String get twoFactorAuthentication => 'Autenticazione a due fattori';

  @override
  String get privacySettingsTitle => 'Impostazioni sulla privacy';

  @override
  String get privacySettingsIntro =>
      'Controlla chi può vedere il tuo profilo e come vieni mostrato agli altri utenti.';

  @override
  String get privacyProfileVisibilityTitle =>
      'Mostra il profilo agli altri utenti';

  @override
  String get privacyProfileVisibilityDescription =>
      'Consenti agli utenti con cui interagisci di vedere i dettagli del tuo profilo.';

  @override
  String get privacyContactInfoTitle => 'Mostra le informazioni di contatto';

  @override
  String get privacyContactInfoDescription =>
      'Mostra e-mail e numero di telefono agli utenti collegati';

  @override
  String get privacyDataSharingSectionTitle => 'Condivisione dei dati';

  @override
  String get privacyDataSharingDescription =>
      'Decidi come i tuoi dati vengono utilizzati per migliorare ImmoLink.';

  @override
  String get privacyAllowPropertySearchTitle =>
      'Consenti la ricerca delle proprietà';

  @override
  String get privacyAllowPropertySearchDescription =>
      'Permetti agli altri utenti di trovare le tue proprietà nei risultati di ricerca';

  @override
  String get privacyUsageAnalyticsTitle => 'Condividi le analisi di utilizzo';

  @override
  String get privacyUsageAnalyticsDescription =>
      'Aiuta a migliorare ImmoLink condividendo dati di utilizzo anonimi';

  @override
  String get privacyMarketingSectionTitle => 'Marketing e comunicazioni';

  @override
  String get privacyMarketingDescription =>
      'Controlla come ti informiamo su nuove funzionalità e offerte.';

  @override
  String get privacyMarketingEmailsTitle => 'Ricevi email promozionali';

  @override
  String get privacyMarketingEmailsDescription =>
      'Ricevi aggiornamenti su nuove funzionalità, suggerimenti e offerte speciali';

  @override
  String get privacyDataManagementSectionTitle => 'Gestione dei dati';

  @override
  String get privacyDataManagementDescription =>
      'Gestisci i tuoi dati personali ed esporta le tue informazioni.';

  @override
  String get privacyExportDataTitle => 'Esporta i miei dati';

  @override
  String get privacyExportDataSubtitle =>
      'Scarica una copia dei tuoi dati personali';

  @override
  String get privacyDeleteAccountTitle => 'Elimina account';

  @override
  String get privacyDeleteAccountSubtitle =>
      'Elimina definitivamente il tuo account e tutti i dati';

  @override
  String get privacyExportDialogTitle => 'Esporta i tuoi dati';

  @override
  String get privacyExportDialogDescription =>
      'Prepariamo un link di download con tutti i tuoi dati personali, inclusi:';

  @override
  String get privacyExportIncludesProfile => 'Informazioni del profilo';

  @override
  String get privacyExportIncludesProperty => 'Dati delle proprietà';

  @override
  String get privacyExportIncludesMessages => 'Messaggi e conversazioni';

  @override
  String get privacyExportIncludesPayments => 'Storico dei pagamenti';

  @override
  String get privacyExportIncludesSettings => 'Impostazioni e preferenze';

  @override
  String get privacyExportDialogNote =>
      'Il processo può richiedere fino a 24 ore. Riceverai un\'e-mail con il link per il download.';

  @override
  String get privacyExportSuccess =>
      'Richiesta di esportazione inviata. Riceverai presto un link via e-mail.';

  @override
  String get privacyExportButton => 'Richiedi esportazione';

  @override
  String get privacyDeleteDialogTitle => 'Elimina account';

  @override
  String get privacyDeleteDialogQuestion =>
      'Sei sicuro di voler eliminare il tuo account?';

  @override
  String get privacyDeleteDialogWarningTitle =>
      'Questa azione eliminerà definitivamente:';

  @override
  String get privacyDeleteDialogDeleteProfile =>
      'Il tuo profilo e tutti i dati personali';

  @override
  String get privacyDeleteDialogDeleteProperties =>
      'Tutte le proprietà e i relativi dati';

  @override
  String get privacyDeleteDialogDeleteMessages => 'Messaggi e conversazioni';

  @override
  String get privacyDeleteDialogDeletePayments => 'Storico dei pagamenti';

  @override
  String get privacyDeleteDialogDeleteDocuments =>
      'Tutti i documenti e le immagini caricati';

  @override
  String get privacyDeleteDialogIrreversible =>
      'Questa azione è irreversibile. Esporta i tuoi dati se vuoi conservarne una copia.';

  @override
  String get privacyDeleteRequestSubmitted =>
      'Richiesta di eliminazione inviata. Questa funzione sarà disponibile a breve.';

  @override
  String get privacyDeleteButton => 'Elimina account';

  @override
  String get changePasswordPageTitle => 'Cambia password';

  @override
  String get changePasswordSubtitle =>
      'Inserisci la password attuale e scegline una nuova';

  @override
  String get changePasswordCurrentLabel => 'Password attuale';

  @override
  String get changePasswordCurrentRequired => 'Inserisci la password attuale';

  @override
  String get changePasswordNewLabel => 'Nuova password';

  @override
  String get changePasswordNewRequired => 'Inserisci una nuova password';

  @override
  String get changePasswordNewLength =>
      'La password deve avere almeno 8 caratteri';

  @override
  String get changePasswordNewComplexity =>
      'La password deve contenere maiuscole, minuscole e numeri';

  @override
  String get changePasswordConfirmRequired => 'Conferma la nuova password';

  @override
  String get changePasswordConfirmMismatch => 'Le password non corrispondono';

  @override
  String get passwordRequirementsTitle => 'Requisiti della password';

  @override
  String get passwordRequirementLength => 'Almeno 8 caratteri';

  @override
  String get passwordRequirementUppercase => 'Contiene lettere maiuscole (A-Z)';

  @override
  String get passwordRequirementLowercase => 'Contiene lettere minuscole (a-z)';

  @override
  String get passwordRequirementNumbers => 'Contiene numeri (0-9)';

  @override
  String get changePasswordButton => 'Cambia password';

  @override
  String get removeTenant => 'Rimuovi inquilino';

  @override
  String get removeTenantConfirmation =>
      'Sei sicuro di voler rimuovere questo inquilino dalla proprietà?';

  @override
  String get tenantRemovedSuccessfully => 'Inquilino rimosso con successo';

  @override
  String get failedToRemoveTenant => 'Rimozione inquilino fallita';

  @override
  String get invitations => 'Inviti';

  @override
  String get subscriptionPageTitle => 'Abbonamento';

  @override
  String get subscriptionLoginPrompt => 'Accedi';

  @override
  String get subscriptionNoActiveTitle => 'Nessun abbonamento attivo';

  @override
  String get subscriptionNoActiveDescription =>
      'Al momento non hai un abbonamento attivo.';

  @override
  String get subscriptionViewPlansButton => 'Vedi i piani';

  @override
  String get subscriptionStatusActive => 'Abbonamento attivo';

  @override
  String subscriptionStatusValue(Object status) {
    return 'Abbonamento $status';
  }

  @override
  String get subscriptionPlanLabel => 'Piano';

  @override
  String get subscriptionAmountLabel => 'Importo';

  @override
  String get subscriptionBillingLabel => 'Fatturazione';

  @override
  String get subscriptionBillingMonthly => 'Mensile';

  @override
  String get subscriptionBillingYearly => 'Annuale';

  @override
  String get subscriptionNextBillingLabel => 'Prossima fatturazione';

  @override
  String get subscriptionDetailsTitle => 'Dettagli abbonamento';

  @override
  String get subscriptionIdLabel => 'ID abbonamento';

  @override
  String get subscriptionCustomerIdLabel => 'ID cliente';

  @override
  String get subscriptionCustomerIdUnavailable => 'N/D';

  @override
  String get subscriptionStartedLabel => 'Avviato';

  @override
  String get subscriptionEndsLabel => 'Termina';

  @override
  String get subscriptionManageButton => 'Gestisci abbonamento';

  @override
  String get subscriptionCancelButton => 'Annulla abbonamento';

  @override
  String get subscriptionErrorLoading =>
      'Errore durante il caricamento dell\'abbonamento';

  @override
  String get subscriptionNoCustomerIdMessage => 'Nessun ID cliente trovato';

  @override
  String get subscriptionOpeningPortal => 'Apertura del portale Stripe...';

  @override
  String subscriptionFailedToOpenPortal(Object error) {
    return 'Impossibile aprire il portale: $error';
  }

  @override
  String get subscriptionCancelDialogTitle => 'Annullare l\'abbonamento?';

  @override
  String get subscriptionCancelDialogBody =>
      'Sei sicuro di voler annullare l\'abbonamento? Perderai l\'accesso alle funzionalità premium al termine dell\'attuale periodo di fatturazione.';

  @override
  String get subscriptionKeepButton => 'Mantieni l\'abbonamento';

  @override
  String get subscriptionCancelledMessage => 'Abbonamento annullato';

  @override
  String subscriptionCancelErrorMessage(Object error) {
    return 'Errore: $error';
  }

  @override
  String get analyticsAndReports => 'Analisi e Rapporti';

  @override
  String get exportReportsTitle => 'Esporta report';

  @override
  String get exportFormatPrompt => 'Seleziona il formato di esportazione';

  @override
  String get exportPdf => 'Esporta PDF';

  @override
  String get generatingPdfReport => 'Generazione del report PDF...';

  @override
  String get pdfExportInfo =>
      'La funzione di esportazione PDF sarà implementata con il pacchetto pdf';

  @override
  String get propertyOverview => 'Panoramica proprietà';

  @override
  String get financialOverview => 'Panoramica finanziaria';

  @override
  String get maintenanceOverview => 'Panoramica manutenzione';

  @override
  String get recentPayments => 'Pagamenti recenti';

  @override
  String get noPaymentsFound => 'Nessun pagamento trovato';

  @override
  String get collected => 'Incassato';

  @override
  String get totalPaid => 'Totale pagato';

  @override
  String get totalPayments => 'Pagamenti totali';

  @override
  String get totalRequests => 'Richieste totali';

  @override
  String get revenueAnalytics => 'Analisi dei ricavi';

  @override
  String get revenueChartComingSoon => 'Grafico dei ricavi in arrivo';

  @override
  String get thisWeek => 'Questa settimana';

  @override
  String get thisMonth => 'Questo mese';

  @override
  String get thisQuarter => 'Questo trimestre';

  @override
  String get thisYear => 'Quest\'anno';

  @override
  String get reportPeriod => 'Periodo del rapporto';

  @override
  String get financialSummary => 'Riepilogo finanziario';

  @override
  String get totalIncome => 'Entrate totali';

  @override
  String get paymentSummary => 'Riepilogo pagamenti';

  @override
  String get dashboardComponentsRequireBrowser =>
      'I componenti del dashboard richiedono un browser web';

  @override
  String get dashboardAvailableOnWeb => 'Dashboard disponibile sul web';

  @override
  String visitWebForFullDashboard(Object component) {
    return 'Visita la versione web per accedere al dashboard completo $component';
  }

  @override
  String get planBasic => 'Basic';

  @override
  String get planProfessional => 'Professional';

  @override
  String get planEnterprise => 'Enterprise';

  @override
  String get planBasicDescription => 'Perfetto per proprietari individuali';

  @override
  String get planProfessionalDescription =>
      'Ideale per portafogli immobiliari in crescita';

  @override
  String get planEnterpriseDescription =>
      'Per grandi società di gestione immobiliare';

  @override
  String get featureUpToThreeProperties => 'Fino a 3 proprietà';

  @override
  String get featureBasicTenantManagement => 'Gestione inquilini di base';

  @override
  String get featurePaymentTracking => 'Tracciamento pagamenti';

  @override
  String get featureEmailSupport => 'Supporto email';

  @override
  String get featureUpToFifteenProperties => 'Fino a 15 proprietà';

  @override
  String get featureAdvancedTenantManagement => 'Gestione avanzata inquilini';

  @override
  String get featureAutomatedRentCollection =>
      'Riscossione affitto automatizzata';

  @override
  String get featureMaintenanceRequestTracking =>
      'Tracciamento richieste di manutenzione';

  @override
  String get featureFinancialReports => 'Report finanziari';

  @override
  String get featurePrioritySupport => 'Supporto prioritario';

  @override
  String get featureUnlimitedProperties => 'Proprietà illimitate';

  @override
  String get featureMultiUserAccounts => 'Account multi-utente';

  @override
  String get featureAdvancedAnalytics => 'Analisi avanzate';

  @override
  String get featureApiAccess => 'Accesso API';

  @override
  String get featureCustomIntegrations => 'Integrazioni personalizzate';

  @override
  String get featureDedicatedSupport => 'Supporto dedicato';

  @override
  String documentDownloadedTo(Object path) {
    return 'Documento scaricato in: $path';
  }

  @override
  String get openFolder => 'Apri cartella';

  @override
  String get downloadFailed => 'Download fallito';

  @override
  String get failedToOpen => 'Apertura non riuscita';

  @override
  String get openInExternalApp => 'Apri in app esterna';

  @override
  String get loadingDocument => 'Caricamento documento...';

  @override
  String get unableToLoadDocument => 'Impossibile caricare il documento';

  @override
  String get downloadInstead => 'Scarica invece';

  @override
  String get viewImage => 'Visualizza immagine';

  @override
  String get loadPreview => 'Carica anteprima';

  @override
  String get downloadToDevice => 'Scarica sul dispositivo';

  @override
  String get failedToDisplayImage => 'Impossibile visualizzare l\'immagine';

  @override
  String get pdfDocument => 'Documento PDF';

  @override
  String get imageFile => 'File immagine';

  @override
  String get textFile => 'File di testo';

  @override
  String get wordDocument => 'Documento Word';

  @override
  String get excelSpreadsheet => 'Foglio di calcolo Excel';

  @override
  String get powerPointPresentation => 'Presentazione PowerPoint';

  @override
  String get documentFile => 'File documento';

  @override
  String get expiringSoon => 'In scadenza';

  @override
  String get expired => 'Scaduto';

  @override
  String expiresOn(Object date) {
    return 'Scade il $date';
  }

  @override
  String tenantsCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'inquilini',
      one: 'inquilino',
    );
    return '$count $_temp0';
  }

  @override
  String propertiesCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'proprietà',
      one: 'proprietà',
    );
    return '$count $_temp0';
  }

  @override
  String daysAgo(Object days) {
    return '${days}g fa';
  }

  @override
  String weeksAgo(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count settimane fa',
      one: '1 settimana fa',
    );
    return '$_temp0';
  }

  @override
  String get subscriptionRequired => 'Abbonamento richiesto';

  @override
  String get subscriptionRequiredMessage =>
      'Questa funzione è disponibile con un abbonamento.';

  @override
  String get subscriptionChoosePlanMessage =>
      'Scegli un piano per sbloccare tutte le funzionalità.';

  @override
  String get viewPlans => 'Visualizza piani';

  @override
  String get total => 'Totale';

  @override
  String get viewAllProperties => 'Vedi tutte le proprietà';

  @override
  String get noRecentMessages => 'Nessun messaggio recente';

  @override
  String get noPendingMaintenanceRequests =>
      'Nessuna richiesta di manutenzione in sospeso';

  @override
  String get errorLoadingMaintenanceRequest =>
      'Errore nel caricamento della richiesta di manutenzione';

  @override
  String get goBack => 'Torna indietro';

  @override
  String get contractorInformation => 'Informazioni appaltatore';

  @override
  String get contact => 'Contatto';

  @override
  String get company => 'Azienda';

  @override
  String get notes => 'Note';

  @override
  String get reported => 'Segnalato';

  @override
  String get loadingAddress => 'Caricamento indirizzo...';

  @override
  String get propertyIdLabel => 'ID Proprietà';

  @override
  String get urgency => 'Urgenza';

  @override
  String get scheduled => 'Programmato';

  @override
  String get estimated => 'Stimato';

  @override
  String get actualCost => 'Costo effettivo';

  @override
  String get markAsInProgress => 'Segna in corso';

  @override
  String get markAsCompleted => 'Segna completato';

  @override
  String get enterNoteHint => 'Inserisci una nota...';

  @override
  String get addingNote => 'Aggiunta nota...';

  @override
  String get completePayment => 'Completa pagamento';

  @override
  String get perYearSuffix => 'all\'anno';

  @override
  String get perMonthSuffix => 'al mese';

  @override
  String youSavePerYear(Object savings) {
    return 'Risparmi $savings all\'anno';
  }

  @override
  String get includedFeatures => 'Funzionalità incluse';

  @override
  String get paymentMethod => 'Metodo di pagamento';

  @override
  String get paymentInfoSecure =>
      'Le tue informazioni di pagamento sono sicure';

  @override
  String get desktopPaymentNotSupported => 'Pagamento desktop non supportato';

  @override
  String get desktopPaymentUseWebOrMobile =>
      'Utilizza il web o l\'app mobile per completare il pagamento.';

  @override
  String get openWebVersion => 'Apri versione web';

  @override
  String get redirectingToSecurePaymentPage =>
      'Reindirizzamento alla pagina di pagamento sicura...';

  @override
  String get subscriptionTerms => 'Termini di abbonamento';

  @override
  String subscriptionBulletAutoRenews(Object interval) {
    return 'Si rinnova automaticamente ogni $interval';
  }

  @override
  String get yearlyInterval => 'anno';

  @override
  String get monthlyInterval => 'mese';

  @override
  String get subscriptionBulletCancelAnytime => 'Annulla in qualsiasi momento';

  @override
  String get subscriptionBulletRefundPolicy =>
      'Non rimborsabile dopo l\'inizio del periodo di fatturazione';

  @override
  String get subscriptionBulletAgreeTerms =>
      'Abbonandoti accetti i nostri termini';

  @override
  String get subscribeNow => 'Abbonati ora';

  @override
  String get continueOnWeb => 'Continua sul web';

  @override
  String paymentFailed(Object error) {
    return 'Pagamento non riuscito: $error';
  }

  @override
  String subscriptionActivated(Object planName) {
    return 'Il tuo abbonamento $planName è attivo!';
  }

  @override
  String get getStarted => 'Inizia';

  @override
  String get subscription => 'Abbonamento';

  @override
  String get manageSubscriptionTitle => 'Gestisci abbonamento';

  @override
  String get chooseYourPlanTitle => 'Scegli il tuo piano';

  @override
  String get subscriptionLoadError =>
      'Impossibile caricare i dati dell\'abbonamento';

  @override
  String get upgradeUnlockFeaturesMessage =>
      'Esegui l\'upgrade per sbloccare più funzionalità e limiti';

  @override
  String get selectPlanIntro =>
      'Seleziona il piano perfetto per le tue esigenze di gestione immobiliare';

  @override
  String get highestPlanTitle => 'Sei nel piano più alto!';

  @override
  String get highestPlanDescription =>
      'Hai accesso a tutte le funzionalità premium e gestione illimitata.';

  @override
  String get premiumThanksMessage => 'Grazie per essere un abbonato premium!';

  @override
  String get billingMonthly => 'Mensile';

  @override
  String get billingYearly => 'Annuale';

  @override
  String savePercent(Object percent) {
    return 'Risparmia $percent%';
  }

  @override
  String get currentPlanLabel => 'Piano attuale';

  @override
  String get statusLabel => 'Stato';

  @override
  String get nextBillingLabel => 'Prossima fatturazione';

  @override
  String get popularBadge => 'Popolare';

  @override
  String get upgradeBadge => 'Upgrade';

  @override
  String get upgradePlanButton => 'Upgrade piano';

  @override
  String get continueToPayment => 'Continua al pagamento';

  @override
  String get yourProperty => 'La tua proprietà';

  @override
  String get recentActivity => 'Attività recente';

  @override
  String get statusActiveUpper => 'ATTIVO';

  @override
  String get myDocuments => 'I miei documenti';

  @override
  String welcomeUser(Object userName) {
    return 'Benvenuto, $userName';
  }

  @override
  String get tenantDocumentsIntro =>
      'Gestisci qui tutti i tuoi documenti di affitto, contratti e documenti importanti.';

  @override
  String get documentCategories => 'Categorie di documenti';

  @override
  String get leaseAgreement => 'Contratto di locazione';

  @override
  String get leaseAgreementSubtitle => 'Il tuo contratto di affitto attuale';

  @override
  String get operatingCosts => 'Spese';

  @override
  String get operatingCostsSubtitle => 'Estratti conto e ricevute';

  @override
  String get protocols => 'Verbali';

  @override
  String get protocolsSubtitle => 'Verbali di consegna e ispezione';

  @override
  String get correspondence => 'Corrispondenza';

  @override
  String get correspondenceSubtitle => 'Email e lettere';

  @override
  String documentsCount(Object count, Object pluralSuffix) {
    return '$count documento$pluralSuffix';
  }

  @override
  String get enterSearchTerm => 'Inserisci un termine di ricerca';

  @override
  String get noDocumentsFound => 'Nessun documento trovato';

  @override
  String get documentSearch => 'Ricerca documenti';

  @override
  String get useDocumentsTabForDetailedSearch =>
      'Usa la scheda documenti per una ricerca dettagliata';

  @override
  String get recentDocuments => 'Documenti recenti';

  @override
  String get viewAll => 'Vedi tutto';

  @override
  String get noRecentDocuments => 'Nessun documento recente';

  @override
  String get allDocumentsHeader => 'Tutti i documenti';

  @override
  String get noDocumentsAvailable => 'Nessun documento disponibile';

  @override
  String get documentsSharedByLandlord =>
      'I documenti condivisi dal tuo proprietario appariranno qui';

  @override
  String get loadingDocuments => 'Caricamento documenti...';

  @override
  String get errorLoadingDocuments =>
      'Errore durante il caricamento dei documenti';

  @override
  String get pleaseLoginToUploadDocuments => 'Accedi per caricare documenti';

  @override
  String downloadingDocument(Object name) {
    return 'Download di $name...';
  }

  @override
  String documentDownloadedSuccessfully(Object name) {
    return '$name scaricato con successo';
  }

  @override
  String failedToDownloadDocument(Object name) {
    return 'Download di $name non riuscito';
  }

  @override
  String documentUploadedSuccessfully(Object name) {
    return 'Documento \"$name\" caricato con successo';
  }

  @override
  String failedToUploadDocument(Object error) {
    return 'Caricamento del documento non riuscito: $error';
  }

  @override
  String get featureComingSoonTitle => 'Prossimamente';

  @override
  String get featureComingSoonMessage =>
      'Questa funzione sarà disponibile in un prossimo aggiornamento.';

  @override
  String get ok => 'OK';

  @override
  String get expiring => 'In scadenza';

  @override
  String get uploadDocument => 'Carica documento';

  @override
  String get noSpecificProperty => 'Nessuna proprietà specifica';

  @override
  String failedToUploadDocumentGeneric(Object error) {
    return 'Caricamento del documento non riuscito: $error';
  }

  @override
  String get insurance => 'Assicurazione';

  @override
  String get inspectionReports => 'Rapporti di ispezione';

  @override
  String get legalDocuments => 'Documenti legali';

  @override
  String get otherCategory => 'Altro';

  @override
  String get documentManagement => 'Gestione documenti';

  @override
  String welcomeBack(Object name) {
    return 'Bentornato, $name';
  }

  @override
  String get quickUpload => 'Caricamento rapido';

  @override
  String get notice => 'Avviso';

  @override
  String get receipt => 'Ricevuta';

  @override
  String get filterDocuments => 'Filtra documenti';

  @override
  String get loadingProperties => 'Caricamento proprietà...';

  @override
  String get documentLibrary => 'Libreria documenti';

  @override
  String get uploadFirstDocument =>
      'Carica il tuo primo documento per iniziare';

  @override
  String get fileLabel => 'File';

  @override
  String get sizeLabel => 'Dimensione';

  @override
  String get recentLabel => 'Recenti';

  @override
  String get importantLabel => 'Importante';

  @override
  String get documentName => 'Nome documento';

  @override
  String get descriptionOptional => 'Descrizione (opzionale)';

  @override
  String get assignToPropertyOptional => 'Assegna alla proprietà (opzionale)';

  @override
  String get areYouSure => 'Sei sicuro?';

  @override
  String documentDeletedSuccessfully(Object name) {
    return 'Documento \"$name\" eliminato con successo';
  }

  @override
  String failedToDeleteDocument(Object error) {
    return 'Impossibile eliminare il documento: $error';
  }

  @override
  String get noAppToOpenFile => 'Nessuna app trovata per aprire questo file';

  @override
  String get subscriptionStatus => 'Stato';

  @override
  String get subscriptionMonthlyAmount => 'Importo mensile';

  @override
  String get subscriptionYearlyCost => 'Costo annuale';

  @override
  String get subscriptionMonthlyCost => 'Costo mensile';

  @override
  String get subscriptionNextBilling => 'Prossima fatturazione';

  @override
  String get subscriptionBillingInterval => 'Intervallo di fatturazione';

  @override
  String get subscriptionMySubscription => 'Il mio abbonamento';

  @override
  String get subscriptionActive => 'Attivo';

  @override
  String get subscriptionPastDue => 'Scaduto';

  @override
  String get subscriptionCanceled => 'Annullato';

  @override
  String get subscriptionPaymentDue => 'Pagamento dovuto!';

  @override
  String get subscriptionNextPayment => 'Prossimo pagamento';

  @override
  String subscriptionInDays(Object days) {
    return 'Tra $days giorni';
  }

  @override
  String get subscriptionToday => 'Oggi';

  @override
  String get subscriptionOverdue => 'In ritardo';

  @override
  String get subscriptionMemberSince => 'Membro dal';

  @override
  String get subscriptionMonthly => 'Mensile';

  @override
  String get subscriptionYearly => 'Annuale';

  @override
  String get noActiveSubscription => 'Nessun abbonamento attivo';

  @override
  String get noActiveSubscriptionLandlord =>
      'Abbonati per sbloccare le funzionalità premium e gestire le tue proprietà in modo più efficiente.';

  @override
  String get noActiveSubscriptionTenant =>
      'Abbonati per accedere a tutte le funzionalità e goderti un\'esperienza senza interruzioni.';

  @override
  String get tenantPayments => 'Pagamenti degli inquilini';

  @override
  String get totalOutstanding => 'Totale in sospeso';

  @override
  String get pendingPayments => 'Pagamenti in attesa';

  @override
  String get overduePayments => 'Pagamenti scaduti';

  @override
  String get noTenantsYetMessage =>
      'Aggiungi inquilini alle tue proprietà per monitorare i loro pagamenti di abbonamento.';

  @override
  String get invitationSent => 'Invito inviato';

  @override
  String get propertyInvitation => 'Invito alla proprietà';

  @override
  String toTenant(Object tenantName, Object propertyAddress) {
    return 'A $tenantName • $propertyAddress';
  }

  @override
  String fromLandlord(Object landlordName) {
    return 'Da $landlordName';
  }

  @override
  String get unknownTenant => 'Inquilino sconosciuto';

  @override
  String get invitationAccepted => 'Accettato';

  @override
  String get invitationPending => 'In attesa';

  @override
  String get messageLabel => 'Messaggio';

  @override
  String get decline => 'Rifiuta';

  @override
  String get accept => 'Accetta';

  @override
  String get invitationExpired => 'Questo invito è scaduto';

  @override
  String acceptedOn(Object date) {
    return 'Accettato il $date';
  }

  @override
  String declinedOn(Object date) {
    return 'Rifiutato il $date';
  }

  @override
  String receivedOn(Object date) {
    return 'Ricevuto il $date';
  }

  @override
  String get justNow => 'proprio ora';

  @override
  String minutesAgo(Object minutes) {
    return '${minutes}m fa';
  }

  @override
  String hoursAgo(Object hours) {
    return '${hours}h fa';
  }

  @override
  String get imageRemoved => 'Immagine rimossa';

  @override
  String get upgradePlan => 'Aggiorna piano';

  @override
  String get editProperty => 'Modifica proprietà';

  @override
  String get newProperty => 'Nuova proprietà';

  @override
  String get addPropertyDetails =>
      'Aggiungi i dettagli della proprietà per iniziare';

  @override
  String get updatePropertyDetails => 'Aggiorna i dettagli della tua proprietà';

  @override
  String get streetAddress => 'Indirizzo';

  @override
  String get city => 'Città';

  @override
  String get postalCode => 'Codice postale';

  @override
  String get images => 'Immagini';

  @override
  String get addressRequired => 'L\'indirizzo è richiesto';

  @override
  String get cityRequired => 'La città è richiesta';

  @override
  String get postalCodeRequired => 'Il codice postale è richiesto';

  @override
  String get rentRequired => 'L\'affitto è richiesto';

  @override
  String get sizeRequired => 'La dimensione è richiesta';

  @override
  String get roomsRequired => 'Le stanze sono richieste';

  @override
  String get updatingProperty => 'Aggiornamento proprietà...';

  @override
  String get creatingProperty => 'Creazione proprietà...';

  @override
  String get selectAmenities => 'Seleziona servizi';

  @override
  String get addPhotos => 'Aggiungi foto';

  @override
  String get selectPhotosDescription =>
      'Seleziona le foto per mostrare la tua proprietà';

  @override
  String get tapToUploadImages => 'Tocca per caricare immagini';

  @override
  String get saveProperty => 'Salva proprietà';

  @override
  String get updateProperty => 'Aggiorna proprietà';

  @override
  String get payments => 'Pagamenti';

  @override
  String get overview => 'Panoramica';

  @override
  String get payouts => 'Prelievi';

  @override
  String get refresh => 'Aggiorna';

  @override
  String get revenueDetails => 'Dettagli entrate';

  @override
  String get outstandingPaymentsDetails => 'Dettagli pagamenti in sospeso';

  @override
  String get totalRevenuePerMonth => 'Entrate totali al mese';

  @override
  String get averagePerProperty => 'Media per proprietà';

  @override
  String get numberOfProperties => 'Numero di proprietà';

  @override
  String get revenueByProperty => 'Entrate per proprietà';

  @override
  String get revenueDistribution => 'Distribuzione entrate';

  @override
  String get rentIncome => 'Reddito da affitto';

  @override
  String get utilityCosts => 'Spese accessorie';

  @override
  String get otherIncome => 'Altre entrate';

  @override
  String get unknownAddress => 'Indirizzo sconosciuto';

  @override
  String get openPayments => 'Pagamenti aperti';

  @override
  String get totalAmount => 'Importo totale';

  @override
  String get noOutstandingPayments => 'Nessun pagamento in sospeso';

  @override
  String get allRentPaymentsCurrent =>
      'Tutti i pagamenti dell\'affitto sono aggiornati.';
}
