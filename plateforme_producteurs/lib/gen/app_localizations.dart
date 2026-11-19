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

  /// No description provided for @dashboardApprovedContents.
  ///
  /// In fr, this message translates to:
  /// **'Contenus approuvés'**
  String get dashboardApprovedContents;

  /// No description provided for @dashboardPendingReview.
  ///
  /// In fr, this message translates to:
  /// **'En attente de validation'**
  String get dashboardPendingReview;

  /// No description provided for @dashboardDraftContents.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons'**
  String get dashboardDraftContents;

  /// No description provided for @dashboardEligibleBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde des vues éligibles'**
  String get dashboardEligibleBalance;

  /// No description provided for @dashboardQualifiedViews.
  ///
  /// In fr, this message translates to:
  /// **'Vues qualifiées (30 j)'**
  String get dashboardQualifiedViews;

  /// No description provided for @dashboardUniqueViewers.
  ///
  /// In fr, this message translates to:
  /// **'Spectateurs uniques (30 j)'**
  String get dashboardUniqueViewers;

  /// No description provided for @dashboardEngagementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d’engagement (30 j)'**
  String get dashboardEngagementRate;

  /// No description provided for @dashboardLast30Days.
  ///
  /// In fr, this message translates to:
  /// **'Audience sur 30 jours · statut actuel des contenus et solde éligible'**
  String get dashboardLast30Days;

  /// No description provided for @dashboardPartialLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Certaines données n’ont pas pu être actualisées.'**
  String get dashboardPartialLoadError;

  /// No description provided for @dashboardLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger le tableau de bord.'**
  String get dashboardLoadError;

  /// No description provided for @dashboardNoRecentActivity.
  ///
  /// In fr, this message translates to:
  /// **'Aucune activité récente.'**
  String get dashboardNoRecentActivity;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In fr, this message translates to:
  /// **'Tout marquer comme lu'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les notifications.'**
  String get notificationsLoadError;

  /// No description provided for @notificationsUpdateError.
  ///
  /// In fr, this message translates to:
  /// **'La mise à jour n’a pas abouti. Réessayez.'**
  String get notificationsUpdateError;

  /// No description provided for @notificationsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune notification pour le moment.'**
  String get notificationsEmpty;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @analyticsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Analytics'**
  String get analyticsTitle;

  /// No description provided for @analyticsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Performance réelle de vos contenus'**
  String get analyticsSubtitle;

  /// No description provided for @analyticsLoadError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger les données Analytics.'**
  String get analyticsLoadError;

  /// No description provided for @analyticsUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Données Analytics indisponibles.'**
  String get analyticsUnavailable;

  /// No description provided for @analyticsRefreshError.
  ///
  /// In fr, this message translates to:
  /// **'Les données n’ont pas pu être actualisées.'**
  String get analyticsRefreshError;

  /// No description provided for @analyticsNoData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée Analytics disponible pour cette période.'**
  String get analyticsNoData;

  /// No description provided for @analyticsQualifiedViews.
  ///
  /// In fr, this message translates to:
  /// **'Vues qualifiées'**
  String get analyticsQualifiedViews;

  /// No description provided for @analyticsUniqueViewers.
  ///
  /// In fr, this message translates to:
  /// **'Spectateurs uniques'**
  String get analyticsUniqueViewers;

  /// No description provided for @analyticsWatchTime.
  ///
  /// In fr, this message translates to:
  /// **'Temps de visionnage'**
  String get analyticsWatchTime;

  /// No description provided for @analyticsCompletedViews.
  ///
  /// In fr, this message translates to:
  /// **'Lectures terminées'**
  String get analyticsCompletedViews;

  /// No description provided for @analyticsEngagement.
  ///
  /// In fr, this message translates to:
  /// **'Engagement'**
  String get analyticsEngagement;

  /// No description provided for @analyticsLikes.
  ///
  /// In fr, this message translates to:
  /// **'J’aime'**
  String get analyticsLikes;

  /// No description provided for @analyticsUnlikes.
  ///
  /// In fr, this message translates to:
  /// **'Je n’aime pas'**
  String get analyticsUnlikes;

  /// No description provided for @analyticsNetLikes.
  ///
  /// In fr, this message translates to:
  /// **'J’aime nets'**
  String get analyticsNetLikes;

  /// No description provided for @analyticsCurrentLikes.
  ///
  /// In fr, this message translates to:
  /// **'J’aime actuels'**
  String get analyticsCurrentLikes;

  /// No description provided for @analyticsEngagedUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs engagés'**
  String get analyticsEngagedUsers;

  /// No description provided for @analyticsEngagementRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux d’engagement'**
  String get analyticsEngagementRate;

  /// No description provided for @analyticsQualifiedViewsByContent.
  ///
  /// In fr, this message translates to:
  /// **'Vues qualifiées par contenu'**
  String get analyticsQualifiedViewsByContent;

  /// No description provided for @analyticsContentPerformance.
  ///
  /// In fr, this message translates to:
  /// **'Performance des contenus'**
  String get analyticsContentPerformance;

  /// No description provided for @analyticsViews.
  ///
  /// In fr, this message translates to:
  /// **'Vues'**
  String get analyticsViews;

  /// No description provided for @analyticsQualification.
  ///
  /// In fr, this message translates to:
  /// **'Qualification'**
  String get analyticsQualification;

  /// No description provided for @analyticsContentFallback.
  ///
  /// In fr, this message translates to:
  /// **'Contenu'**
  String get analyticsContentFallback;

  /// No description provided for @analyticsStarts.
  ///
  /// In fr, this message translates to:
  /// **'Démarrages'**
  String get analyticsStarts;

  /// No description provided for @contentDetailsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détails du contenu'**
  String get contentDetailsTitle;

  /// No description provided for @closeContentDetails.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get closeContentDetails;

  /// No description provided for @contentStatusDraft.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon'**
  String get contentStatusDraft;

  /// No description provided for @contentStatusPending.
  ///
  /// In fr, this message translates to:
  /// **'En validation'**
  String get contentStatusPending;

  /// No description provided for @contentStatusApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get contentStatusApproved;

  /// No description provided for @contentStatusRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusé'**
  String get contentStatusRejected;

  /// No description provided for @contentStatusUnknown.
  ///
  /// In fr, this message translates to:
  /// **'Statut inconnu'**
  String get contentStatusUnknown;

  /// No description provided for @contentTabOverview.
  ///
  /// In fr, this message translates to:
  /// **'Vue d’ensemble'**
  String get contentTabOverview;

  /// No description provided for @contentTabAudience.
  ///
  /// In fr, this message translates to:
  /// **'Audience'**
  String get contentTabAudience;

  /// No description provided for @contentTabMedia.
  ///
  /// In fr, this message translates to:
  /// **'Médias'**
  String get contentTabMedia;

  /// No description provided for @contentTabTechnical.
  ///
  /// In fr, this message translates to:
  /// **'Technique'**
  String get contentTabTechnical;

  /// No description provided for @contentTabSeasons.
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get contentTabSeasons;

  /// No description provided for @contentInfoSection.
  ///
  /// In fr, this message translates to:
  /// **'Informations'**
  String get contentInfoSection;

  /// No description provided for @contentTeamSection.
  ///
  /// In fr, this message translates to:
  /// **'Équipe'**
  String get contentTeamSection;

  /// No description provided for @contentPublicationSection.
  ///
  /// In fr, this message translates to:
  /// **'Publication et validation'**
  String get contentPublicationSection;

  /// No description provided for @contentDirector.
  ///
  /// In fr, this message translates to:
  /// **'Réalisateur'**
  String get contentDirector;

  /// No description provided for @contentScreenwriter.
  ///
  /// In fr, this message translates to:
  /// **'Scénariste'**
  String get contentScreenwriter;

  /// No description provided for @contentProducers.
  ///
  /// In fr, this message translates to:
  /// **'Producteurs'**
  String get contentProducers;

  /// No description provided for @contentCast.
  ///
  /// In fr, this message translates to:
  /// **'Casting'**
  String get contentCast;

  /// No description provided for @contentCreatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Créé'**
  String get contentCreatedAt;

  /// No description provided for @contentUpdatedAt.
  ///
  /// In fr, this message translates to:
  /// **'Mis à jour'**
  String get contentUpdatedAt;

  /// No description provided for @contentPublishedAt.
  ///
  /// In fr, this message translates to:
  /// **'Publication'**
  String get contentPublishedAt;

  /// No description provided for @contentReviewReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif'**
  String get contentReviewReason;

  /// No description provided for @contentViewing.
  ///
  /// In fr, this message translates to:
  /// **'Visionnage'**
  String get contentViewing;

  /// No description provided for @contentPerformance.
  ///
  /// In fr, this message translates to:
  /// **'Performance'**
  String get contentPerformance;

  /// No description provided for @contentStarts.
  ///
  /// In fr, this message translates to:
  /// **'Démarrages'**
  String get contentStarts;

  /// No description provided for @contentCompletionRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de qualification'**
  String get contentCompletionRate;

  /// No description provided for @contentAverageCompletion.
  ///
  /// In fr, this message translates to:
  /// **'Complétion moyenne'**
  String get contentAverageCompletion;

  /// No description provided for @contentLikedUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs ayant aimé'**
  String get contentLikedUsers;

  /// No description provided for @contentNoMedia.
  ///
  /// In fr, this message translates to:
  /// **'Aucun média disponible pour ce contenu.'**
  String get contentNoMedia;

  /// No description provided for @contentPoster.
  ///
  /// In fr, this message translates to:
  /// **'Affiche'**
  String get contentPoster;

  /// No description provided for @contentBanner.
  ///
  /// In fr, this message translates to:
  /// **'Bannière'**
  String get contentBanner;

  /// No description provided for @contentTrailer.
  ///
  /// In fr, this message translates to:
  /// **'Bande-annonce'**
  String get contentTrailer;

  /// No description provided for @contentMasterLoading.
  ///
  /// In fr, this message translates to:
  /// **'Master — chargement…'**
  String get contentMasterLoading;

  /// No description provided for @contentMaster.
  ///
  /// In fr, this message translates to:
  /// **'Master'**
  String get contentMaster;

  /// No description provided for @filterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get filterAll;

  /// No description provided for @filterDrafts.
  ///
  /// In fr, this message translates to:
  /// **'Brouillons'**
  String get filterDrafts;

  /// No description provided for @filterPending.
  ///
  /// In fr, this message translates to:
  /// **'En validation'**
  String get filterPending;

  /// No description provided for @filterApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validés'**
  String get filterApproved;

  /// No description provided for @filterRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusés'**
  String get filterRejected;

  /// No description provided for @moviesPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes films'**
  String get moviesPageTitle;

  /// No description provided for @seriesPageTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes séries'**
  String get seriesPageTitle;

  /// No description provided for @contentNoMovies.
  ///
  /// In fr, this message translates to:
  /// **'Aucun film'**
  String get contentNoMovies;

  /// No description provided for @contentNoSeries.
  ///
  /// In fr, this message translates to:
  /// **'Aucune série'**
  String get contentNoSeries;

  /// No description provided for @contentLoadingMoviesError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos films.'**
  String get contentLoadingMoviesError;

  /// No description provided for @contentLoadingSeriesError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger vos séries.'**
  String get contentLoadingSeriesError;

  /// No description provided for @contentUpdatedOn.
  ///
  /// In fr, this message translates to:
  /// **'Modifié le {date}'**
  String contentUpdatedOn(Object date);

  /// No description provided for @deleteDraftQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce brouillon ?'**
  String get deleteDraftQuestion;

  /// No description provided for @deleteDraftConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get deleteDraftConfirm;

  /// No description provided for @draftDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Brouillon supprimé'**
  String get draftDeleted;

  /// No description provided for @draftDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Le brouillon a été supprimé avec succès.'**
  String get draftDeletedSuccess;

  /// No description provided for @deleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible'**
  String get deleteFailed;

  /// No description provided for @draftDeleteWarning.
  ///
  /// In fr, this message translates to:
  /// **'Ce brouillon sera supprimé automatiquement dans {days} jours.'**
  String draftDeleteWarning(Object days);

  /// No description provided for @draftDeleteSoon.
  ///
  /// In fr, this message translates to:
  /// **'Suppression automatique imminente'**
  String get draftDeleteSoon;

  /// No description provided for @contentNeedsCorrection.
  ///
  /// In fr, this message translates to:
  /// **'Ce contenu doit être corrigé avant une nouvelle soumission.'**
  String get contentNeedsCorrection;

  /// No description provided for @contentPendingReviewFilm.
  ///
  /// In fr, this message translates to:
  /// **'Votre film est en cours de validation par EKEFLICKS.'**
  String get contentPendingReviewFilm;

  /// No description provided for @contentApprovedFilm.
  ///
  /// In fr, this message translates to:
  /// **'Votre film a été validé par EKEFLICKS.'**
  String get contentApprovedFilm;

  /// No description provided for @continueEditing.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get continueEditing;

  /// No description provided for @correctContent.
  ///
  /// In fr, this message translates to:
  /// **'Corriger'**
  String get correctContent;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @addContent.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un contenu'**
  String get addContent;

  /// No description provided for @myDrafts.
  ///
  /// In fr, this message translates to:
  /// **'Mes brouillons'**
  String get myDrafts;

  /// No description provided for @originalTitle.
  ///
  /// In fr, this message translates to:
  /// **'Titre original'**
  String get originalTitle;

  /// No description provided for @originalTitleHelp.
  ///
  /// In fr, this message translates to:
  /// **'Titre dans la langue originale du programme.'**
  String get originalTitleHelp;

  /// No description provided for @shortSynopsis.
  ///
  /// In fr, this message translates to:
  /// **'Synopsis court'**
  String get shortSynopsis;

  /// No description provided for @shortSynopsisHelp.
  ///
  /// In fr, this message translates to:
  /// **'150 à 300 caractères à la soumission finale.'**
  String get shortSynopsisHelp;

  /// No description provided for @longSynopsis.
  ///
  /// In fr, this message translates to:
  /// **'Synopsis long'**
  String get longSynopsis;

  /// No description provided for @longSynopsisHelp.
  ///
  /// In fr, this message translates to:
  /// **'Facultatif — recommandé entre 500 et 1000 caractères.'**
  String get longSynopsisHelp;

  /// No description provided for @xmlImportTitle.
  ///
  /// In fr, this message translates to:
  /// **'Importer les métadonnées XML'**
  String get xmlImportTitle;

  /// No description provided for @xmlPreviewNotice.
  ///
  /// In fr, this message translates to:
  /// **'Le fichier est analysé sans enregistrer ni modifier le contenu.'**
  String get xmlPreviewNotice;

  /// No description provided for @xmlChooseTypeNotice.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez d’abord le type de contenu (Film ou Série). Le modèle XML sera adapté au type choisi.'**
  String get xmlChooseTypeNotice;

  /// No description provided for @xmlDownloadTemplate.
  ///
  /// In fr, this message translates to:
  /// **'Télécharger le modèle XML'**
  String get xmlDownloadTemplate;

  /// No description provided for @xmlAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse…'**
  String get xmlAnalyzing;

  /// No description provided for @xmlImport.
  ///
  /// In fr, this message translates to:
  /// **'Importer un XML'**
  String get xmlImport;

  /// No description provided for @deleteDraftMovieBody.
  ///
  /// In fr, this message translates to:
  /// **'Le film « {title} » sera supprimé définitivement. Les fichiers temporaires associés seront également supprimés. Cette action est irréversible.'**
  String deleteDraftMovieBody(Object title);

  /// No description provided for @deleteDraftSeriesBody.
  ///
  /// In fr, this message translates to:
  /// **'La série « {title} » sera supprimée définitivement. Les fichiers temporaires associés seront également supprimés. Cette action est irréversible.'**
  String deleteDraftSeriesBody(Object title);

  /// No description provided for @contentPendingReviewSeries.
  ///
  /// In fr, this message translates to:
  /// **'Votre série est en cours de validation par EKEFLICKS.'**
  String get contentPendingReviewSeries;

  /// No description provided for @contentApprovedSeries.
  ///
  /// In fr, this message translates to:
  /// **'Votre série a été validée par EKEFLICKS.'**
  String get contentApprovedSeries;

  /// No description provided for @notProvided.
  ///
  /// In fr, this message translates to:
  /// **'Non renseigné'**
  String get notProvided;

  /// No description provided for @contentNoSynopsis.
  ///
  /// In fr, this message translates to:
  /// **'Aucun synopsis renseigné.'**
  String get contentNoSynopsis;

  /// No description provided for @contentDuration.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get contentDuration;

  /// No description provided for @contentClassification.
  ///
  /// In fr, this message translates to:
  /// **'Classification'**
  String get contentClassification;
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
