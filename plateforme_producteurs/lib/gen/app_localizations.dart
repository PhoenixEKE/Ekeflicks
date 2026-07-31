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

  /// Texte du bouton de mise à jour
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

  /// Titre général pour la confidentialité
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

  /// Message d'erreur lorsque les mots de passe ne correspondent pas
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

  /// Option pour rendre l'email public
  ///
  /// In fr, this message translates to:
  /// **'Afficher mon email publiquement'**
  String get showEmailPublic;

  /// Description de l'option d'affichage public de l'email
  ///
  /// In fr, this message translates to:
  /// **'Les autres utilisateurs pourront voir votre email sur votre profil.'**
  String get showEmailPublicDescription;

  /// Option pour activer la 2FA
  ///
  /// In fr, this message translates to:
  /// **'Activer l\'authentification à deux facteurs'**
  String get enableTwoFactorAuth;

  /// Description de la 2FA
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une couche de sécurité supplémentaire lors de la connexion.'**
  String get enableTwoFactorAuthDescription;

  /// Bouton pour sauvegarder les paramètres
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer les paramètres'**
  String get saveSettings;

  /// Message affiché après sauvegarde des paramètres
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés'**
  String get settingsSaved;

  /// Description générale en haut de la page paramètres de confidentialité
  ///
  /// In fr, this message translates to:
  /// **'Gérez vos préférences en matière de confidentialité et de collecte de données.'**
  String get privacySettingsDescription;

  /// Option pour accepter le suivi analytique
  ///
  /// In fr, this message translates to:
  /// **'Accepter le suivi analytique'**
  String get acceptAnalyticsTracking;

  /// Texte explicatif du suivi analytique
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

  /// Erreur affichée si aucune app mail n'est disponible
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'ouvrir l\'application de messagerie.'**
  String get emailLaunchError;

  /// Titre de la page Aide & Support
  ///
  /// In fr, this message translates to:
  /// **'Aide & Support'**
  String get helpSupportTitle;

  /// Titre du centre d'aide
  ///
  /// In fr, this message translates to:
  /// **'Centre d\'aide Ephrata'**
  String get helpCenterTitle;

  /// Titre de la section tutoriels vidéo
  ///
  /// In fr, this message translates to:
  /// **'Tutoriels vidéo'**
  String get videoTutorialsTitle;

  /// Titre tuto vidéo 1
  ///
  /// In fr, this message translates to:
  /// **'Comment créer un profil'**
  String get helpSupportVideo1Title;

  /// Titre tuto vidéo 2
  ///
  /// In fr, this message translates to:
  /// **'Ajouter vos produits'**
  String get helpSupportVideo2Title;

  /// Titre tuto vidéo 3
  ///
  /// In fr, this message translates to:
  /// **'Gérer vos commandes'**
  String get helpSupportVideo3Title;

  /// Titre de la FAQ
  ///
  /// In fr, this message translates to:
  /// **'Questions fréquentes'**
  String get faqTitle;

  /// FAQ question 1
  ///
  /// In fr, this message translates to:
  /// **'Comment modifier mes informations?'**
  String get helpSupportFaq1Question;

  /// FAQ réponse 1
  ///
  /// In fr, this message translates to:
  /// **'Allez dans Paramètres > Mon compte'**
  String get helpSupportFaq1Answer;

  /// FAQ question 2
  ///
  /// In fr, this message translates to:
  /// **'Problème de connexion?'**
  String get helpSupportFaq2Question;

  /// FAQ réponse 2
  ///
  /// In fr, this message translates to:
  /// **'Réinitialisez votre mot de passe'**
  String get helpSupportFaq2Answer;

  /// Titre de contact support
  ///
  /// In fr, this message translates to:
  /// **'Contactez notre support'**
  String get contactSupportTitle;

  /// Label email support
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// Email du support
  ///
  /// In fr, this message translates to:
  /// **'support@ephrata.com'**
  String get contactEmail;

  /// Label téléphone France
  ///
  /// In fr, this message translates to:
  /// **'Téléphone France'**
  String get contactPhoneFrLabel;

  /// Téléphone France
  ///
  /// In fr, this message translates to:
  /// **'+33 6 83 63 70 52'**
  String get contactPhoneFr;

  /// Label téléphone CI
  ///
  /// In fr, this message translates to:
  /// **'Téléphone Côte d\'Ivoire'**
  String get contactPhoneCiLabel;

  /// Téléphone CI
  ///
  /// In fr, this message translates to:
  /// **'+225 05 86 75 89 89'**
  String get contactPhoneCi;

  /// Label WhatsApp
  ///
  /// In fr, this message translates to:
  /// **'WhatsApp'**
  String get contactWhatsAppLabel;

  /// Numéro WhatsApp
  ///
  /// In fr, this message translates to:
  /// **'+225 05 86 75 86 96'**
  String get contactWhatsApp;

  /// Titre page login
  ///
  /// In fr, this message translates to:
  /// **'CONNEXION PRODUCTEUR'**
  String get loginPageTitle;

  /// Label email login
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label password login
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get passwordLabel;

  /// Bouton login
  ///
  /// In fr, this message translates to:
  /// **'SE CONNECTER'**
  String get loginButton;

  /// Lien mot de passe oublié
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// Erreur email invalide
  ///
  /// In fr, this message translates to:
  /// **'Email invalide'**
  String get emailValidationError;

  /// Erreur mot de passe trop court
  ///
  /// In fr, this message translates to:
  /// **'Minimum 6 caractères'**
  String get passwordValidationError;

  /// Bouton changer langue
  ///
  /// In fr, this message translates to:
  /// **'Changer la langue'**
  String get changeLanguage;

  /// Tab dashboard
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTab;

  /// Tab films
  ///
  /// In fr, this message translates to:
  /// **'Films'**
  String get moviesTab;

  /// Tab séries
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get seriesTab;

  /// Tab upload
  ///
  /// In fr, this message translates to:
  /// **'Dépôt'**
  String get uploadTab;

  /// Tab finances
  ///
  /// In fr, this message translates to:
  /// **'Finances'**
  String get financeTab;

  /// Tab support
  ///
  /// In fr, this message translates to:
  /// **'Support'**
  String get supportTab;

  /// Tab profil
  ///
  /// In fr, this message translates to:
  /// **'Mon compte'**
  String get profileTab;

  /// Bouton déconnexion
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get logout;

  /// Titre notifications
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Notification nouveau commentaire
  ///
  /// In fr, this message translates to:
  /// **'Nouveau commentaire'**
  String get notificationNewComment;

  /// Notification sur un contenu
  ///
  /// In fr, this message translates to:
  /// **'Sur \"{content}\"'**
  String notificationOnContent(Object content);

  /// Notification paiement reçu
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu'**
  String get notificationPayment;

  /// Texte hier
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// Bouton fermer
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// Titre dashboard
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboardTitle;

  /// Label vidéos publiées
  ///
  /// In fr, this message translates to:
  /// **'Vidéos publiées'**
  String get publishedVideos;

  /// Label vues totales
  ///
  /// In fr, this message translates to:
  /// **'Vues totales'**
  String get totalViews;

  /// Label revenus estimés
  ///
  /// In fr, this message translates to:
  /// **'Revenus estimés'**
  String get estimatedRevenue;

  /// Label en attente
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingItems;

  /// Label abonnés
  ///
  /// In fr, this message translates to:
  /// **'Abonnés'**
  String get subscribers;

  /// Label taux d'engagement
  ///
  /// In fr, this message translates to:
  /// **'Taux d\'engagement'**
  String get engagementRate;

  /// Label activité récente
  ///
  /// In fr, this message translates to:
  /// **'Activité récente'**
  String get recentActivity;

  /// Notification nouvelle vidéo
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle vidéo publiée'**
  String get newVideoPublished;

  /// Titre de la vidéo avec variable
  ///
  /// In fr, this message translates to:
  /// **'Vidéo : {title}'**
  String videoTitle(Object title);

  /// Notification paiement reçu
  ///
  /// In fr, this message translates to:
  /// **'Paiement reçu'**
  String get paymentReceived;

  /// Texte il y a X temps
  ///
  /// In fr, this message translates to:
  /// **'Il y a {count} {unit}'**
  String timeAgo(Object count, Object unit);

  /// Unité de temps heure
  ///
  /// In fr, this message translates to:
  /// **'heure'**
  String get hour;

  /// Unité de temps heures
  ///
  /// In fr, this message translates to:
  /// **'heures'**
  String get hours;

  /// Titre formulaire upload vidéo
  ///
  /// In fr, this message translates to:
  /// **'Formulaire Upload Vidéo'**
  String get uploadFormTitle;

  /// Label type contenu
  ///
  /// In fr, this message translates to:
  /// **'Type de contenu'**
  String get contentTypeLabel;

  /// Label titre
  ///
  /// In fr, this message translates to:
  /// **'Titre'**
  String get titleLabel;

  /// Label description
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionLabel;

  /// Label genres film
  ///
  /// In fr, this message translates to:
  /// **'Genre(s)'**
  String get genresLabel;

  /// Label langue
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabel;

  /// Label préciser langue
  ///
  /// In fr, this message translates to:
  /// **'Précisez la langue'**
  String get languageSpecifyLabel;

  /// Label pays
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get countryLabel;

  /// Option autres pays/langues
  ///
  /// In fr, this message translates to:
  /// **'Autres'**
  String get otherOption;

  /// Label préciser pays
  ///
  /// In fr, this message translates to:
  /// **'Précisez le pays'**
  String get countrySpecifyLabel;

  /// Label année sortie
  ///
  /// In fr, this message translates to:
  /// **'Année de sortie'**
  String get releaseYearLabel;

  /// Titre équipe production
  ///
  /// In fr, this message translates to:
  /// **'Équipe de production'**
  String get productionTeamTitle;

  /// Label réalisateur
  ///
  /// In fr, this message translates to:
  /// **'Nom du réalisateur'**
  String get directorLabel;

  /// Label scénariste
  ///
  /// In fr, this message translates to:
  /// **'Nom du scénariste'**
  String get screenwriterLabel;

  /// Label producteurs
  ///
  /// In fr, this message translates to:
  /// **'Producteurs'**
  String get producersLabel;

  /// Label acteurs
  ///
  /// In fr, this message translates to:
  /// **'Acteurs'**
  String get actorsLabel;

  /// Titre gestion des saisons
  ///
  /// In fr, this message translates to:
  /// **'Gestion des saisons'**
  String get seasonManagementTitle;

  /// Label saisons
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get seasonsLabel;

  /// Label saison
  ///
  /// In fr, this message translates to:
  /// **'Saison'**
  String get seasonLabel;

  /// Label épisodes
  ///
  /// In fr, this message translates to:
  /// **'Episodes'**
  String get episodesLabel;

  /// Label épisode
  ///
  /// In fr, this message translates to:
  /// **'Episode'**
  String get episodeLabel;

  /// Label bande annonce
  ///
  /// In fr, this message translates to:
  /// **'Bande annonce'**
  String get trailerLabel;

  /// Titre fichiers multimédias
  ///
  /// In fr, this message translates to:
  /// **'Fichiers multimédias'**
  String get mediaFilesTitle;

  /// Label poster
  ///
  /// In fr, this message translates to:
  /// **'Poster'**
  String get posterLabel;

  /// Label bannière
  ///
  /// In fr, this message translates to:
  /// **'Bannière'**
  String get bannerLabel;

  /// Label vidéo principale
  ///
  /// In fr, this message translates to:
  /// **'Vidéo principale'**
  String get mainVideoLabel;

  /// Titre ajouter producteur
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un producteur'**
  String get addProducerTitle;

  /// Titre ajouter acteur
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un acteur'**
  String get addActorTitle;

  /// Label nom
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nameLabel;

  /// Bouton ajouter image
  ///
  /// In fr, this message translates to:
  /// **'Ajouter image'**
  String get addImageButton;

  /// Bouton annuler
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancelButton;

  /// Bouton ajouter
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get addButton;

  /// Bouton supprimer
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteButton;

  /// Erreur champ requis
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est requis'**
  String get requiredFieldError;

  /// Erreur validation formulaire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir correctement le formulaire'**
  String get formValidationError;

  /// Erreur genre obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner au moins un genre'**
  String get genreSelectionError;

  /// Erreur langue obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner la langue'**
  String get languageSelectionError;

  /// Erreur préciser langue
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser la langue'**
  String get languageSpecifyError;

  /// Erreur pays obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un pays'**
  String get countrySelectionError;

  /// Erreur préciser pays
  ///
  /// In fr, this message translates to:
  /// **'Veuillez préciser le pays'**
  String get countrySpecifyError;

  /// Erreur année obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner l\'année de sortie'**
  String get yearSelectionError;

  /// Erreur nom réalisateur
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom du réalisateur'**
  String get directorNameError;

  /// Erreur nom scénariste
  ///
  /// In fr, this message translates to:
  /// **'Veuillez renseigner le nom du scénariste'**
  String get screenwriterNameError;

  /// Erreur poster obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une image poster'**
  String get posterSelectionError;

  /// Erreur bannière obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une image banner'**
  String get bannerSelectionError;

  /// Erreur vidéo obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une vidéo'**
  String get videoSelectionError;

  /// Erreur saison obligatoire
  ///
  /// In fr, this message translates to:
  /// **'Veuillez ajouter au moins une saison pour une série'**
  String get seasonSelectionError;

  /// Erreur validation saisons/épisodes
  ///
  /// In fr, this message translates to:
  /// **'Veuillez compléter toutes les saisons et épisodes'**
  String get seasonValidationError;

  /// Message succès formulaire
  ///
  /// In fr, this message translates to:
  /// **'Formulaire soumis avec succès !'**
  String get formSubmissionSuccess;

  /// Bouton soumettre
  ///
  /// In fr, this message translates to:
  /// **'Soumettre le formulaire'**
  String get submitButton;

  /// Bouton ajouter saison
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une saison'**
  String get addSeasonButton;

  /// Bouton ajouter bande-annonce
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une bande-annonce'**
  String get addTrailerButton;

  /// Bouton ajouter poster
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Poster'**
  String get addPosterButton;

  /// Bouton ajouter bannière
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Bannière'**
  String get addBannerButton;

  /// Bouton ajouter vidéo
  ///
  /// In fr, this message translates to:
  /// **'Ajouter Vidéo'**
  String get addVideoButton;

  /// Label description saison
  ///
  /// In fr, this message translates to:
  /// **'Description de la saison'**
  String get seasonDescriptionLabel;

  /// Label description épisode
  ///
  /// In fr, this message translates to:
  /// **'Description de l\'épisode'**
  String get episodeDescriptionLabel;

  /// Label bande-annonce saison
  ///
  /// In fr, this message translates to:
  /// **'Bande-annonce de la saison'**
  String get seasonTrailerLabel;

  /// Bouton ajouter poster saison
  ///
  /// In fr, this message translates to:
  /// **'Ajouter poster (saison)'**
  String get addSeasonPosterButton;

  /// Bouton ajouter bannière saison
  ///
  /// In fr, this message translates to:
  /// **'Ajouter bannière (saison)'**
  String get addSeasonBannerButton;

  /// Tooltip ajouter épisode
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un épisode'**
  String get addEpisodeTooltip;

  /// Tooltip supprimer saison
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la saison'**
  String get removeSeasonTooltip;

  /// Titre du dialogue de confirmation
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmationTitle;

  /// Message confirmation suppression
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous supprimer cet élément ?'**
  String get confirmationMessage;

  /// Hint titre
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'épisode'**
  String get titleHint;

  /// Texte sélection vidéo d'abord
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une vidéo d\'abord'**
  String get selectVideoFirst;

  /// Texte ajouter saison
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une saison'**
  String get addSeason;

  /// Label titre saison
  ///
  /// In fr, this message translates to:
  /// **'Titre de la saison'**
  String get seasonTitleLabel;

  /// Hint titre saison
  ///
  /// In fr, this message translates to:
  /// **'Ex: Saison 3'**
  String get seasonTitleHint;

  /// Titre pour le modal d'ajout d'épisode
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un épisode (Saison {seasonNumber})'**
  String addEpisode(Object seasonNumber);

  /// Tab détails
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get detailsTab;

  /// Tab vidéo
  ///
  /// In fr, this message translates to:
  /// **'Vidéo'**
  String get videoTab;

  /// Label titre épisode
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'épisode'**
  String get episodeTitleLabel;

  /// Hint titre épisode
  ///
  /// In fr, this message translates to:
  /// **'Titre de l\'épisode'**
  String get episodeTitleHint;

  /// Label durée
  ///
  /// In fr, this message translates to:
  /// **'Durée (minutes)'**
  String get durationLabel;

  /// Texte fichier sélectionné
  ///
  /// In fr, this message translates to:
  /// **'Fichier sélectionné'**
  String get selectedFile;

  /// Bouton upload vidéo
  ///
  /// In fr, this message translates to:
  /// **'Télécharger la vidéo'**
  String get uploadVideo;

  /// Texte sélectionner vidéo
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une vidéo'**
  String get selectVideoPrompt;

  /// Texte champ requis
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire'**
  String get requiredField;

  /// Erreur nombre invalide
  ///
  /// In fr, this message translates to:
  /// **'Nombre invalide'**
  String get invalidNumber;

  /// Bouton ajouter
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// Titre accès sécurisé
  ///
  /// In fr, this message translates to:
  /// **'Accès sécurisé'**
  String get secure_access;

  /// Texte entrer pin finances
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer votre code PIN pour accéder à vos finances.'**
  String get enter_pin;

  /// Erreur code invalide
  ///
  /// In fr, this message translates to:
  /// **'Code invalide'**
  String get invalid_code;

  /// Bouton valider
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// Titre finances
  ///
  /// In fr, this message translates to:
  /// **'Mes finances'**
  String get my_finances;

  /// Label solde disponible
  ///
  /// In fr, this message translates to:
  /// **'Solde disponible'**
  String get available_balance;

  /// Label dernier retrait
  ///
  /// In fr, this message translates to:
  /// **'Dernier retrait'**
  String get last_withdrawal;

  /// Label date
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// Label paiements en attente
  ///
  /// In fr, this message translates to:
  /// **'Paiements en attente'**
  String get pending_payments;

  /// Texte disponible 48h
  ///
  /// In fr, this message translates to:
  /// **'Disponible dans 48h'**
  String get available_in_48h;

  /// Bouton demander retrait
  ///
  /// In fr, this message translates to:
  /// **'Demander un retrait'**
  String get request_withdrawal;

  /// Titre demande retrait
  ///
  /// In fr, this message translates to:
  /// **'Demande de retrait'**
  String get withdrawal_request;

  /// Label montant
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// Texte saisir montant
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir un montant'**
  String get enter_amount;

  /// Erreur montant positif
  ///
  /// In fr, this message translates to:
  /// **'Le montant doit être positif'**
  String get amount_positive;

  /// Erreur montant dépasse solde
  ///
  /// In fr, this message translates to:
  /// **'Le montant dépasse le solde disponible ({balance} €)'**
  String amount_exceeds_balance(Object balance);

  /// Label méthode paiement
  ///
  /// In fr, this message translates to:
  /// **'Méthode de paiement'**
  String get payment_method;

  /// Label numéro tel retrait
  ///
  /// In fr, this message translates to:
  /// **'Numéro de téléphone'**
  String get phone_number;

  /// Texte saisir numéro tel
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir votre numéro'**
  String get enter_number;

  /// Label IBAN
  ///
  /// In fr, this message translates to:
  /// **'IBAN'**
  String get iban;

  /// Texte saisir IBAN
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir l\'IBAN'**
  String get enter_iban;

  /// Label nom bénéficiaire
  ///
  /// In fr, this message translates to:
  /// **'Nom du bénéficiaire'**
  String get beneficiary_name;

  /// Texte saisir nom
  ///
  /// In fr, this message translates to:
  /// **'Veuillez saisir le nom'**
  String get enter_name;

  /// Bouton confirmer retrait
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le retrait'**
  String get confirm_withdrawal;

  /// Texte succès
  ///
  /// In fr, this message translates to:
  /// **'réussi'**
  String get success;

  /// Titre réclamation paiement non reçu
  ///
  /// In fr, this message translates to:
  /// **'Paiement non reçu'**
  String get payment_not_received;

  /// Statut réclamation en cours
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get claim_status_in_progress;

  /// Description réclamation paiement
  ///
  /// In fr, this message translates to:
  /// **'Le paiement n\'a pas été reçu pour cette commande.'**
  String get payment_issue_desc;

  /// Priorité haute
  ///
  /// In fr, this message translates to:
  /// **'Haute priorité'**
  String get high_priority;

  /// Réclamation vidéo rejetée
  ///
  /// In fr, this message translates to:
  /// **'Vidéo rejetée'**
  String get video_rejected;

  /// Statut réclamation résolu
  ///
  /// In fr, this message translates to:
  /// **'Résolu'**
  String get claim_status_resolved;

  /// Description vidéo rejetée
  ///
  /// In fr, this message translates to:
  /// **'La vidéo a été rejetée pour non-conformité.'**
  String get rejection_issue_desc;

  /// Priorité moyenne
  ///
  /// In fr, this message translates to:
  /// **'Priorité moyenne'**
  String get medium_priority;

  /// Titre réponse support
  ///
  /// In fr, this message translates to:
  /// **'Réponse du support'**
  String get rejection_response;

  /// Titre mes réclamations
  ///
  /// In fr, this message translates to:
  /// **'Mes réclamations'**
  String get my_claims;

  /// Champ recherche réclamations
  ///
  /// In fr, this message translates to:
  /// **'Rechercher des réclamations'**
  String get search_claims;

  /// Label réponse support
  ///
  /// In fr, this message translates to:
  /// **'Réponse du support'**
  String get support_response;

  /// Bouton nouvelle réclamation
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle réclamation'**
  String get new_claim;

  /// Label titre réclamation
  ///
  /// In fr, this message translates to:
  /// **'Titre de la réclamation'**
  String get claim_title;

  /// Label description réclamation
  ///
  /// In fr, this message translates to:
  /// **'Description de la réclamation'**
  String get claim_description;

  /// Priorité basse
  ///
  /// In fr, this message translates to:
  /// **'Basse priorité'**
  String get low_priority;

  /// Label priorité
  ///
  /// In fr, this message translates to:
  /// **'Priorité'**
  String get priority;

  /// Label statut
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// Label description générique
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// Bouton soumettre
  ///
  /// In fr, this message translates to:
  /// **'Soumettre'**
  String get submit;

  /// Message succès réclamation
  ///
  /// In fr, this message translates to:
  /// **'Réclamation soumise avec succès'**
  String get claim_submitted;

  /// Hint recherche film
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un film...'**
  String get searchFilmHint;

  /// Statut publié
  ///
  /// In fr, this message translates to:
  /// **'Publié'**
  String get publishedStatus;

  /// Statut en attente
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get pendingStatus;

  /// Statut rejeté
  ///
  /// In fr, this message translates to:
  /// **'Rejeté'**
  String get rejectedStatus;

  /// Titre Synopsis
  ///
  /// In fr, this message translates to:
  /// **'📜 Synopsis'**
  String get synopsisTitle;

  /// Titre informations
  ///
  /// In fr, this message translates to:
  /// **'🎬 Informations'**
  String get informationTitle;

  /// Titre équipe
  ///
  /// In fr, this message translates to:
  /// **'👨‍🎤 Équipe'**
  String get teamTitle;

  /// Titre statistiques
  ///
  /// In fr, this message translates to:
  /// **'📊 Statistiques'**
  String get statsTitle;

  /// Titre commentaires
  ///
  /// In fr, this message translates to:
  /// **'💬 Commentaires récents'**
  String get commentsTitle;

  /// Titre métadonnées
  ///
  /// In fr, this message translates to:
  /// **'💾 Métadonnées'**
  String get metadataTitle;

  /// Bouton modifier
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get editButton;

  /// Bouton fermer
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeButton;

  /// Label acteurs principaux
  ///
  /// In fr, this message translates to:
  /// **'Acteurs principaux'**
  String get mainActorsLabel;

  /// Label historique publication
  ///
  /// In fr, this message translates to:
  /// **'Historique de publication'**
  String get publicationHistoryLabel;

  /// Label sous-titres
  ///
  /// In fr, this message translates to:
  /// **'Sous-titres disponibles'**
  String get availableSubtitlesLabel;

  /// Label vues
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get viewsLabel;

  /// Label likes
  ///
  /// In fr, this message translates to:
  /// **'Likes'**
  String get likesLabel;

  /// Label commentaires
  ///
  /// In fr, this message translates to:
  /// **'Commentaires'**
  String get commentsLabel;

  /// Label note
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get ratingLabel;

  /// Label langue film
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get languageLabelFilm;

  /// Label année film
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get yearLabel;

  /// Label pays film
  ///
  /// In fr, this message translates to:
  /// **'Pays'**
  String get countryLabelFilm;

  /// Label saison film
  ///
  /// In fr, this message translates to:
  /// **'Saison'**
  String get seasonLabelFilm;

  /// Label épisode film
  ///
  /// In fr, this message translates to:
  /// **'Épisode'**
  String get episodeLabelFilm;

  /// Label épisodes film
  ///
  /// In fr, this message translates to:
  /// **'épisode(s)'**
  String get episodesLabelFilm;

  /// Texte description incomplète
  ///
  /// In fr, this message translates to:
  /// **'Description à compléter'**
  String get descriptionToComplete;

  /// Texte filtres à implémenter
  ///
  /// In fr, this message translates to:
  /// **'Filtres à implémenter'**
  String get filtersToImplement;

  /// Affiché lorsqu'un champ obligatoire est vide.
  ///
  /// In fr, this message translates to:
  /// **'Ce champ est obligatoire.'**
  String get required_field;

  /// No description provided for @privacyPolicyIntroductionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Introduction'**
  String get privacyPolicyIntroductionTitle;

  /// No description provided for @privacyPolicyIntroductionContent.
  ///
  /// In fr, this message translates to:
  /// **'Cette politique de confidentialité explique comment nous collectons et utilisons vos données.'**
  String get privacyPolicyIntroductionContent;

  /// No description provided for @privacyPolicyDataCollectedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Données Collectées'**
  String get privacyPolicyDataCollectedTitle;

  /// No description provided for @privacyPolicyDataCollectedContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous collectons des informations de base pour fournir nos services.'**
  String get privacyPolicyDataCollectedContent;

  /// No description provided for @privacyPolicyDataCollectedItem1.
  ///
  /// In fr, this message translates to:
  /// **'Informations du compte'**
  String get privacyPolicyDataCollectedItem1;

  /// No description provided for @privacyPolicyDataCollectedItem2.
  ///
  /// In fr, this message translates to:
  /// **'Données d\'utilisation'**
  String get privacyPolicyDataCollectedItem2;

  /// No description provided for @privacyPolicyDataCollectedItem3.
  ///
  /// In fr, this message translates to:
  /// **'Données techniques'**
  String get privacyPolicyDataCollectedItem3;

  /// No description provided for @privacyPolicyDataUsageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation des Données'**
  String get privacyPolicyDataUsageTitle;

  /// No description provided for @privacyPolicyDataUsageContent.
  ///
  /// In fr, this message translates to:
  /// **'Vos données sont utilisées uniquement pour améliorer nos services.'**
  String get privacyPolicyDataUsageContent;

  /// No description provided for @privacyPolicyDataSharingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Partage des Données'**
  String get privacyPolicyDataSharingTitle;

  /// No description provided for @privacyPolicyDataSharingContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous ne partageons pas vos données avec des tiers sans votre accord.'**
  String get privacyPolicyDataSharingContent;

  /// No description provided for @privacyPolicyUserRightsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vos Droits'**
  String get privacyPolicyUserRightsTitle;

  /// No description provided for @privacyPolicyUserRightsContent.
  ///
  /// In fr, this message translates to:
  /// **'Vous pouvez accéder, modifier ou supprimer vos données à tout moment.'**
  String get privacyPolicyUserRightsContent;

  /// No description provided for @privacyPolicyUserRightsItem1.
  ///
  /// In fr, this message translates to:
  /// **'Droit d\'accès'**
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
  /// **'Nous utilisons des cookies pour améliorer votre expérience de navigation.'**
  String get privacyPolicyCookiesContent;

  /// No description provided for @privacyPolicySecurityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité des Données'**
  String get privacyPolicySecurityTitle;

  /// No description provided for @privacyPolicySecurityContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous appliquons des mesures appropriées pour protéger vos données.'**
  String get privacyPolicySecurityContent;

  /// No description provided for @privacyPolicyChangesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifications de la Politique'**
  String get privacyPolicyChangesTitle;

  /// No description provided for @privacyPolicyChangesContent.
  ///
  /// In fr, this message translates to:
  /// **'Nous pouvons mettre à jour cette politique de temps à autre.'**
  String get privacyPolicyChangesContent;

  /// No description provided for @privacyPolicyContactTitle.
  ///
  /// In fr, this message translates to:
  /// **'Contactez-nous'**
  String get privacyPolicyContactTitle;

  /// No description provided for @privacyPolicyContactContent.
  ///
  /// In fr, this message translates to:
  /// **'Pour toute question, vous pouvez nous contacter.'**
  String get privacyPolicyContactContent;

  /// Affiche la date de la dernière mise à jour de la politique de confidentialité.
  ///
  /// In fr, this message translates to:
  /// **'Dernière mise à jour : {date}'**
  String privacyPolicyLastUpdate(Object date);

  /// No description provided for @uploading.
  ///
  /// In fr, this message translates to:
  /// **'Téléchargement...'**
  String get uploading;

  /// No description provided for @selectVideo.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une vidéo'**
  String get selectVideo;

  /// No description provided for @supportedFormats.
  ///
  /// In fr, this message translates to:
  /// **'Formats supportés: MP4, AVI, MOV, etc.'**
  String get supportedFormats;
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
