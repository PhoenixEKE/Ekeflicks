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
    Locale('en'),
    Locale('fr'),
  ];

  /// Title for the New Releases section
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get nouveautes;

  /// Title for the Popular section
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get populaires;

  /// Title of the movie The Desert King
  ///
  /// In en, this message translates to:
  /// **'The Desert King'**
  String get leRoiDuDesert;

  /// Prefix for a new movie title with number
  ///
  /// In en, this message translates to:
  /// **'New Movie'**
  String get nouveauFilm;

  /// Prefix for a popular movie title with number
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get populaire;

  /// Title for TV feature
  ///
  /// In en, this message translates to:
  /// **'Watch on your TV'**
  String get featureTvTitle;

  /// Description of TV feature
  ///
  /// In en, this message translates to:
  /// **'Smart TV, PlayStation, Xbox, Chromecast and more.'**
  String get featureTvDesc;

  /// Title for anywhere feature
  ///
  /// In en, this message translates to:
  /// **'Watch everywhere'**
  String get featureAnywhereTitle;

  /// Description of anywhere feature
  ///
  /// In en, this message translates to:
  /// **'Unlimited streaming on your phone, tablet and computer.'**
  String get featureAnywhereDesc;

  /// Title for offline feature
  ///
  /// In en, this message translates to:
  /// **'Download offline'**
  String get featureOfflineTitle;

  /// Description of offline feature
  ///
  /// In en, this message translates to:
  /// **'Save your favorite content to watch without connection.'**
  String get featureOfflineDesc;

  /// Title for streaming feature
  ///
  /// In en, this message translates to:
  /// **'High quality streaming'**
  String get featureStreamingTitle;

  /// Description of streaming feature
  ///
  /// In en, this message translates to:
  /// **'Enjoy your movies in Full HD and 4K quality.'**
  String get featureStreamingDesc;

  /// Copyright message
  ///
  /// In en, this message translates to:
  /// **'© 2026 EKEflicks - EPHRATA, All rights reserved. Developed by EPHRATA.'**
  String get footerCopyright;

  /// Title for contact section in footer
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get footerContact;

  /// Label for email contact
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get footerEmail;

  /// Label for phone contact
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get footerPhone;

  /// Label for WhatsApp contact
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get footerWhatsApp;

  /// Label for company section
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get footerCompany;

  /// Link to privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get footerPrivacyPolicy;

  /// Link to terms of use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get footerTerms;

  /// FAQ page title
  ///
  /// In en, this message translates to:
  /// **'FAQ'**
  String get faq;

  /// Language button tooltip
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// Language selection dialog title
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// Light theme tooltip
  ///
  /// In en, this message translates to:
  /// **'Light theme'**
  String get lightTheme;

  /// Dark theme tooltip
  ///
  /// In en, this message translates to:
  /// **'Dark theme'**
  String get darkTheme;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get connexion;

  /// Tooltip text or label for menu button
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get sinscrire;

  /// Button text to play content
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Libellé du bouton pour mettre en pause la vidéo
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Tooltip for mute button
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// Tooltip for unmute button
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// Tooltip for disabling subtitles
  ///
  /// In en, this message translates to:
  /// **'Turn off subtitles'**
  String get subtitlesOn;

  /// Tooltip for enabling subtitles
  ///
  /// In en, this message translates to:
  /// **'Turn on subtitles'**
  String get subtitlesOff;

  /// Tooltip for entering fullscreen
  ///
  /// In en, this message translates to:
  /// **'Fullscreen'**
  String get fullscreen;

  /// Tooltip for exiting fullscreen
  ///
  /// In en, this message translates to:
  /// **'Exit fullscreen'**
  String get exitFullscreen;

  /// Error message when video playback fails
  ///
  /// In en, this message translates to:
  /// **'An error occurred during playback.'**
  String get videoPlaybackError;

  /// Label for retry button after an error
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button to watch trailer
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get trailer;

  /// Button to share content
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Button to download content
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// Button to add or remove from favorites
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Button to add content to user's list
  ///
  /// In en, this message translates to:
  /// **'Add to my list'**
  String get addToList;

  /// Title of section containing content summary
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get synopsis;

  /// Button to expand detailed information
  ///
  /// In en, this message translates to:
  /// **'See more'**
  String get seeMore;

  /// Button to reduce or hide detailed information
  ///
  /// In en, this message translates to:
  /// **'See less'**
  String get seeLess;

  /// Title of section listing series seasons
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get seasons;

  /// Title of contact form
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// Name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Error message for empty field
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// Field for the user's email address
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Error message for invalid email
  ///
  /// In en, this message translates to:
  /// **'Invalid email.'**
  String get invalidEmail;

  /// Message field
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// Button to send message
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Text for WhatsApp and phone contacts section
  ///
  /// In en, this message translates to:
  /// **'Or contact us directly:'**
  String get orContactUsMobile;

  /// Title of the welcome popup
  ///
  /// In en, this message translates to:
  /// **'Welcome to EkeFlicks!\nAfrica shines on the big screen, with its unique and captivating stories.'**
  String get popupTitreAccueil;

  /// Content text of the welcome popup
  ///
  /// In en, this message translates to:
  /// **'Also discover movies from around the world, with unlimited access from {prix}, cancel anytime.'**
  String popupTexteAccueil(Object prix);

  /// Button to close dialogs or menus
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get fermer;

  /// Tooltip text for language change button
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get changerDeLangue;

  /// Title for privacy policy
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get politiqueConfidentialite;

  /// Title for terms of use
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get conditionsUtilisation;

  /// Footer text for contact information
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Tooltip text for theme change button
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get changerDeTheme;

  /// Placeholder in search bar
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get rechercher;

  /// Title of the section showing content the user has already started
  ///
  /// In en, this message translates to:
  /// **'Continue Watching'**
  String get continueWatching;

  /// Prefix for recommended content titles
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommended;

  /// Title for popular content section
  ///
  /// In en, this message translates to:
  /// **'Popular'**
  String get popular;

  /// Section title for new content
  ///
  /// In en, this message translates to:
  /// **'New Releases'**
  String get newReleases;

  /// Label for the director name
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get directorLabel;

  /// Label for the list of actors
  ///
  /// In en, this message translates to:
  /// **'Cast'**
  String get castLabel;

  /// Section title for the list of seasons
  ///
  /// In en, this message translates to:
  /// **'Seasons'**
  String get seasonsLabel;

  /// Placeholder text for seasons when data is missing
  ///
  /// In en, this message translates to:
  /// **'Season list coming soon.'**
  String get seasonsPlaceholder;

  /// Title for similar content section
  ///
  /// In en, this message translates to:
  /// **'Similar Content'**
  String get similarContentLabel;

  /// Error message when failing to open a URL link
  ///
  /// In en, this message translates to:
  /// **'Could not open link'**
  String get linkOpenError;

  /// Title for the legal section in the footer
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get footerLegal;

  /// Label for the cookies policy link in the footer
  ///
  /// In en, this message translates to:
  /// **'Cookies Policy'**
  String get footerCookies;

  /// Short invitation to download the app
  ///
  /// In en, this message translates to:
  /// **'Download on mobile'**
  String get footerDownloadApp;

  /// Title for payment methods section
  ///
  /// In en, this message translates to:
  /// **'Payment Methods'**
  String get footerPaymentMethods;

  /// Shown when there are no featured contents to display
  ///
  /// In en, this message translates to:
  /// **'No featured content available'**
  String get noFeaturedContent;

  /// Message displayed when video cannot be played or is unavailable
  ///
  /// In en, this message translates to:
  /// **'Video not available'**
  String get videoNotAvailable;

  /// Invitation to follow on social media
  ///
  /// In en, this message translates to:
  /// **'Follow us on'**
  String get footerFollowUs;

  /// Title of section a serie season
  ///
  /// In en, this message translates to:
  /// **'Season'**
  String get season;

  /// Title of section listing episodes
  ///
  /// In en, this message translates to:
  /// **'Episodes'**
  String get episodes;

  /// Title of section one episode
  ///
  /// In en, this message translates to:
  /// **'Episode'**
  String get episode;

  /// Title for section showing similar content
  ///
  /// In en, this message translates to:
  /// **'Similar content'**
  String get similarContent;

  /// Title of the section showing the cast and crew of the movie or show
  ///
  /// In en, this message translates to:
  /// **'Cast & Crew'**
  String get distribution;

  /// Default message when there is no description
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// Title for the section displaying popular genres
  ///
  /// In en, this message translates to:
  /// **'Popular Genres'**
  String get popularGenres;

  /// Title for the section displaying genres
  ///
  /// In en, this message translates to:
  /// **'Genres'**
  String get genres;

  /// Title for the African Series section
  ///
  /// In en, this message translates to:
  /// **'African Series'**
  String get seriesAfricaines;

  /// Prefix for an African series title with number
  ///
  /// In en, this message translates to:
  /// **'African Series'**
  String get serieAfrique;

  /// Button text to view all movies
  ///
  /// In en, this message translates to:
  /// **'View All Movies'**
  String get voirLesFilms;

  /// Label for watch movie button
  ///
  /// In en, this message translates to:
  /// **'Watch'**
  String get regarder;

  /// Label for movie info button
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get infos;

  /// Title for subscription plans block
  ///
  /// In en, this message translates to:
  /// **'Subscription Plans'**
  String get offresAbonnement;

  /// Prefix for subscription plan number
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get plan;

  /// Description text in a subscription plan card
  ///
  /// In en, this message translates to:
  /// **'Subscription plan description'**
  String get descriptionPlan;

  /// Button text to subscribe to a plan
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get souscrire;

  /// Footer text for legal notices
  ///
  /// In en, this message translates to:
  /// **'Legal Notice'**
  String get mentionLegale;

  /// Message displayed when there are no banners
  ///
  /// In en, this message translates to:
  /// **'No banners available'**
  String get noBannersAvailable;

  /// Description of The Desert King movie
  ///
  /// In en, this message translates to:
  /// **'An epic drama available now.'**
  String get descLeRoiDuDesert;

  /// Title of the movie The North Star
  ///
  /// In en, this message translates to:
  /// **'The North Star'**
  String get etoileDuNord;

  /// Description of The North Star movie
  ///
  /// In en, this message translates to:
  /// **'An exciting adventure awaits you.'**
  String get descEtoileDuNord;

  /// Title of the movie African Heart
  ///
  /// In en, this message translates to:
  /// **'African Heart'**
  String get coeurAfricain;

  /// Description of African Heart movie
  ///
  /// In en, this message translates to:
  /// **'A journey to the heart of tradition.'**
  String get descCoeurAfricain;

  /// Title for the Features section
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get fonctionnalites;

  /// Title for subscription section
  ///
  /// In en, this message translates to:
  /// **'Subscription Title'**
  String get abonnementTitre;

  /// Description text for subscription
  ///
  /// In en, this message translates to:
  /// **'Subscription description'**
  String get abonnementDesc;

  /// Login page title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get connexionTitre;

  /// Error message if email is empty
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get emailObligatoire;

  /// Error message if email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get emailInvalide;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get motDePasse;

  /// Error message if password is empty
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get motDePasseObligatoire;

  /// Error message if password is too short
  ///
  /// In en, this message translates to:
  /// **'Password must contain at least 8 characters'**
  String get motDePasseTropCourt;

  /// Link to reset password
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get motDePasseOublie;

  /// Button text to sign in
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get seConnecter;

  /// Invitation to sign up
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account yet?'**
  String get pasEncoreCompte;

  /// Message displayed after successful login
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get connexionReussie;

  /// Tooltip for back button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get retour;

  /// Button text to validate a form
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get valider;

  /// Text inviting to return to login page
  ///
  /// In en, this message translates to:
  /// **'Back to login page?'**
  String get retourConnexion;

  /// Message after sending reset form
  ///
  /// In en, this message translates to:
  /// **'If this email exists, a reset link has been sent.'**
  String get emailEnvoye;

  /// Sign up page title
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get inscriptionTitre;

  /// Last name field label
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get nom;

  /// First name field label
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get prenom;

  /// Error message if last name is empty
  ///
  /// In en, this message translates to:
  /// **'Last name is required'**
  String get nomObligatoire;

  /// Error message if first name is empty
  ///
  /// In en, this message translates to:
  /// **'First name is required'**
  String get prenomObligatoire;

  /// Text before terms and policy links
  ///
  /// In en, this message translates to:
  /// **'By clicking Create, you accept our'**
  String get acceptationTexte1;

  /// Connecting word between terms and policy
  ///
  /// In en, this message translates to:
  /// **'and'**
  String get et;

  /// Message after successful sign up
  ///
  /// In en, this message translates to:
  /// **'Sign up successful'**
  String get inscriptionReussie;

  /// Error message if last name is too short
  ///
  /// In en, this message translates to:
  /// **'Last name must contain at least 3 characters.'**
  String get nomTropCourt;

  /// Error message if first name is too short
  ///
  /// In en, this message translates to:
  /// **'First name must contain at least 3 characters.'**
  String get prenomTropCourt;

  /// Main title for terms of use
  ///
  /// In en, this message translates to:
  /// **'EKEflicks Terms of Use'**
  String get termsTitle;

  /// Introduction to terms of use
  ///
  /// In en, this message translates to:
  /// **'Welcome to Ekeflicks, your streaming platform dedicated to African cinema. By using our service, you accept these Terms of Use. Please read them carefully.'**
  String get termsIntro;

  /// Title for acceptance section
  ///
  /// In en, this message translates to:
  /// **'1. Acceptance of Terms'**
  String get terms1Title;

  /// Text for acceptance section
  ///
  /// In en, this message translates to:
  /// **'By accessing or using our platform, you agree to comply with these Terms of Use and all applicable laws and regulations. If you do not accept these terms, please do not use our service.'**
  String get terms1Content;

  /// Title for modifications section
  ///
  /// In en, this message translates to:
  /// **'2. Modification of Terms'**
  String get terms2Title;

  /// Text about modifications
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these Terms of Use at any time. Changes will take effect upon publication on our site. Your continued use of our service after any changes constitutes your acceptance of the new terms.'**
  String get terms2Content;

  /// Title for user account section
  ///
  /// In en, this message translates to:
  /// **'3. User Account'**
  String get terms3Title;

  /// Text about user account
  ///
  /// In en, this message translates to:
  /// **'3.1. Registration\nTo access certain features of our service, you must create an account. You must provide accurate and complete information during registration and update this information if necessary.\n\n3.2. Responsibility\nYou are responsible for the confidentiality of your login credentials and all activities that occur under your account. You must immediately inform us of any unauthorized use of your account.'**
  String get terms3Content;

  /// Title for service use section
  ///
  /// In en, this message translates to:
  /// **'4. Use of Service'**
  String get terms4Title;

  /// Text about use and restrictions
  ///
  /// In en, this message translates to:
  /// **'4.1. Access\nWe grant you a limited, non-exclusive, non-transferable and revocable right to use our service for your personal and non-commercial use.\n\n4.2. Restrictions\nYou agree not to reproduce, distribute, modify, transmit, display, perform, publish, create derivative works or exploit in any way any content from our service without our prior authorization.'**
  String get terms4Content;

  /// Title for content section
  ///
  /// In en, this message translates to:
  /// **'5. Content'**
  String get terms5Title;

  /// Text about content and ownership
  ///
  /// In en, this message translates to:
  /// **'5.1. Ownership\nAll content available on Ekeflicks, including videos, images, texts, and graphics, is protected by copyright and other intellectual property rights.\n\n5.2. License\nBy accessing our service, we grant you a limited license to view content only for your personal and non-commercial use.'**
  String get terms5Content;

  /// Title for subscriptions and payments section
  ///
  /// In en, this message translates to:
  /// **'6. Subscriptions and Payments'**
  String get terms6Title;

  /// Text about subscriptions and payments
  ///
  /// In en, this message translates to:
  /// **'6.1. Subscriptions\nOur subscriptions are subject to the terms of the current offer. Subscription fees may vary and will be clearly indicated at registration.\n\n6.2. Payment\nYou agree to provide valid payment information and pay all applicable fees for your subscription. We reserve the right to suspend or terminate your access if payment is declined.'**
  String get terms6Content;

  /// Title for termination section
  ///
  /// In en, this message translates to:
  /// **'7. Termination'**
  String get terms7Title;

  /// Text about termination terms
  ///
  /// In en, this message translates to:
  /// **'7.1. By you\nYou may cancel your subscription at any time through your account. Fees already paid will not be refunded for unused subscription periods.\n\n7.2. By us\nWe reserve the right to suspend or terminate your access to our service if you violate these Terms of Use.'**
  String get terms7Content;

  /// Title for liability section
  ///
  /// In en, this message translates to:
  /// **'8. Liability'**
  String get terms8Title;

  /// Text about limitation and indemnification
  ///
  /// In en, this message translates to:
  /// **'8.1. Limitation\nEkeflicks will not be liable for indirect, special, incidental or consequential damages resulting from your use or inability to use our service, even if we have been informed of the possibility of such damages.\n\n8.2. Indemnification\nYou agree to indemnify and hold Ekeflicks harmless from any claim or demand made by a third party related to your use of our service or violation of these Terms of Use.'**
  String get terms8Content;

  /// Title for intellectual property section
  ///
  /// In en, this message translates to:
  /// **'9. Intellectual Property'**
  String get terms9Title;

  /// Text about intellectual property
  ///
  /// In en, this message translates to:
  /// **'All content and technologies used to provide our service are the property of Ekeflicks or its licensors. You acquire no ownership rights to the content by using our service.'**
  String get terms9Content;

  /// Title for applicable laws section
  ///
  /// In en, this message translates to:
  /// **'10. Applicable Laws'**
  String get terms10Title;

  /// Text about applicable jurisdiction
  ///
  /// In en, this message translates to:
  /// **'These Terms of Use are governed by the laws of Ivory Coast. Any dispute arising from or related to these terms will be submitted to the competent courts of France or Côte d\'Ivoire.'**
  String get terms10Content;

  /// Title for contact section
  ///
  /// In en, this message translates to:
  /// **'11. Contact'**
  String get terms11Title;

  /// Contact text
  ///
  /// In en, this message translates to:
  /// **'Ekeflicks\n9 Jules Caesar Street, Bordeaux-France\n+33 06 84 57 69\n'**
  String get terms11Content;

  /// No description provided for @terms12Content.
  ///
  /// In en, this message translates to:
  /// **'\nVITIB, Bassam-Côte d\'Ivoire\n+225 07 16 09 69 40\n\nsupport@ekeflicks.com'**
  String get terms12Content;

  /// Title of the Privacy Policy page
  ///
  /// In en, this message translates to:
  /// **'EKEflicks Privacy Policy'**
  String get privacyPolicyTitle;

  /// Introduction to Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Welcome to EKEflicks\' Privacy Policy. We place great importance on protecting your personal information. This policy explains how we collect, use, share and protect your data. By using our platform, you accept the practices described in this policy.'**
  String get privacyPolicyIntro;

  /// Title for section 1
  ///
  /// In en, this message translates to:
  /// **'1. Collected Information'**
  String get section1Title;

  /// Title for subsection 1.1
  ///
  /// In en, this message translates to:
  /// **'1.1. Information Provided by User'**
  String get section1_1Title;

  /// Text for subsection 1.1
  ///
  /// In en, this message translates to:
  /// **'When creating an account, subscribing to services or communicating with our support team, you may provide us with information such as your name, email address, billing address, etc.'**
  String get section1_1Text;

  /// Title for subsection 1.2
  ///
  /// In en, this message translates to:
  /// **'1.2. Automatically Collected Information'**
  String get section1_2Title;

  /// Text for subsection 1.2
  ///
  /// In en, this message translates to:
  /// **'We may automatically collect information through the use of cookies and similar technologies, such as login data, device information, IP address, etc.'**
  String get section1_2Text;

  /// Title for section 2
  ///
  /// In en, this message translates to:
  /// **'2. Use of Information'**
  String get section2Title;

  /// Title for subsection 2.1
  ///
  /// In en, this message translates to:
  /// **'2.1. Provision of Services'**
  String get section2_1Title;

  /// Text for subsection 2.1
  ///
  /// In en, this message translates to:
  /// **'We use your information to provide you with the requested services, including video streaming, user account management and payment processing.'**
  String get section2_1Text;

  /// Title for subsection 2.2
  ///
  /// In en, this message translates to:
  /// **'2.2. Service Improvement'**
  String get section2_2Title;

  /// Text for subsection 2.2
  ///
  /// In en, this message translates to:
  /// **'We use collected data to improve the quality of our services, personalize your user experience and develop new features.'**
  String get section2_2Text;

  /// Title for subsection 2.3
  ///
  /// In en, this message translates to:
  /// **'2.3. Communication with User'**
  String get section2_3Title;

  /// Text for subsection 2.3
  ///
  /// In en, this message translates to:
  /// **'We may use your information to send you service-related communications, updates, special offers and information about new content.'**
  String get section2_3Text;

  /// Title for section 3
  ///
  /// In en, this message translates to:
  /// **'3. Sharing of Information'**
  String get section3Title;

  /// Title for subsection 3.1
  ///
  /// In en, this message translates to:
  /// **'3.1. Sharing with Partners'**
  String get section3_1Title;

  /// Text for subsection 3.1
  ///
  /// In en, this message translates to:
  /// **'We may share certain information with trusted partners for the provision of additional services, such as payment processing.'**
  String get section3_1Text;

  /// Title for subsection 3.2
  ///
  /// In en, this message translates to:
  /// **'3.2. Legal Compliance'**
  String get section3_2Title;

  /// Text for subsection 3.2
  ///
  /// In en, this message translates to:
  /// **'We may disclose information in compliance with applicable laws, legal proceedings, and to protect our legal rights.'**
  String get section3_2Text;

  /// Title for section 4
  ///
  /// In en, this message translates to:
  /// **'4. Data Security'**
  String get section4Title;

  /// Text for section 4
  ///
  /// In en, this message translates to:
  /// **'We implement appropriate security measures to protect your information against unauthorized access, disclosure, alteration and destruction.'**
  String get section4Text;

  /// Title for section 5
  ///
  /// In en, this message translates to:
  /// **'5. User Rights'**
  String get section5Title;

  /// Text for section 5
  ///
  /// In en, this message translates to:
  /// **'You have the right to access your information, rectify it, delete it, or restrict its processing. To exercise these rights, please contact us at support@ekeflicks.com.'**
  String get section5Text;

  /// Title for section 6
  ///
  /// In en, this message translates to:
  /// **'6. Privacy Policy Changes'**
  String get section6Title;

  /// Text for section 6
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to update this Privacy Policy. Any changes will be published on EKEflicks. By continuing to use our services after these changes, you accept the revised terms.'**
  String get section6Text;

  /// Acknowledgements at end of Privacy Policy
  ///
  /// In en, this message translates to:
  /// **'Thank you for using EKEflicks. For any questions regarding this policy, please contact us at support@ekeflicks.com.'**
  String get privacyPolicyThanks;

  /// Title for Terms of Use page
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUseTitle;

  /// Button to log out and return to home page
  ///
  /// In en, this message translates to:
  /// **'Log Out'**
  String get seDeconnecter;

  /// Progress indicator for step 1 of 2
  ///
  /// In en, this message translates to:
  /// **'Step 1 of 2'**
  String get etape1sur2;

  /// Introductory message for offer selection
  ///
  /// In en, this message translates to:
  /// **'Choose the offer that suits you'**
  String get choisissezVotreOffre;

  /// Label for offer resolution
  ///
  /// In en, this message translates to:
  /// **'Resolution'**
  String get resolution;

  /// Label for compatible devices with the offer
  ///
  /// In en, this message translates to:
  /// **'Supported devices'**
  String get appareilsPrisEnCharge;

  /// Label for number of simultaneous users
  ///
  /// In en, this message translates to:
  /// **'Simultaneous devices allowed'**
  String get appareilsSimultanes;

  /// Label for devices that can download videos
  ///
  /// In en, this message translates to:
  /// **'Devices allowed for download'**
  String get telechargement;

  /// Indicates if the offer contains advertisements
  ///
  /// In en, this message translates to:
  /// **'Ads'**
  String get pubs;

  /// Button text to go to next step
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get suivant;

  /// Information text under subscription offers
  ///
  /// In en, this message translates to:
  /// **'If you select an offer with ads, we will ask you to provide your date of birth to personalize advertisements, as well as for other purposes in accordance with the Privacy Statement.\n\nAvailability of Full HD (1080p), Ultra HD (4K) and HDR depends on your internet connection and device capabilities. Not all content is available in all resolutions.\n\nOnly people who live with you can use your account. Live events are not included in the offers.'**
  String get texteExplicatifAbonnement;

  /// Error message displayed when authentication fails
  ///
  /// In en, this message translates to:
  /// **'Authentication error, please try again.'**
  String get erreurAuthentification;

  /// Error message displayed when registration fails
  ///
  /// In en, this message translates to:
  /// **'Registration error, please try again.'**
  String get erreurInscription;

  /// Format to display monthly price
  ///
  /// In en, this message translates to:
  /// **'{price} / month'**
  String prixParMois(String price);

  /// Label for advertisements
  ///
  /// In en, this message translates to:
  /// **'Advertisements'**
  String get publicites;

  /// Message displayed when price is not available
  ///
  /// In en, this message translates to:
  /// **'Price not available'**
  String get prixNonDisponible;

  /// Label for monthly subscription
  ///
  /// In en, this message translates to:
  /// **'Monthly subscription'**
  String get abonnementMensuel;

  /// Label for video quality
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get qualite;

  /// Text indicating step 2 of 2 in subscription process
  ///
  /// In en, this message translates to:
  /// **'Step 2 of 2'**
  String get step2of2;

  /// Main title of step 2 page inviting user to choose payment method. Variables: offerTitle, offerPrice
  ///
  /// In en, this message translates to:
  /// **'Choose your payment method for the {offerTitle} offer ({offerPrice})'**
  String chooseYourPaymentMethodForOffer(Object offerTitle, Object offerPrice);

  /// Informative message about payment security and flexibility
  ///
  /// In en, this message translates to:
  /// **'Secure payment - End-to-end encrypted - Easy cancellation - Modifiable at any time.'**
  String get paymentSecureInfo;

  /// Message displayed when payment page is not yet available
  ///
  /// In en, this message translates to:
  /// **'Payment page under development.'**
  String get paymentPageComingSoon;

  /// Title for movies to continue section
  ///
  /// In en, this message translates to:
  /// **'Continue watching'**
  String get continuerLecture;

  /// Title for recommended movies
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get recommandePourVous;

  /// Label for chatbot access button
  ///
  /// In en, this message translates to:
  /// **'Assistant'**
  String get chatbot;

  /// Main menu Movies
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get films;

  /// Main menu Series
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get series;

  /// Main menu Documentaries
  ///
  /// In en, this message translates to:
  /// **'Documentaries'**
  String get documentaires;

  /// Main menu Reality TV
  ///
  /// In en, this message translates to:
  /// **'Reality TV'**
  String get telerealites;

  /// Main menu Live
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get live;

  /// Main menu Explore by country
  ///
  /// In en, this message translates to:
  /// **'Explore by country'**
  String get explorerParPays;

  /// Icon or label Notifications
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Menu option to change user profile
  ///
  /// In en, this message translates to:
  /// **'Switch profile'**
  String get changerProfil;

  /// Menu option to access user account
  ///
  /// In en, this message translates to:
  /// **'My account'**
  String get compte;

  /// Menu option to log out
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get deconnexion;

  /// Main title of the application
  ///
  /// In en, this message translates to:
  /// **'Ekeflicks'**
  String get appTitle;

  /// Section title for trends
  ///
  /// In en, this message translates to:
  /// **'Popular on Ekeflicks'**
  String get popularOnEkeflicks;

  /// Button text to display all items in a section
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Label or title for the Movies section
  ///
  /// In en, this message translates to:
  /// **'Movies'**
  String get movies;

  /// Prefix for series titles
  ///
  /// In en, this message translates to:
  /// **'Series'**
  String get serie;

  /// Title of the section displaying newly added content
  ///
  /// In en, this message translates to:
  /// **'New Release'**
  String get newRelease;

  /// Error message when loading fails
  ///
  /// In en, this message translates to:
  /// **'Error loading content'**
  String get errorLoadingContent;

  /// Message when no data is available
  ///
  /// In en, this message translates to:
  /// **'No content available'**
  String get noContentAvailable;

  /// Button to add content to user's list
  ///
  /// In en, this message translates to:
  /// **'Added to my list'**
  String get addedToList;

  /// Button to display content_info_sheet widget
  ///
  /// In en, this message translates to:
  /// **'More information'**
  String get moreInfo;

  /// Message displayed when an item is removed from the list
  ///
  /// In en, this message translates to:
  /// **'Removed from list'**
  String get removedFromList;

  /// Confirmation message when an item is added
  ///
  /// In en, this message translates to:
  /// **'Added to your list'**
  String get addedToWatchlist;

  /// Button label to watch trailer
  ///
  /// In en, this message translates to:
  /// **'Trailer'**
  String get watchTrailer;

  /// Button to display more information
  ///
  /// In en, this message translates to:
  /// **'Show more details'**
  String get moreDetails;

  /// Button to hide technical information
  ///
  /// In en, this message translates to:
  /// **'Hide details'**
  String get hideDetails;

  /// Label to invite user to rate
  ///
  /// In en, this message translates to:
  /// **'Your rating:'**
  String get yourRating;

  /// Title for technical details section
  ///
  /// In en, this message translates to:
  /// **'Technical Information'**
  String get technicalInformation;

  /// Label for director
  ///
  /// In en, this message translates to:
  /// **'Director'**
  String get labelDirector;

  /// Label for actors
  ///
  /// In en, this message translates to:
  /// **'Actors'**
  String get labelActors;

  /// Label for genre
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get labelGenre;

  /// Label for language
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get labelLanguage;

  /// Label for year
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get labelYear;

  /// Label for country
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get labelCountry;

  /// Default text when information is missing
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// Label to add to list
  ///
  /// In en, this message translates to:
  /// **'My list'**
  String get myList;

  /// Button to display details
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// Affirmative answer
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// Affirmative answer
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get oui;

  /// Negative answer
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Negative answer
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get non;

  /// Menu containing Documentaries, Reality TV, Live
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get plus;

  /// Text indicating content is in user's list
  ///
  /// In en, this message translates to:
  /// **'In my list'**
  String get inWatchlist;

  /// Text displayed when content is removed from user's list
  ///
  /// In en, this message translates to:
  /// **'Removed from my list'**
  String get removedFromWatchlist;

  /// Label for kid-friendly content
  ///
  /// In en, this message translates to:
  /// **'For kids'**
  String get forKids;

  /// Message displayed when content is added to user's list
  ///
  /// In en, this message translates to:
  /// **'Add to my list'**
  String get addToWatchlist;

  /// Message displayed when an action requires the user to be logged in.
  ///
  /// In en, this message translates to:
  /// **'You must be logged in to access this feature.'**
  String get loginRequired;

  /// Text displayed during download start
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// Title shown after successful login
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get postLoginTitle;

  /// Welcome message on post-login page
  ///
  /// In en, this message translates to:
  /// **'Welcome to your space'**
  String get postLoginWelcome;

  /// Welcome back message on login screen
  ///
  /// In en, this message translates to:
  /// **'Good to see you again!'**
  String get bienvenueRetour;

  /// Legal message footer: all rights reserved
  ///
  /// In en, this message translates to:
  /// **'All rights reserved'**
  String get allRightsReserved;

  /// Instruction text on the password reset screen
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address to reset your password.'**
  String get entrerEmailRecuperation;

  /// Word used between two options (e.g. 'or' between buttons)
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get ou;

  /// Button text to start watching a tutorial
  ///
  /// In en, this message translates to:
  /// **'Watch now'**
  String get regarderMaintenant;

  /// Text for a button or link to view a tutorial
  ///
  /// In en, this message translates to:
  /// **'Click to view tutorial'**
  String get cliquerPourVoir;

  /// Title of the error dialog
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Button text to close a dialog
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Message shown while the video player is loading
  ///
  /// In en, this message translates to:
  /// **'Loading video...'**
  String get loadingVideo;

  /// Error message displayed if the user doesn't accept terms during sign-up
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms of use.'**
  String get acceptTermsError;

  /// Subtitle on the sign-up screen
  ///
  /// In en, this message translates to:
  /// **'Create your account to continue.'**
  String get inscriptionSousTitre;

  /// Text prompting the user to sign in if they already have an account
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get dejaUnCompte;

  /// Text for the sign-in button or link
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get connectezVous;

  /// Button text or title for the sign-up page
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Title of the section with recommended content for the user
  ///
  /// In en, this message translates to:
  /// **'Recommended for You'**
  String get recommendedForYou;

  /// Genre for adventure movies or series
  ///
  /// In en, this message translates to:
  /// **'Adventure'**
  String get adventure;

  /// Message shown when the notification feature is not available
  ///
  /// In en, this message translates to:
  /// **'Notifications not implemented'**
  String get notificationsNonImpl;

  /// Title of the section showing trending or frequently watched content
  ///
  /// In en, this message translates to:
  /// **'Popular Content'**
  String get popularContent;

  /// Label for the home tab or icon
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Label for the search tab or icon
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Label for the user profile tab or icon
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Bouton pour revoir un contenu déjà visionné
  ///
  /// In en, this message translates to:
  /// **'Regarder à nouveau'**
  String get watchAgain;

  /// Text shown when content has already been watched by the user
  ///
  /// In en, this message translates to:
  /// **'Already watched'**
  String get alreadyWatched;

  /// Genre label for Action movies
  ///
  /// In en, this message translates to:
  /// **'Action'**
  String get action;

  /// Genre label for Comedy movies
  ///
  /// In en, this message translates to:
  /// **'Comedy'**
  String get comedy;

  /// Genre label for Drama movies
  ///
  /// In en, this message translates to:
  /// **'Drama'**
  String get drama;

  /// Genre label for Science Fiction movies
  ///
  /// In en, this message translates to:
  /// **'Sci-Fi'**
  String get sciFi;

  /// Genre label for Documentary films
  ///
  /// In en, this message translates to:
  /// **'Documentary'**
  String get documentary;

  /// Label for the Animation genre
  ///
  /// In en, this message translates to:
  /// **'Animation'**
  String get animation;

  /// Label for the Horror genre
  ///
  /// In en, this message translates to:
  /// **'Horror'**
  String get horror;

  /// Label for the Fantasy genre
  ///
  /// In en, this message translates to:
  /// **'Fantasy'**
  String get fantasy;

  /// Label for the Romance genre
  ///
  /// In en, this message translates to:
  /// **'Romance'**
  String get romance;

  /// Label used to indicate the number of titles (e.g. '12 titles')
  ///
  /// In en, this message translates to:
  /// **'titles'**
  String get titles;

  /// Label used to indicate the list of all content items
  ///
  /// In en, this message translates to:
  /// **'All titles'**
  String get allContents;

  /// Label for adult user profile
  ///
  /// In en, this message translates to:
  /// **'Adult Profile'**
  String get adultProfile;

  /// Label for child user profile
  ///
  /// In en, this message translates to:
  /// **'Child Profile'**
  String get childProfile;

  /// Label for guest user profile
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guestProfile;

  /// Title to choose user profile
  ///
  /// In en, this message translates to:
  /// **'Choose a Profile'**
  String get chooseProfile;

  /// Label for adding a new user profile
  ///
  /// In en, this message translates to:
  /// **'Add Profile'**
  String get addProfile;

  /// Field label for entering the profile name
  ///
  /// In en, this message translates to:
  /// **'Profile Name'**
  String get profileName;

  /// Cancel button label
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Save button label
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Message shown when user switches profile
  ///
  /// In en, this message translates to:
  /// **'Profile changed to'**
  String get profileChangedTo;

  /// Action to log out of the account
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Confirmation message when logging out
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout?'**
  String get logoutConfirmation;

  /// Title for the user's account section
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get myAccount;

  /// Title for the personal information section
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Field for the full name
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Field for the user's phone number
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Field for the user's country
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// Account security section
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Option to change the password
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// Title for the user's personal content section
  ///
  /// In en, this message translates to:
  /// **'My Content'**
  String get myContent;

  /// List of favorite contents
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoritesList;

  /// Section for downloaded content
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloads;

  /// Label for the settings section
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Title for accessing profile settings
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// Title for accessing account settings
  ///
  /// In en, this message translates to:
  /// **'Account Settings'**
  String get accountSettings;

  /// Label for the user's selected payment method
  ///
  /// In en, this message translates to:
  /// **'Payment Method'**
  String get paymentMethod;

  /// Label for the billing date
  ///
  /// In en, this message translates to:
  /// **'Billing Date'**
  String get billingDate;

  /// Title for managing connected devices
  ///
  /// In en, this message translates to:
  /// **'Device Management'**
  String get deviceManagement;

  /// Title for general app settings
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get appSettings;

  /// Label for selecting the application language
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// Title for notification preferences
  ///
  /// In en, this message translates to:
  /// **'Notification Settings'**
  String get notificationSettings;

  /// Option to reduce data usage
  ///
  /// In en, this message translates to:
  /// **'Data Saver Mode'**
  String get dataSaverMode;

  /// Title for parental control settings
  ///
  /// In en, this message translates to:
  /// **'Parental Controls'**
  String get parentalControls;

  /// Label for restricted content settings
  ///
  /// In en, this message translates to:
  /// **'Content Restrictions'**
  String get contentRestrictions;

  /// Option to set a viewing time limit
  ///
  /// In en, this message translates to:
  /// **'Watch Time Limit'**
  String get watchTimeLimit;

  /// Option to lock purchases with a PIN or password
  ///
  /// In en, this message translates to:
  /// **'Purchase Lock'**
  String get purchaseLock;

  /// Label for light theme mode
  ///
  /// In en, this message translates to:
  /// **'Light mode'**
  String get lightMode;

  /// Label for dark theme mode
  ///
  /// In en, this message translates to:
  /// **'Dark mode'**
  String get darkMode;

  /// Label for the button to change the app language
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changerLangue;

  /// No description provided for @annuler.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get annuler;

  /// No description provided for @nomProfil.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get nomProfil;

  /// No description provided for @typeProfil.
  ///
  /// In en, this message translates to:
  /// **'Profile type'**
  String get typeProfil;

  /// No description provided for @couleurProfil.
  ///
  /// In en, this message translates to:
  /// **'Profile color'**
  String get couleurProfil;

  /// No description provided for @adulte.
  ///
  /// In en, this message translates to:
  /// **'Adult'**
  String get adulte;

  /// No description provided for @supprimer.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get supprimer;

  /// No description provided for @sauvegarder.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sauvegarder;

  /// No description provided for @choisirProfil.
  ///
  /// In en, this message translates to:
  /// **'choose profile'**
  String get choisirProfil;

  /// No description provided for @afficherClavier.
  ///
  /// In en, this message translates to:
  /// **'Show Keyboard'**
  String get afficherClavier;

  /// No description provided for @masquerClavier.
  ///
  /// In en, this message translates to:
  /// **'Hide Keyboard'**
  String get masquerClavier;

  /// No description provided for @creerProfil.
  ///
  /// In en, this message translates to:
  /// **'Create new profile'**
  String get creerProfil;

  /// No description provided for @profilEnfant.
  ///
  /// In en, this message translates to:
  /// **'Child profile'**
  String get profilEnfant;

  /// No description provided for @creer.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get creer;

  /// No description provided for @quiRegarde.
  ///
  /// In en, this message translates to:
  /// **'Who\'s watching'**
  String get quiRegarde;

  /// No description provided for @profilSelectionne.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profilSelectionne;

  /// No description provided for @selectionne.
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selectionne;

  /// No description provided for @enfant.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get enfant;

  /// No description provided for @ajouter.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get ajouter;

  /// No description provided for @espaceClavier.
  ///
  /// In en, this message translates to:
  /// **'Space'**
  String get espaceClavier;

  /// No description provided for @entreeClavier.
  ///
  /// In en, this message translates to:
  /// **'Enter'**
  String get entreeClavier;

  /// No description provided for @profilDe.
  ///
  /// In en, this message translates to:
  /// **'Profile of'**
  String get profilDe;

  /// No description provided for @telephone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get telephone;

  /// No description provided for @enregistrer.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get enregistrer;

  /// No description provided for @modifier.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get modifier;

  /// No description provided for @supprimerProfil.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get supprimerProfil;

  /// No description provided for @confirmationSuppressionProfil.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this profile?'**
  String get confirmationSuppressionProfil;

  /// No description provided for @profilMisAJour.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profilMisAJour;

  /// No description provided for @profilSupprime.
  ///
  /// In en, this message translates to:
  /// **'Profile deleted successfully'**
  String get profilSupprime;

  /// No description provided for @avatarModifie.
  ///
  /// In en, this message translates to:
  /// **'Avatar modified successfully'**
  String get avatarModifie;

  /// No description provided for @cliquerAvatarModifier.
  ///
  /// In en, this message translates to:
  /// **'Click on the avatar to edit'**
  String get cliquerAvatarModifier;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @connectedDevices.
  ///
  /// In en, this message translates to:
  /// **'Connected Devices'**
  String get connectedDevices;

  /// No description provided for @erreurConnexion.
  ///
  /// In en, this message translates to:
  /// **'Connection error'**
  String get erreurConnexion;

  /// No description provided for @emailAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get emailAlreadyExists;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Check your internet.'**
  String get connectionError;

  /// No description provided for @genericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred, please try again later'**
  String get genericError;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Unable to log in after signup.'**
  String get loginError;

  /// No description provided for @emailOrPasswordIncorrect.
  ///
  /// In en, this message translates to:
  /// **'email Or Password Incorrect'**
  String get emailOrPasswordIncorrect;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @reinitialiserMotDePasse.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get reinitialiserMotDePasse;

  /// No description provided for @nouveauMotDePasse.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get nouveauMotDePasse;

  /// No description provided for @motDePasseCourt.
  ///
  /// In en, this message translates to:
  /// **'Password is too short'**
  String get motDePasseCourt;

  /// No description provided for @confirmerMotDePasse.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmerMotDePasse;

  /// No description provided for @motsDePasseDifferents.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get motsDePasseDifferents;

  /// No description provided for @aucunAppareil.
  ///
  /// In en, this message translates to:
  /// **'No devices connected'**
  String get aucunAppareil;

  /// No description provided for @motDePasseChange.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get motDePasseChange;

  /// No description provided for @actuel.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get actuel;

  /// No description provided for @ajouterProfil.
  ///
  /// In en, this message translates to:
  /// **'Add profile'**
  String get ajouterProfil;

  /// No description provided for @profilPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Main profile'**
  String get profilPrincipal;

  /// No description provided for @profilInvite.
  ///
  /// In en, this message translates to:
  /// **'Guest profile'**
  String get profilInvite;

  /// No description provided for @descriptionProfilEnfant.
  ///
  /// In en, this message translates to:
  /// **'Content suitable for children'**
  String get descriptionProfilEnfant;

  /// No description provided for @descriptionProfilInvite.
  ///
  /// In en, this message translates to:
  /// **'Temporary limited access'**
  String get descriptionProfilInvite;

  /// No description provided for @descriptionProfilPrincipal.
  ///
  /// In en, this message translates to:
  /// **'Full access to all content'**
  String get descriptionProfilPrincipal;

  /// No description provided for @informationsProfil.
  ///
  /// In en, this message translates to:
  /// **'Profile information'**
  String get informationsProfil;

  /// No description provided for @facturation.
  ///
  /// In en, this message translates to:
  /// **'Billing history'**
  String get facturation;

  /// No description provided for @favoris.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favoris;

  /// No description provided for @telechargements.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get telechargements;

  /// No description provided for @controleParental.
  ///
  /// In en, this message translates to:
  /// **'Parental control'**
  String get controleParental;

  /// No description provided for @ageMaximal.
  ///
  /// In en, this message translates to:
  /// **'Maximum age'**
  String get ageMaximal;

  /// No description provided for @definirHeureLimite.
  ///
  /// In en, this message translates to:
  /// **'Set time limit'**
  String get definirHeureLimite;

  /// No description provided for @enregistrerControles.
  ///
  /// In en, this message translates to:
  /// **'Save controls'**
  String get enregistrerControles;

  /// No description provided for @parametres.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get parametres;

  /// No description provided for @appareilsConnectes.
  ///
  /// In en, this message translates to:
  /// **'Connected devices'**
  String get appareilsConnectes;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @invalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get invalidCredentials;

  /// No description provided for @maxConnectionsReached.
  ///
  /// In en, this message translates to:
  /// **'Maximum simultaneous connections reached'**
  String get maxConnectionsReached;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Connection error. Please check your internet access'**
  String get networkError;

  /// No description provided for @timeoutError.
  ///
  /// In en, this message translates to:
  /// **'Connection timed out. Please try again'**
  String get timeoutError;

  /// No description provided for @modifierProfil.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get modifierProfil;

  /// No description provided for @chargementProfils.
  ///
  /// In en, this message translates to:
  /// **'Loading profiles...'**
  String get chargementProfils;

  /// No description provided for @selectionAge.
  ///
  /// In en, this message translates to:
  /// **'Select an age'**
  String get selectionAge;

  /// No description provided for @ageActuel.
  ///
  /// In en, this message translates to:
  /// **'Current age'**
  String get ageActuel;

  /// No description provided for @erreurInattendue.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get erreurInattendue;

  /// No description provided for @ageModifie.
  ///
  /// In en, this message translates to:
  /// **'Age updated successfully'**
  String get ageModifie;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @nonDefini.
  ///
  /// In en, this message translates to:
  /// **'Undefined'**
  String get nonDefini;

  /// No description provided for @impossibleSupprimerProfilAjouter.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the Add Profile card'**
  String get impossibleSupprimerProfilAjouter;

  /// No description provided for @impossibleSupprimerDernierProfil.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete the last profile'**
  String get impossibleSupprimerDernierProfil;

  /// No description provided for @confirmerSuppressionProfil.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the profile'**
  String get confirmerSuppressionProfil;

  /// No description provided for @erreurSuppressionProfil.
  ///
  /// In en, this message translates to:
  /// **'Error while deleting profile'**
  String get erreurSuppressionProfil;

  /// No description provided for @maximumProfilsAtteint.
  ///
  /// In en, this message translates to:
  /// **'Maximum of 4 profiles reached'**
  String get maximumProfilsAtteint;

  /// No description provided for @maximumProfils.
  ///
  /// In en, this message translates to:
  /// **'(Maximum 4 profiles)'**
  String get maximumProfils;

  /// No description provided for @profil.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profil;

  /// No description provided for @aucuneFacture.
  ///
  /// In en, this message translates to:
  /// **'No invoice available'**
  String get aucuneFacture;

  /// No description provided for @aucunFavori.
  ///
  /// In en, this message translates to:
  /// **'No favorites yet'**
  String get aucunFavori;

  /// No description provided for @aucunTelechargement.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get aucunTelechargement;

  /// No description provided for @modifierMotDePasse.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get modifierMotDePasse;

  /// No description provided for @motDePasseActuel.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get motDePasseActuel;

  /// FAQ category for account questions
  ///
  /// In en, this message translates to:
  /// **'Account & Profile'**
  String get faqCategoryAccount;

  /// FAQ category for subscription questions
  ///
  /// In en, this message translates to:
  /// **'Subscription & Payment'**
  String get faqCategorySubscription;

  /// FAQ category for content questions
  ///
  /// In en, this message translates to:
  /// **'Content & Streaming'**
  String get faqCategoryContent;

  /// FAQ category for technical questions
  ///
  /// In en, this message translates to:
  /// **'Technical Support'**
  String get faqCategoryTechnical;

  /// FAQ question about account creation
  ///
  /// In en, this message translates to:
  /// **'How do I create an account on EkeFlicks?'**
  String get faqQuestion1;

  /// Answer to account creation question
  ///
  /// In en, this message translates to:
  /// **'To create an account, click the \'Sign Up\' button in the top right corner of the homepage. Fill out the form with your email, a secure password, and your personal information. You will receive a confirmation email to activate your account.'**
  String get faqAnswer1;

  /// FAQ question about profile modification
  ///
  /// In en, this message translates to:
  /// **'Can I modify my profile information?'**
  String get faqQuestion2;

  /// Answer to profile modification question
  ///
  /// In en, this message translates to:
  /// **'Yes, you can modify your profile at any time. Go to \'My Account\' from the navigation menu. You can change your profile picture, name, email, and notification preferences.'**
  String get faqAnswer2;

  /// FAQ question about family profiles
  ///
  /// In en, this message translates to:
  /// **'How do I create family profiles?'**
  String get faqQuestion3;

  /// Answer to family profiles question
  ///
  /// In en, this message translates to:
  /// **'EkeFlicks allows up to 5 profiles per account. In \'Profile Management\', click \'Add Profile\'. You can create child profiles with appropriate content restrictions, or adult profiles for other family members.'**
  String get faqAnswer3;

  /// FAQ question about payment methods
  ///
  /// In en, this message translates to:
  /// **'What payment methods are accepted?'**
  String get faqQuestion4;

  /// Answer to payment methods question
  ///
  /// In en, this message translates to:
  /// **'We accept credit cards (Visa, MasterCard, American Express), debit cards, PayPal, and e-wallets depending on your region. All payments are secure and encrypted.'**
  String get faqAnswer4;

  /// FAQ question about cancellation
  ///
  /// In en, this message translates to:
  /// **'How do I cancel my subscription?'**
  String get faqQuestion5;

  /// Answer to cancellation question
  ///
  /// In en, this message translates to:
  /// **'You can cancel at any time without fees. Go to \'My Subscription\' in your account settings, click \'Manage Subscription\' and follow the instructions. Your access will remain active until the end of the paid period.'**
  String get faqAnswer5;

  /// FAQ question about refunds
  ///
  /// In en, this message translates to:
  /// **'Do you offer refunds?'**
  String get faqQuestion6;

  /// Answer to refunds question
  ///
  /// In en, this message translates to:
  /// **'We offer a 14-day satisfaction guarantee for new subscriptions. For existing subscriptions, refunds are evaluated case by case. Contact our customer service for any requests.'**
  String get faqAnswer6;

  /// FAQ question about different plans
  ///
  /// In en, this message translates to:
  /// **'What\'s the difference between the plans?'**
  String get faqQuestion7;

  /// Answer to plans question
  ///
  /// In en, this message translates to:
  /// **'EkeFlicks offers 3 plans: Basic (1 screen, SD), Standard (2 screens, HD), and Premium (4 screens, 4K UHD). All include full access to our catalog and offline downloads.'**
  String get faqAnswer7;

  /// FAQ question about downloads
  ///
  /// In en, this message translates to:
  /// **'Can I download content to watch offline?'**
  String get faqQuestion8;

  /// Answer to downloads question
  ///
  /// In en, this message translates to:
  /// **'Yes! Most movies and series can be downloaded for offline viewing. Look for the download icon next to content. Downloads are available for 30 days once started, and 48 hours after playback begins.'**
  String get faqAnswer8;

  /// FAQ question about available languages
  ///
  /// In en, this message translates to:
  /// **'Is content available in all languages?'**
  String get faqQuestion9;

  /// Answer to languages question
  ///
  /// In en, this message translates to:
  /// **'Our catalog offers dubbing and subtitles in French, English, Spanish, and several African languages depending on content. Availability varies by licenses. You can change the language in playback settings.'**
  String get faqAnswer9;

  /// FAQ question about compatible devices
  ///
  /// In en, this message translates to:
  /// **'On how many devices can I use my account?'**
  String get faqQuestion10;

  /// Answer to devices question
  ///
  /// In en, this message translates to:
  /// **'You can use EkeFlicks on as many devices as you want, but the number of simultaneous screens depends on your plan: 1 for Basic, 2 for Standard, 4 for Premium. Compatible with smartphones, tablets, TVs, computers.'**
  String get faqAnswer10;

  /// FAQ question about technical issues
  ///
  /// In en, this message translates to:
  /// **'What to do if I have playback issues?'**
  String get faqQuestion11;

  /// Answer to technical issues question
  ///
  /// In en, this message translates to:
  /// **'If you encounter problems: 1) Check your internet connection 2) Restart the app 3) Update the app 4) Clear cache. If the problem persists, contact our technical support with error details.'**
  String get faqAnswer11;

  /// FAQ question about customer support
  ///
  /// In en, this message translates to:
  /// **'How to contact customer support?'**
  String get faqQuestion12;

  /// Answer to customer support question
  ///
  /// In en, this message translates to:
  /// **'Our support team is available 24/7 via live chat, email at support@ekeflicks.com, or phone at +33 1 23 45 67 89. Average response time: less than 2 hours for chat, 24 hours for emails.'**
  String get faqAnswer12;

  /// Tutorials page title
  ///
  /// In en, this message translates to:
  /// **'Tutorials'**
  String get tutoriels;

  /// No description provided for @tutorial1Title.
  ///
  /// In en, this message translates to:
  /// **'Getting Started with EkeFlicks'**
  String get tutorial1Title;

  /// No description provided for @tutorial1Desc.
  ///
  /// In en, this message translates to:
  /// **'Learn how to set up your account and navigate the app'**
  String get tutorial1Desc;

  /// No description provided for @tutorial2Title.
  ///
  /// In en, this message translates to:
  /// **'Family Profiles Management'**
  String get tutorial2Title;

  /// No description provided for @tutorial2Desc.
  ///
  /// In en, this message translates to:
  /// **'Learn to create and manage profiles for all family members'**
  String get tutorial2Desc;

  /// No description provided for @tutorial3Title.
  ///
  /// In en, this message translates to:
  /// **'Offline Downloads'**
  String get tutorial3Title;

  /// No description provided for @tutorial3Desc.
  ///
  /// In en, this message translates to:
  /// **'Complete guide to download your favorite content'**
  String get tutorial3Desc;

  /// No description provided for @tutorial4Title.
  ///
  /// In en, this message translates to:
  /// **'Parental Controls Settings'**
  String get tutorial4Title;

  /// No description provided for @tutorial4Desc.
  ///
  /// In en, this message translates to:
  /// **'Configure content restrictions for child profiles'**
  String get tutorial4Desc;

  /// No description provided for @tutorial5Title.
  ///
  /// In en, this message translates to:
  /// **'Video Quality Optimization'**
  String get tutorial5Title;

  /// No description provided for @tutorial5Desc.
  ///
  /// In en, this message translates to:
  /// **'Adjust settings for the best streaming experience'**
  String get tutorial5Desc;
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
