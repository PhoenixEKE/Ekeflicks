import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
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
    Locale('en'),
    Locale('fr'),
  ];

  /// Titre pour la section Nouveautés
  ///
  /// In fr, this message translates to:
  /// **'Nouveautés'**
  String get nouveautes;

  /// Titre pour la section Populaires
  ///
  /// In fr, this message translates to:
  /// **'Populaires'**
  String get populaires;

  /// Titre pour la page profil producteur
  ///
  /// In fr, this message translates to:
  /// **'Profil Producteur'**
  String get profilePageTitle;

  /// Libellé pour le champ nom ou société dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Nom ou société'**
  String get nameOrCompany;

  /// Libellé pour le champ numéro de téléphone dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phoneNumber;

  /// Libellé pour le champ email dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// Libellé pour le champ mot de passe dans le profil
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// Libellé du bouton de mise à jour
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get updateButton;

  /// Option de langue française
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// Option de langue anglaise
  ///
  /// In fr, this message translates to:
  /// **'Anglais'**
  String get english;

  /// Titre pour la page d'erreur 404
  ///
  /// In fr, this message translates to:
  /// **'Page non trouvée'**
  String get pageNotFound;

  /// Message pour la page d'erreur 404
  ///
  /// In fr, this message translates to:
  /// **'Désolé, la page que vous avez demandée n\'existe pas.'**
  String get pageNotFoundMessage;

  /// Message affiché lorsque le profil utilisateur est mis à jour
  ///
  /// In fr, this message translates to:
  /// **'Profil mis à jour avec succès.'**
  String get profileUpdated;

  /// Titre de la page de paramètres de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Paramètres de confidentialité'**
  String get privacySettings;

  /// Titre pour la section d'aide et support
  ///
  /// In fr, this message translates to:
  /// **'Aide et Support'**
  String get helpSupport;

  /// Message affiché lorsqu'une image ne peut pas être chargée
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du chargement de l\'image'**
  String get errorLoadingImage;

  /// Option pour choisir une photo dans la galerie
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner depuis la galerie'**
  String get selectFromGallery;

  /// Option pour prendre une photo avec l'appareil photo
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get takePhoto;

  /// Bouton pour annuler une action
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// Tooltip affiché sur le bouton de changement de photo de profil
  ///
  /// In fr, this message translates to:
  /// **'Changer la photo de profil'**
  String get changePhotoTooltip;

  /// Message d'erreur lorsque le nom n'est pas renseigné
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire'**
  String get errorNameRequired;

  /// Message d'erreur lorsque le téléphone n'est pas renseigné
  ///
  /// In fr, this message translates to:
  /// **'Le numéro de téléphone est obligatoire'**
  String get errorPhoneRequired;

  /// Message d'erreur lorsque le numéro de téléphone n'est pas valide
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone invalide'**
  String get errorPhoneInvalid;

  /// Message d'erreur lorsque le mot de passe est trop court
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe est trop court'**
  String get errorPasswordTooShort;

  /// Message affiché lors de la sauvegarde
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde...'**
  String get saving;

  /// Message d'erreur lors de la sauvegarde du profil
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la sauvegarde du profil'**
  String get errorSavingProfile;

  /// Bouton pour lancer la modification du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get change;

  /// Titre du dialogue de changement de mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Changer le mot de passe'**
  String get changePassword;

  /// Champ pour saisir le nouveau mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// Champ pour confirmer le nouveau mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// Bouton pour sauvegarder le changement
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// Message d'erreur lorsque tous les champs ne sont pas remplis
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs'**
  String get fillAllFields;

  /// Message d'erreur lorsque les mots de passe saisis ne sont pas identiques
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordsDoNotMatch;

  /// Message de succès après mise à jour du mot de passe
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe mis à jour'**
  String get passwordUpdated;

  /// Option pour activer ou désactiver le partage de données
  ///
  /// In fr, this message translates to:
  /// **'Partager mes données avec les partenaires'**
  String get shareDataWithPartners;

  /// Description de l'option de partage de données
  ///
  /// In fr, this message translates to:
  /// **'Autoriser le partage de données anonymisées avec nos partenaires pour améliorer le service.'**
  String get shareDataWithPartnersDescription;

  /// Option pour rendre l'email public ou non
  ///
  /// In fr, this message translates to:
  /// **'Afficher mon email publiquement'**
  String get showEmailPublic;

  /// Description de l'option d'affichage de l'email
  ///
  /// In fr, this message translates to:
  /// **'Les autres utilisateurs pourront voir votre email sur votre profil.'**
  String get showEmailPublicDescription;

  /// Option pour activer la 2FA
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'authentification à deux facteurs'**
  String get enableTwoFactorAuth;

  /// Description de l'option 2FA
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une couche de sécurité supplémentaire lors de la connexion.'**
  String get enableTwoFactorAuthDescription;

  /// Bouton pour sauvegarder les paramètres
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les paramètres'**
  String get saveSettings;

  /// Message affiché après avoir sauvegardé les paramètres
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés'**
  String get settingsSaved;

  /// Description générale en haut de la page paramètres de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos préférences en matière de confidentialité et de collecte de données.'**
  String get privacySettingsDescription;

  /// Option pour accepter ou refuser le suivi des données d'utilisation
  ///
  /// In fr, this message translates to:
  /// **'Accepter le suivi analytique'**
  String get acceptAnalyticsTracking;

  /// Texte explicatif sous le bouton pour accepter ou refuser le suivi analytique
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons ces données pour améliorer votre expérience.'**
  String get acceptAnalyticsTrackingDescription;

  /// Bouton pour ouvrir la politique de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Voir la politique de confidentialité'**
  String get viewPrivacyPolicy;

  /// Titre de la page Politique de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyPolicy;

  /// Titre principal de la politique de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Notre politique de confidentialité'**
  String get privacyPolicyTitle;

  /// No description provided for @privacyPolicyIntroductionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Introduction'**
  String get privacyPolicyIntroductionTitle;

  /// No description provided for @privacyPolicyIntroductionContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous accordons une grande importance à la confidentialité de vos données personnelles.'**
  String get privacyPolicyIntroductionContent;

  /// No description provided for @privacyPolicyDataCollectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données collectées'**
  String get privacyPolicyDataCollectedTitle;

  /// No description provided for @privacyPolicyDataCollectedContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous pouvons collecter les données suivantes :'**
  String get privacyPolicyDataCollectedContent;

  /// No description provided for @privacyPolicyDataCollectedItem1.
  ///
  /// In fr, this message translates to:
  /// **'Informations de compte'**
  String get privacyPolicyDataCollectedItem1;

  /// No description provided for @privacyPolicyDataCollectedItem2.
  ///
  /// In fr, this message translates to:
  /// **'Données de navigation'**
  String get privacyPolicyDataCollectedItem2;

  /// No description provided for @privacyPolicyDataCollectedItem3.
  ///
  /// In fr, this message translates to:
  /// **'Préférences utilisateur'**
  String get privacyPolicyDataCollectedItem3;

  /// No description provided for @privacyPolicyDataUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation des données'**
  String get privacyPolicyDataUsageTitle;

  /// No description provided for @privacyPolicyDataUsageContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons vos données pour améliorer nos services et personnaliser votre expérience.'**
  String get privacyPolicyDataUsageContent;

  /// No description provided for @privacyPolicyDataSharingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage des données'**
  String get privacyPolicyDataSharingTitle;

  /// No description provided for @privacyPolicyDataSharingContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous ne partageons pas vos données avec des tiers sans votre consentement, sauf obligation légale.'**
  String get privacyPolicyDataSharingContent;

  /// No description provided for @privacyPolicyUserRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos droits'**
  String get privacyPolicyUserRightsTitle;

  /// No description provided for @privacyPolicyUserRightsContent.
  ///
  /// In fr, this message translates to:
  /// **'Vous disposez de plusieurs droits concernant vos données personnelles :'**
  String get privacyPolicyUserRightsContent;

  /// No description provided for @privacyPolicyUserRightsItem1.
  ///
  /// In fr, this message translates to:
  /// **'Droit d’accès'**
  String get privacyPolicyUserRightsItem1;

  /// No description provided for @privacyPolicyUserRightsItem2.
  ///
  /// In fr, this message translates to:
  /// **'Droit de rectification'**
  String get privacyPolicyUserRightsItem2;

  /// No description provided for @privacyPolicyUserRightsItem3.
  ///
  /// In fr, this message translates to:
  /// **'Droit de suppression'**
  String get privacyPolicyUserRightsItem3;

  /// No description provided for @privacyPolicyCookiesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Cookies'**
  String get privacyPolicyCookiesTitle;

  /// No description provided for @privacyPolicyCookiesContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous utilisons des cookies pour améliorer la navigation et analyser le trafic du site.'**
  String get privacyPolicyCookiesContent;

  /// No description provided for @privacyPolicySecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get privacyPolicySecurityTitle;

  /// No description provided for @privacyPolicySecurityContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous mettons en œuvre des mesures de sécurité pour protéger vos données.'**
  String get privacyPolicySecurityContent;

  /// No description provided for @privacyPolicyChangesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifications de cette politique'**
  String get privacyPolicyChangesTitle;

  /// No description provided for @privacyPolicyChangesContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous pouvons mettre à jour cette politique de confidentialité à tout moment. Les changements seront publiés sur cette page.'**
  String get privacyPolicyChangesContent;

  /// No description provided for @privacyPolicyContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get privacyPolicyContactTitle;

  /// No description provided for @privacyPolicyContactContent.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question, contactez-nous à l\'adresse suivante : support@example.com'**
  String get privacyPolicyContactContent;

  /// Texte affichant la dernière date de mise à jour de la politique
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : {date}'**
  String privacyPolicyLastUpdate(String date);

  /// Message d'erreur affiché lorsqu'il est impossible d'ouvrir le client email
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application de messagerie.'**
  String get emailLaunchError;

  /// Titre de la page d'aide et support
  ///
  /// In fr, this message translates to:
  /// **'Aide & Support'**
  String get helpSupportTitle;

  /// No description provided for @helpCenterTitle.
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide Ephrata'**
  String get helpCenterTitle;

  /// No description provided for @videoTutorialsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tutoriels vidéo'**
  String get videoTutorialsTitle;

  /// No description provided for @helpSupportVideo1Title.
  ///
  /// In fr, this message translates to:
  /// **'Comment créer un profil'**
  String get helpSupportVideo1Title;

  /// No description provided for @helpSupportVideo2Title.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter vos produits'**
  String get helpSupportVideo2Title;

  /// No description provided for @helpSupportVideo3Title.
  ///
  /// In fr, this message translates to:
  /// **'Gérer vos commandes'**
  String get helpSupportVideo3Title;

  /// No description provided for @faqTitle.
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get faqTitle;

  /// No description provided for @helpSupportFaq1Question.
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mes informations?'**
  String get helpSupportFaq1Question;

  /// No description provided for @helpSupportFaq1Answer.
  ///
  /// In fr, this message translates to:
  /// **'Allez dans Paramètres > Mon compte'**
  String get helpSupportFaq1Answer;

  /// No description provided for @helpSupportFaq2Question.
  ///
  /// In fr, this message translates to:
  /// **'Problème de connexion?'**
  String get helpSupportFaq2Question;

  /// No description provided for @helpSupportFaq2Answer.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisez votre mot de passe'**
  String get helpSupportFaq2Answer;

  /// No description provided for @contactSupportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contactez notre support'**
  String get contactSupportTitle;

  /// No description provided for @contactEmailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// No description provided for @contactEmail.
  ///
  /// In fr, this message translates to:
  /// **'support@ephrata.com'**
  String get contactEmail;

  /// No description provided for @contactPhoneFrLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone France'**
  String get contactPhoneFrLabel;

  /// No description provided for @contactPhoneFr.
  ///
  /// In fr, this message translates to:
  /// **'+33 6 83 63 70 52'**
  String get contactPhoneFr;

  /// No description provided for @contactPhoneCiLabel.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone Côte d\'Ivoire'**
  String get contactPhoneCiLabel;

  /// No description provided for @contactPhoneCi.
  ///
  /// In fr, this message translates to:
  /// **'+225 05 86 75 89 89'**
  String get contactPhoneCi;

  /// No description provided for @contactWhatsAppLabel.
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsAppLabel;

  /// No description provided for @contactWhatsApp.
  ///
  /// In fr, this message translates to:
  /// **'+225 05 86 75 86 96'**
  String get contactWhatsApp;

  /// No description provided for @loginPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'GESTIONNAIRE EKEFLICKS'**
  String get loginPageTitle;

  /// No description provided for @emailLabel.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// No description provided for @loginButton.
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get loginButton;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @emailValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailValidationError;

  /// No description provided for @passwordValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get passwordValidationError;

  /// No description provided for @changeLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get changeLanguage;

  /// No description provided for @dashboardTab.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTab;

  /// No description provided for @moviesTab.
  ///
  /// In fr, this message translates to:
  /// **'Films'**
  String get moviesTab;

  /// No description provided for @seriesTab.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get seriesTab;

  /// No description provided for @uploadTab.
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get uploadTab;

  /// No description provided for @financeTab.
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get financeTab;

  /// No description provided for @supportTab.
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get supportTab;

  /// No description provided for @profileTab.
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get profileTab;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// No description provided for @notificationsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationNewComment.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau commentaire'**
  String get notificationNewComment;

  /// No description provided for @notificationOnContent.
  ///
  /// In fr, this message translates to:
  /// **'Sur \"{content}\"'**
  String notificationOnContent(Object content);

  /// No description provided for @notificationPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu'**
  String get notificationPayment;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @dashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// No description provided for @publishedVideos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos publiées'**
  String get publishedVideos;

  /// No description provided for @totalViews.
  ///
  /// In fr, this message translates to:
  /// **'Vues totales'**
  String get totalViews;

  /// No description provided for @estimatedRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus estimés'**
  String get estimatedRevenue;

  /// No description provided for @pendingItems.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingItems;

  /// No description provided for @subscribers.
  ///
  /// In fr, this message translates to:
  /// **'Abonnés'**
  String get subscribers;

  /// No description provided for @engagementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'engagement'**
  String get engagementRate;

  /// No description provided for @recentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité récente'**
  String get recentActivity;

  /// No description provided for @newVideoPublished.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle vidéo publiée'**
  String get newVideoPublished;

  /// No description provided for @videoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo : {title}'**
  String videoTitle(Object title);

  /// No description provided for @paymentReceived.
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu'**
  String get paymentReceived;

  /// No description provided for @timeAgo.
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} {unit}'**
  String timeAgo(Object count, Object unit);

  /// No description provided for @hour.
  ///
  /// In fr, this message translates to:
  /// **'heure'**
  String get hour;

  /// No description provided for @hours.
  ///
  /// In fr, this message translates to:
  /// **'heures'**
  String get hours;

  /// No description provided for @uploadFormTitle.
  ///
  /// In fr, this message translates to:
  /// **'Formulaire Upload Vidéo'**
  String get uploadFormTitle;

  /// No description provided for @contentTypeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Type de contenu'**
  String get contentTypeLabel;

  /// No description provided for @titleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get titleLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// No description provided for @genresLabel.
  ///
  /// In fr, this message translates to:
  /// **'Genre(s)'**
  String get genresLabel;

  /// No description provided for @languageLabel.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// No description provided for @languageSpecifyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Précisez la langue'**
  String get languageSpecifyLabel;

  /// No description provided for @countryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get countryLabel;

  /// No description provided for @otherOption.
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get otherOption;

  /// No description provided for @countrySpecifyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Précisez le pays'**
  String get countrySpecifyLabel;

  /// No description provided for @releaseYearLabel.
  ///
  /// In fr, this message translates to:
  /// **'Année de sortie'**
  String get releaseYearLabel;

  /// No description provided for @productionTeamTitle.
  ///
  /// In fr, this message translates to:
  /// **'Équipe de production'**
  String get productionTeamTitle;

  /// No description provided for @directorLabel.
  ///
  /// In fr, this message translates to:
  /// **'Réalisateur'**
  String get directorLabel;

  /// No description provided for @screenwriterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Scénariste'**
  String get screenwriterLabel;

  /// No description provided for @producersLabel.
  ///
  /// In fr, this message translates to:
  /// **'Producteur(s)'**
  String get producersLabel;

  /// No description provided for @actorsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Acteurs'**
  String get actorsLabel;

  /// No description provided for @seasonManagementTitle.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des saisons'**
  String get seasonManagementTitle;

  /// No description provided for @seasonsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get seasonsLabel;

  /// No description provided for @seasonLabel.
  ///
  /// In fr, this message translates to:
  /// **'Saison'**
  String get seasonLabel;

  /// No description provided for @episodesLabel.
  ///
  /// In fr, this message translates to:
  /// **'épisode(s)'**
  String get episodesLabel;

  /// No description provided for @episodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Épisode'**
  String get episodeLabel;

  /// No description provided for @trailerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bande annonce'**
  String get trailerLabel;

  /// No description provided for @mediaFilesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fichiers multimédias'**
  String get mediaFilesTitle;

  /// No description provided for @posterLabel.
  ///
  /// In fr, this message translates to:
  /// **'Poster'**
  String get posterLabel;

  /// No description provided for @bannerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bannière'**
  String get bannerLabel;

  /// No description provided for @mainVideoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo principale'**
  String get mainVideoLabel;

  /// No description provided for @addProducerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un producteur'**
  String get addProducerTitle;

  /// No description provided for @addActorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un acteur'**
  String get addActorTitle;

  /// No description provided for @nameLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nameLabel;

  /// No description provided for @addImageButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter image'**
  String get addImageButton;

  /// No description provided for @cancelButton.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// No description provided for @addButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addButton;

  /// No description provided for @deleteButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteButton;

  /// No description provided for @requiredFieldError.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get requiredFieldError;

  /// No description provided for @formValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir correctement le formulaire'**
  String get formValidationError;

  /// No description provided for @genreSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner au moins un genre'**
  String get genreSelectionError;

  /// No description provided for @languageSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner la langue'**
  String get languageSelectionError;

  /// No description provided for @languageSpecifyError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser la langue'**
  String get languageSpecifyError;

  /// No description provided for @countrySelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un pays'**
  String get countrySelectionError;

  /// No description provided for @countrySpecifyError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser le pays'**
  String get countrySpecifyError;

  /// No description provided for @yearSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner l\'année de sortie'**
  String get yearSelectionError;

  /// No description provided for @directorNameError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom du réalisateur'**
  String get directorNameError;

  /// No description provided for @screenwriterNameError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom du scénariste'**
  String get screenwriterNameError;

  /// No description provided for @posterSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une image poster'**
  String get posterSelectionError;

  /// No description provided for @bannerSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une image banner'**
  String get bannerSelectionError;

  /// No description provided for @videoSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une vidéo'**
  String get videoSelectionError;

  /// No description provided for @seasonSelectionError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins une saison pour une série'**
  String get seasonSelectionError;

  /// No description provided for @seasonValidationError.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez compléter toutes les saisons et épisodes'**
  String get seasonValidationError;

  /// No description provided for @formSubmissionSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Formulaire soumis avec succès !'**
  String get formSubmissionSuccess;

  /// No description provided for @submitButton.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre le formulaire'**
  String get submitButton;

  /// No description provided for @addSeasonButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une saison'**
  String get addSeasonButton;

  /// No description provided for @addTrailerButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une bande-annonce'**
  String get addTrailerButton;

  /// No description provided for @addPosterButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Poster'**
  String get addPosterButton;

  /// No description provided for @addBannerButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Bannière'**
  String get addBannerButton;

  /// No description provided for @addVideoButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Vidéo'**
  String get addVideoButton;

  /// No description provided for @seasonDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description de la saison'**
  String get seasonDescriptionLabel;

  /// No description provided for @episodeDescriptionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get episodeDescriptionLabel;

  /// No description provided for @seasonTrailerLabel.
  ///
  /// In fr, this message translates to:
  /// **'Bande-annonce de la saison'**
  String get seasonTrailerLabel;

  /// No description provided for @addSeasonPosterButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter poster (saison)'**
  String get addSeasonPosterButton;

  /// No description provided for @addSeasonBannerButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter bannière (saison)'**
  String get addSeasonBannerButton;

  /// No description provided for @addEpisodeTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un épisode'**
  String get addEpisodeTooltip;

  /// No description provided for @removeSeasonTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la saison'**
  String get removeSeasonTooltip;

  /// No description provided for @confirmationTitle.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmationTitle;

  /// No description provided for @confirmationMessage.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer cet élément ?'**
  String get confirmationMessage;

  /// No description provided for @titleHint.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le titre'**
  String get titleHint;

  /// No description provided for @selectVideoFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une vidéo d\'abord'**
  String get selectVideoFirst;

  /// No description provided for @addSeason.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une saison'**
  String get addSeason;

  /// No description provided for @seasonTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la saison'**
  String get seasonTitleLabel;

  /// No description provided for @seasonTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: Saison 3'**
  String get seasonTitleHint;

  /// No description provided for @addEpisode.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un épisode (Saison {seasonNumber})'**
  String addEpisode(Object seasonNumber);

  /// No description provided for @detailsTab.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get detailsTab;

  /// No description provided for @videoTab.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get videoTab;

  /// No description provided for @episodeTitleLabel.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'épisode'**
  String get episodeTitleLabel;

  /// No description provided for @episodeTitleHint.
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'épisode'**
  String get episodeTitleHint;

  /// No description provided for @durationLabel.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get durationLabel;

  /// No description provided for @selectedFile.
  ///
  /// In fr, this message translates to:
  /// **'Fichier sélectionné'**
  String get selectedFile;

  /// No description provided for @uploadVideo.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger vidéo'**
  String get uploadVideo;

  /// No description provided for @selectVideoPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une vidéo'**
  String get selectVideoPrompt;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get requiredField;

  /// No description provided for @invalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get invalidNumber;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @secure_access.
  ///
  /// In fr, this message translates to:
  /// **'Accès Sécurisé'**
  String get secure_access;

  /// No description provided for @enter_pin.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre code PIN'**
  String get enter_pin;

  /// No description provided for @invalid_code.
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get invalid_code;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @my_finances.
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get my_finances;

  /// No description provided for @available_balance.
  ///
  /// In fr, this message translates to:
  /// **'Solde Disponible'**
  String get available_balance;

  /// No description provided for @last_withdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Dernier retrait'**
  String get last_withdrawal;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @pending_payments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements en attente'**
  String get pending_payments;

  /// No description provided for @available_in_48h.
  ///
  /// In fr, this message translates to:
  /// **'Disponible dans 48h'**
  String get available_in_48h;

  /// No description provided for @request_withdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Demande de retrait de'**
  String get request_withdrawal;

  /// No description provided for @withdrawal_request.
  ///
  /// In fr, this message translates to:
  /// **'Demande de Retrait'**
  String get withdrawal_request;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @enter_amount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un montant'**
  String get enter_amount;

  /// No description provided for @amount_positive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être positif'**
  String get amount_positive;

  /// No description provided for @amount_exceeds_balance.
  ///
  /// In fr, this message translates to:
  /// **'Le montant dépasse votre solde de {amount}€'**
  String amount_exceeds_balance(Object amount);

  /// No description provided for @payment_method.
  ///
  /// In fr, this message translates to:
  /// **'Méthode de Paiement'**
  String get payment_method;

  /// No description provided for @phone_number.
  ///
  /// In fr, this message translates to:
  /// **'Numéro de Téléphone'**
  String get phone_number;

  /// No description provided for @enter_number.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un numéro'**
  String get enter_number;

  /// No description provided for @iban.
  ///
  /// In fr, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// No description provided for @enter_iban.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un IBAN'**
  String get enter_iban;

  /// No description provided for @beneficiary_name.
  ///
  /// In fr, this message translates to:
  /// **'Nom du Bénéficiaire'**
  String get beneficiary_name;

  /// No description provided for @enter_name.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nom'**
  String get enter_name;

  /// No description provided for @confirm_withdrawal.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le Retrait'**
  String get confirm_withdrawal;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'a été effectuée avec succès'**
  String get success;

  /// No description provided for @payment_not_received.
  ///
  /// In fr, this message translates to:
  /// **'Paiement non reçu'**
  String get payment_not_received;

  /// No description provided for @claim_status_in_progress.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get claim_status_in_progress;

  /// No description provided for @payment_issue_desc.
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas été reçu pour cette commande.'**
  String get payment_issue_desc;

  /// No description provided for @high_priority.
  ///
  /// In fr, this message translates to:
  /// **'Haute priorité'**
  String get high_priority;

  /// No description provided for @video_rejected.
  ///
  /// In fr, this message translates to:
  /// **'Vidéo rejetée'**
  String get video_rejected;

  /// No description provided for @claim_status_resolved.
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get claim_status_resolved;

  /// No description provided for @rejection_issue_desc.
  ///
  /// In fr, this message translates to:
  /// **'La vidéo a été rejetée pour non-conformité.'**
  String get rejection_issue_desc;

  /// No description provided for @medium_priority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité moyenne'**
  String get medium_priority;

  /// No description provided for @rejection_response.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du support'**
  String get rejection_response;

  /// No description provided for @my_claims.
  ///
  /// In fr, this message translates to:
  /// **'Mes réclamations'**
  String get my_claims;

  /// No description provided for @search_claims.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des réclamations'**
  String get search_claims;

  /// No description provided for @support_response.
  ///
  /// In fr, this message translates to:
  /// **'Réponse du support'**
  String get support_response;

  /// No description provided for @new_claim.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réclamation'**
  String get new_claim;

  /// No description provided for @claim_title.
  ///
  /// In fr, this message translates to:
  /// **'Titre de la réclamation'**
  String get claim_title;

  /// No description provided for @required_field.
  ///
  /// In fr, this message translates to:
  /// **'Champ requis'**
  String get required_field;

  /// No description provided for @claim_description.
  ///
  /// In fr, this message translates to:
  /// **'Description de la réclamation'**
  String get claim_description;

  /// No description provided for @low_priority.
  ///
  /// In fr, this message translates to:
  /// **'Basse priorité'**
  String get low_priority;

  /// No description provided for @priority.
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get priority;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @submit.
  ///
  /// In fr, this message translates to:
  /// **'Soumettre'**
  String get submit;

  /// No description provided for @claim_submitted.
  ///
  /// In fr, this message translates to:
  /// **'Réclamation soumise avec succès'**
  String get claim_submitted;

  /// No description provided for @searchFilmHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un film...'**
  String get searchFilmHint;

  /// No description provided for @publishedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get publishedStatus;

  /// No description provided for @pendingStatus.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingStatus;

  /// No description provided for @rejectedStatus.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get rejectedStatus;

  /// No description provided for @synopsisTitle.
  ///
  /// In fr, this message translates to:
  /// **'📜 Synopsis'**
  String get synopsisTitle;

  /// No description provided for @informationTitle.
  ///
  /// In fr, this message translates to:
  /// **'🎬 Informations'**
  String get informationTitle;

  /// No description provided for @teamTitle.
  ///
  /// In fr, this message translates to:
  /// **'👨‍🎤 Équipe'**
  String get teamTitle;

  /// No description provided for @statsTitle.
  ///
  /// In fr, this message translates to:
  /// **'📊 Statistiques'**
  String get statsTitle;

  /// No description provided for @commentsTitle.
  ///
  /// In fr, this message translates to:
  /// **'💬 Commentaires'**
  String get commentsTitle;

  /// No description provided for @metadataTitle.
  ///
  /// In fr, this message translates to:
  /// **'💾 Métadonnées'**
  String get metadataTitle;

  /// No description provided for @editButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editButton;

  /// No description provided for @closeButton.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// No description provided for @mainActorsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Acteurs principaux'**
  String get mainActorsLabel;

  /// No description provided for @publicationHistoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Historique de publication'**
  String get publicationHistoryLabel;

  /// No description provided for @availableSubtitlesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres disponibles'**
  String get availableSubtitlesLabel;

  /// No description provided for @viewsLabel.
  ///
  /// In fr, this message translates to:
  /// **'vues'**
  String get viewsLabel;

  /// No description provided for @likesLabel.
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get likesLabel;

  /// No description provided for @commentsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get commentsLabel;

  /// No description provided for @ratingLabel.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get ratingLabel;

  /// No description provided for @yearLabel.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get yearLabel;

  /// No description provided for @resolutionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Résolution'**
  String get resolutionLabel;

  /// No description provided for @formatLabel.
  ///
  /// In fr, this message translates to:
  /// **'Format'**
  String get formatLabel;

  /// No description provided for @codecLabel.
  ///
  /// In fr, this message translates to:
  /// **'Codec'**
  String get codecLabel;

  /// No description provided for @minutesLabel.
  ///
  /// In fr, this message translates to:
  /// **'minutes'**
  String get minutesLabel;

  /// No description provided for @searchSeriesHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une série...'**
  String get searchSeriesHint;

  /// No description provided for @seasonsEpisodesTitle.
  ///
  /// In fr, this message translates to:
  /// **'📺 Saisons & Épisodes'**
  String get seasonsEpisodesTitle;

  /// No description provided for @addEpisodeButton.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un épisode'**
  String get addEpisodeButton;

  /// No description provided for @descriptionToComplete.
  ///
  /// In fr, this message translates to:
  /// **'Description à compléter'**
  String get descriptionToComplete;

  /// No description provided for @filtersToImplement.
  ///
  /// In fr, this message translates to:
  /// **'Filtres à implémenter'**
  String get filtersToImplement;

  /// No description provided for @usersTab.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get usersTab;

  /// No description provided for @producersTab.
  ///
  /// In fr, this message translates to:
  /// **'Producteurs'**
  String get producersTab;

  /// No description provided for @adminTab.
  ///
  /// In fr, this message translates to:
  /// **'Administrateurs'**
  String get adminTab;

  /// No description provided for @statisticsTab.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statisticsTab;

  /// No description provided for @recentVideos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos récentes'**
  String get recentVideos;

  /// No description provided for @recentPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements récents'**
  String get recentPayments;

  /// No description provided for @usersManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des utilisateurs'**
  String get usersManagement;

  /// No description provided for @addUser.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un utilisateur'**
  String get addUser;

  /// No description provided for @id.
  ///
  /// In fr, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @subscription.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement'**
  String get subscription;

  /// No description provided for @joinDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'inscription'**
  String get joinDate;

  /// No description provided for @actions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @searchUsers.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des utilisateurs'**
  String get searchUsers;

  /// No description provided for @producersManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des producteurs'**
  String get producersManagement;

  /// No description provided for @addProducer.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un producteur'**
  String get addProducer;

  /// No description provided for @searchProducers.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des producteurs'**
  String get searchProducers;

  /// No description provided for @allStatus.
  ///
  /// In fr, this message translates to:
  /// **'Tous les statuts'**
  String get allStatus;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactive;

  /// No description provided for @adminManagement.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des administrateurs'**
  String get adminManagement;

  /// No description provided for @addAdmin.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un administrateur'**
  String get addAdmin;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @lastLogin.
  ///
  /// In fr, this message translates to:
  /// **'Dernière connexion'**
  String get lastLogin;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @producers.
  ///
  /// In fr, this message translates to:
  /// **'Producteurs'**
  String get producers;

  /// No description provided for @videos.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos'**
  String get videos;

  /// No description provided for @earnings.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get earnings;

  /// No description provided for @usersGrowth.
  ///
  /// In fr, this message translates to:
  /// **'Croissance des utilisateurs'**
  String get usersGrowth;

  /// No description provided for @videosByStatus.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos par statut'**
  String get videosByStatus;

  /// No description provided for @daily.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get weekly;

  /// No description provided for @monthly.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel'**
  String get monthly;

  /// No description provided for @yearly.
  ///
  /// In fr, this message translates to:
  /// **'Annuel'**
  String get yearly;

  /// No description provided for @adminDashboardTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord administrateur'**
  String get adminDashboardTitle;

  /// No description provided for @totalUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs totaux'**
  String get totalUsers;

  /// No description provided for @activeProducers.
  ///
  /// In fr, this message translates to:
  /// **'Producteurs actifs'**
  String get activeProducers;

  /// No description provided for @videosToReview.
  ///
  /// In fr, this message translates to:
  /// **'Vidéos à examiner'**
  String get videosToReview;

  /// No description provided for @monthlyRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenu mensuel'**
  String get monthlyRevenue;

  /// No description provided for @platformActivity.
  ///
  /// In fr, this message translates to:
  /// **'Activité de la plateforme'**
  String get platformActivity;

  /// No description provided for @newVideoSubmitted.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle vidéo soumise'**
  String get newVideoSubmitted;

  /// No description provided for @paymentRequest.
  ///
  /// In fr, this message translates to:
  /// **'Demande de paiement'**
  String get paymentRequest;

  /// No description provided for @totalVideos.
  ///
  /// In fr, this message translates to:
  /// **'Total vidéos'**
  String get totalVideos;

  /// No description provided for @noUsersFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur trouvé'**
  String get noUsersFound;

  /// No description provided for @editUser.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'utilisateur'**
  String get editUser;

  /// No description provided for @update.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get update;

  /// No description provided for @deleteUser.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'utilisateur'**
  String get deleteUser;

  /// No description provided for @deleteUserConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cet utilisateur ?'**
  String get deleteUserConfirmation;

  /// No description provided for @userDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur supprimé avec succès'**
  String get userDeleted;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pending;

  /// No description provided for @nameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est requis'**
  String get nameRequired;

  /// No description provided for @emailRequired.
  ///
  /// In fr, this message translates to:
  /// **'L\'email est requis'**
  String get emailRequired;

  /// No description provided for @invalidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Adresse email invalide'**
  String get invalidEmail;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @country.
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get country;

  /// No description provided for @transactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @linkedProfiles.
  ///
  /// In fr, this message translates to:
  /// **'Profils liés'**
  String get linkedProfiles;

  /// No description provided for @subscriptionStart.
  ///
  /// In fr, this message translates to:
  /// **'Début de l\'abonnement'**
  String get subscriptionStart;

  /// No description provided for @subscriptionEnd.
  ///
  /// In fr, this message translates to:
  /// **'Fin de l\'abonnement'**
  String get subscriptionEnd;

  /// No description provided for @transactionsHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des transactions'**
  String get transactionsHistory;

  /// No description provided for @noTransactions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune transaction'**
  String get noTransactions;

  /// No description provided for @completed.
  ///
  /// In fr, this message translates to:
  /// **'Complété'**
  String get completed;

  /// No description provided for @failed.
  ///
  /// In fr, this message translates to:
  /// **'Échoué'**
  String get failed;

  /// No description provided for @refunded.
  ///
  /// In fr, this message translates to:
  /// **'Remboursé'**
  String get refunded;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @generatePassword.
  ///
  /// In fr, this message translates to:
  /// **'Générer mot de passe'**
  String get generatePassword;

  /// No description provided for @producerName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du producteur'**
  String get producerName;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @generateNewPassword.
  ///
  /// In fr, this message translates to:
  /// **'Générer un nouveau mot de passe'**
  String get generateNewPassword;

  /// No description provided for @enterName.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un nom'**
  String get enterName;

  /// No description provided for @enterValidEmail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un email valide'**
  String get enterValidEmail;

  /// No description provided for @enterPhone.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un numéro de téléphone'**
  String get enterPhone;

  /// No description provided for @regeneratePassword.
  ///
  /// In fr, this message translates to:
  /// **'Générer un mot de passe'**
  String get regeneratePassword;

  /// No description provided for @financialCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'accès financier'**
  String get financialCode;

  /// No description provided for @generateCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Générer un code à 4 chiffres'**
  String get generateCodeHint;

  /// No description provided for @generate.
  ///
  /// In fr, this message translates to:
  /// **'Générer'**
  String get generate;

  /// No description provided for @codeValidForXMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Code valable %d minutes'**
  String get codeValidForXMinutes;

  /// No description provided for @claim_status_rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejetée'**
  String get claim_status_rejected;

  /// No description provided for @group_response_subject.
  ///
  /// In fr, this message translates to:
  /// **'Objet de la réponse groupée'**
  String get group_response_subject;

  /// No description provided for @individual_response_subject.
  ///
  /// In fr, this message translates to:
  /// **'Objet de la réponse individuelle'**
  String get individual_response_subject;

  /// No description provided for @send_group_email.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un email groupé'**
  String get send_group_email;

  /// No description provided for @send_individual_email.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer un email individuel'**
  String get send_individual_email;

  /// No description provided for @subject.
  ///
  /// In fr, this message translates to:
  /// **'Sujet'**
  String get subject;

  /// No description provided for @message.
  ///
  /// In fr, this message translates to:
  /// **'Message'**
  String get message;

  /// No description provided for @send.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer'**
  String get send;

  /// No description provided for @claims_management.
  ///
  /// In fr, this message translates to:
  /// **'Gestion des réclamations'**
  String get claims_management;

  /// No description provided for @all_statuses.
  ///
  /// In fr, this message translates to:
  /// **'Tous les statuts'**
  String get all_statuses;

  /// No description provided for @filter_by_status.
  ///
  /// In fr, this message translates to:
  /// **'Filtrer par statut'**
  String get filter_by_status;

  /// No description provided for @attachments.
  ///
  /// In fr, this message translates to:
  /// **'Pièces jointes'**
  String get attachments;

  /// No description provided for @response.
  ///
  /// In fr, this message translates to:
  /// **'Réponse'**
  String get response;

  /// No description provided for @enter_response.
  ///
  /// In fr, this message translates to:
  /// **'Entrez votre réponse'**
  String get enter_response;

  /// No description provided for @no_claims_found.
  ///
  /// In fr, this message translates to:
  /// **'Aucune réclamation trouvée'**
  String get no_claims_found;

  /// No description provided for @communication_tooltip.
  ///
  /// In fr, this message translates to:
  /// **'Envoyer une communication'**
  String get communication_tooltip;

  /// No description provided for @communication_title.
  ///
  /// In fr, this message translates to:
  /// **'Communication'**
  String get communication_title;

  /// No description provided for @communication_type.
  ///
  /// In fr, this message translates to:
  /// **'Type de communication'**
  String get communication_type;

  /// No description provided for @notification.
  ///
  /// In fr, this message translates to:
  /// **'Notification'**
  String get notification;

  /// No description provided for @sending_mode.
  ///
  /// In fr, this message translates to:
  /// **'Mode d’envoi'**
  String get sending_mode;

  /// No description provided for @individual.
  ///
  /// In fr, this message translates to:
  /// **'Individuel'**
  String get individual;

  /// No description provided for @group.
  ///
  /// In fr, this message translates to:
  /// **'Groupe'**
  String get group;

  /// No description provided for @selected_recipients.
  ///
  /// In fr, this message translates to:
  /// **'destinataires sélectionnés'**
  String get selected_recipients;

  /// No description provided for @confirm_send.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer l’envoi'**
  String get confirm_send;

  /// No description provided for @confirm_group_email.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous envoyer un email à {count} destinataires ?'**
  String confirm_group_email(Object count);

  /// No description provided for @confirm_individual_email.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous envoyer un email à ce destinataire ?'**
  String get confirm_individual_email;

  /// No description provided for @confirm_notification.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous envoyer une notification à {count} destinataires ?'**
  String confirm_notification(Object count);

  /// No description provided for @email_sent.
  ///
  /// In fr, this message translates to:
  /// **'Email envoyé avec succès'**
  String get email_sent;

  /// No description provided for @notification_sent.
  ///
  /// In fr, this message translates to:
  /// **'Notification envoyée avec succès'**
  String get notification_sent;

  /// No description provided for @email_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’envoi de l’email'**
  String get email_error;

  /// No description provided for @notification_error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l’envoi de la notification'**
  String get notification_error;

  /// No description provided for @withdrawal_requests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de Retrait'**
  String get withdrawal_requests;

  /// No description provided for @method.
  ///
  /// In fr, this message translates to:
  /// **'Méthode'**
  String get method;

  /// No description provided for @reject.
  ///
  /// In fr, this message translates to:
  /// **'Rejeter'**
  String get reject;

  /// No description provided for @approve.
  ///
  /// In fr, this message translates to:
  /// **'Approuver'**
  String get approve;

  /// No description provided for @approved.
  ///
  /// In fr, this message translates to:
  /// **'Approuvé'**
  String get approved;

  /// No description provided for @rejected.
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get rejected;

  /// No description provided for @processed_on.
  ///
  /// In fr, this message translates to:
  /// **'Traité le'**
  String get processed_on;

  /// No description provided for @revenue_details.
  ///
  /// In fr, this message translates to:
  /// **'Détails des Revenus'**
  String get revenue_details;

  /// No description provided for @producer.
  ///
  /// In fr, this message translates to:
  /// **'Producteur'**
  String get producer;

  /// No description provided for @views.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get views;

  /// No description provided for @revenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus'**
  String get revenue;

  /// No description provided for @monthly_revenue.
  ///
  /// In fr, this message translates to:
  /// **'Revenus par mois'**
  String get monthly_revenue;

  /// No description provided for @streaming_analytics.
  ///
  /// In fr, this message translates to:
  /// **'Analytique Streaming'**
  String get streaming_analytics;

  /// No description provided for @time_period.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get time_period;

  /// No description provided for @content_type.
  ///
  /// In fr, this message translates to:
  /// **'Type de Contenu'**
  String get content_type;

  /// No description provided for @all_content.
  ///
  /// In fr, this message translates to:
  /// **'Tous Contenus'**
  String get all_content;

  /// No description provided for @movies.
  ///
  /// In fr, this message translates to:
  /// **'Films'**
  String get movies;

  /// No description provided for @series.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get series;

  /// No description provided for @documentaries.
  ///
  /// In fr, this message translates to:
  /// **'Documentaires'**
  String get documentaries;

  /// No description provided for @new_users.
  ///
  /// In fr, this message translates to:
  /// **'Nouveaux'**
  String get new_users;

  /// No description provided for @returning_users.
  ///
  /// In fr, this message translates to:
  /// **'Récurrents'**
  String get returning_users;

  /// No description provided for @premium.
  ///
  /// In fr, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @trial.
  ///
  /// In fr, this message translates to:
  /// **'Essai'**
  String get trial;

  /// No description provided for @total_viewers.
  ///
  /// In fr, this message translates to:
  /// **'Spectateurs Totaux'**
  String get total_viewers;

  /// No description provided for @watch_time.
  ///
  /// In fr, this message translates to:
  /// **'Temps de Visionnage'**
  String get watch_time;

  /// No description provided for @avg_session.
  ///
  /// In fr, this message translates to:
  /// **'Session Moyenne'**
  String get avg_session;

  /// No description provided for @viewership_trends.
  ///
  /// In fr, this message translates to:
  /// **'Tendances Audience'**
  String get viewership_trends;

  /// No description provided for @content_performance.
  ///
  /// In fr, this message translates to:
  /// **'Performance Contenus'**
  String get content_performance;

  /// No description provided for @user_engagement.
  ///
  /// In fr, this message translates to:
  /// **'Engagement Utilisateurs'**
  String get user_engagement;

  /// No description provided for @geo_distribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition Géographique'**
  String get geo_distribution;

  /// No description provided for @user_growth.
  ///
  /// In fr, this message translates to:
  /// **'Croissance utilisateurs'**
  String get user_growth;

  /// No description provided for @video_status_distribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition des vidéos par statut'**
  String get video_status_distribution;

  /// No description provided for @avg_watch_time.
  ///
  /// In fr, this message translates to:
  /// **'Temps moyen de visionnage'**
  String get avg_watch_time;

  /// No description provided for @popular_genres.
  ///
  /// In fr, this message translates to:
  /// **'Genres les plus regardés'**
  String get popular_genres;

  /// No description provided for @subscriber_retention.
  ///
  /// In fr, this message translates to:
  /// **'Taux de rétention des abonnés'**
  String get subscriber_retention;

  /// No description provided for @devices_used.
  ///
  /// In fr, this message translates to:
  /// **'Appareils utilisés'**
  String get devices_used;

  /// No description provided for @published.
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get published;

  /// No description provided for @draft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get draft;

  /// No description provided for @archived.
  ///
  /// In fr, this message translates to:
  /// **'Archivé'**
  String get archived;
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
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
