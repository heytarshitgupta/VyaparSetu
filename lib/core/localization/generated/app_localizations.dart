import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
    Locale('hi'),
    Locale('pa'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'VyaparSetu'**
  String get appTitle;

  /// Brand subtitle describing purpose
  ///
  /// In en, this message translates to:
  /// **'Connecting artisan producers directly with commercial buyers across India'**
  String get appSubtitle;

  /// Role selection prompt
  ///
  /// In en, this message translates to:
  /// **'Choose how you want to continue:'**
  String get chooseHowToContinue;

  /// Role option for buyers
  ///
  /// In en, this message translates to:
  /// **'I Want to Buy Products'**
  String get roleBuyerTitle;

  /// Description for buyer role
  ///
  /// In en, this message translates to:
  /// **'Discover products and connect with producers'**
  String get roleBuyerDescription;

  /// Role option for artisan producers
  ///
  /// In en, this message translates to:
  /// **'I Make & Sell Products'**
  String get roleProducerTitle;

  /// Description for producer role
  ///
  /// In en, this message translates to:
  /// **'Create your profile and reach more buyers'**
  String get roleProducerDescription;

  /// Footer note on role selection
  ///
  /// In en, this message translates to:
  /// **'You can switch or register anytime with your phone or email.'**
  String get roleSelectionFooter;

  /// Navigation item for home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Navigation item or header for producer products
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// Button to add a new product
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// Navigation item for incoming buyer requirements and orders
  ///
  /// In en, this message translates to:
  /// **'Buyer Needs'**
  String get buyerNeeds;

  /// Navigation item for market demand and high-selling craft insights
  ///
  /// In en, this message translates to:
  /// **'What Buyers Want'**
  String get whatBuyersWant;

  /// Navigation item or header for producer profile
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get myProfile;

  /// Navigation item or header for app settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Greeting on dashboard or home
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Generic continue action button
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Generic back action button
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Generic save action button
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Generic cancel action button
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic verify action button
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Badge or status label for verified status
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Badge or status label for unverified status
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get notVerified;

  /// Header for sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signInTitle;

  /// Subtitle on sign in screen
  ///
  /// In en, this message translates to:
  /// **'Sign in to manage your products, view buyer needs, and track orders.'**
  String get signInSubtitle;

  /// Header for create account screen
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// Subtitle on create account screen
  ///
  /// In en, this message translates to:
  /// **'Start your journey as an artisan producer and reach direct commercial buyers.'**
  String get createAccountSubtitle;

  /// Full name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// Hint for full name input
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Kumar'**
  String get fullNameHint;

  /// Email address label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// Hint for email address input
  ///
  /// In en, this message translates to:
  /// **'producer@example.com'**
  String get emailHint;

  /// Password label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Hint for password input
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Hint when creating new password
  ///
  /// In en, this message translates to:
  /// **'Create a password (min 6 characters)'**
  String get createPasswordHint;

  /// Confirm password label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Hint for confirm password input
  ///
  /// In en, this message translates to:
  /// **'Re-enter your password'**
  String get confirmPasswordHint;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Button for alternate phone sign in
  ///
  /// In en, this message translates to:
  /// **'Sign in with Phone OTP'**
  String get signInWithPhone;

  /// Button for alternate phone sign up
  ///
  /// In en, this message translates to:
  /// **'Sign up with Phone OTP'**
  String get signUpWithPhone;

  /// Prompt for new users without account
  ///
  /// In en, this message translates to:
  /// **'New here? '**
  String get newHere;

  /// Prompt for users with existing account
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get alreadyHaveAccount;

  /// Validation error for missing full name
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get enterFullName;

  /// Validation error for short name
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters'**
  String get nameTooShort;

  /// Validation error for missing email
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address'**
  String get enterEmail;

  /// Validation error for invalid email
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmail;

  /// Validation error for missing password
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get enterPassword;

  /// Validation error when creating password
  ///
  /// In en, this message translates to:
  /// **'Please create a password'**
  String get createPassword;

  /// Validation error for short password
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// Validation error for missing confirm password
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get confirmYourPassword;

  /// Validation error when passwords differ
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Notice for upcoming phone login feature
  ///
  /// In en, this message translates to:
  /// **'Phone login will be available in the next update.'**
  String get phoneFeatureUpcoming;

  /// Notice for upcoming password recovery
  ///
  /// In en, this message translates to:
  /// **'Password recovery will be available in a future update.'**
  String get forgotPasswordUpcoming;

  /// Label for language selector
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Label for appearance or theme selector
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Title for appearance selection sheet
  ///
  /// In en, this message translates to:
  /// **'Choose appearance'**
  String get chooseAppearance;

  /// Light appearance mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark appearance mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Appearance mode following system/phone setting
  ///
  /// In en, this message translates to:
  /// **'Use phone setting'**
  String get themeSystem;

  /// Screen title for producer onboarding
  ///
  /// In en, this message translates to:
  /// **'Producer Setup'**
  String get producerSetup;

  /// Exit button label
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// Progress step indicator
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepOf(int current, int total);

  /// Progress percentage indicator
  ///
  /// In en, this message translates to:
  /// **'{percent}% Completed'**
  String percentCompleted(int percent);

  /// Final submit button on onboarding
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// Snackbar shown upon onboarding completion
  ///
  /// In en, this message translates to:
  /// **'Onboarding review submitted. Full submission will be finalized in upcoming steps.'**
  String get onboardingReviewSubmitted;

  /// Step 1 simplified title
  ///
  /// In en, this message translates to:
  /// **'About You'**
  String get step1Title;

  /// Step 1 simplified subtitle
  ///
  /// In en, this message translates to:
  /// **'Your name and contact info'**
  String get step1Subtitle;

  /// Step 2 simplified title
  ///
  /// In en, this message translates to:
  /// **'Your Work'**
  String get step2Title;

  /// Step 2 simplified subtitle
  ///
  /// In en, this message translates to:
  /// **'What you make and sell'**
  String get step2Subtitle;

  /// Step 3 simplified title
  ///
  /// In en, this message translates to:
  /// **'Your Address'**
  String get step3Title;

  /// Step 3 simplified subtitle
  ///
  /// In en, this message translates to:
  /// **'Where your workshop is based'**
  String get step3Subtitle;

  /// Step 4 simplified title
  ///
  /// In en, this message translates to:
  /// **'Verification'**
  String get step4Title;

  /// Step 4 simplified subtitle
  ///
  /// In en, this message translates to:
  /// **'Identity and business details'**
  String get step4Subtitle;

  /// Step 5 simplified title
  ///
  /// In en, this message translates to:
  /// **'Check & Submit'**
  String get step5Title;

  /// Step 5 simplified subtitle
  ///
  /// In en, this message translates to:
  /// **'Confirm and start selling'**
  String get step5Subtitle;

  /// Header inside Step 1 card
  ///
  /// In en, this message translates to:
  /// **'Artisan Basic Details'**
  String get step1Header;

  /// Description inside Step 1 card
  ///
  /// In en, this message translates to:
  /// **'Confirm your primary name and contact information for buyer communications.'**
  String get step1Description;

  /// Full name input label with required star
  ///
  /// In en, this message translates to:
  /// **'Full Name *'**
  String get fullNameLabel;

  /// Full name input hint
  ///
  /// In en, this message translates to:
  /// **'Enter your full name'**
  String get enterFullNameHint;

  /// Full name helper text
  ///
  /// In en, this message translates to:
  /// **'Your name as you want it shown on VyaparSetu'**
  String get fullNameHelper;

  /// Email address label showing login association
  ///
  /// In en, this message translates to:
  /// **'Email Address (Login)'**
  String get emailAddressLogin;

  /// Placeholder when an optional profile field was not provided
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get notProvided;

  /// Badge indicating non-editable field
  ///
  /// In en, this message translates to:
  /// **'Read Only'**
  String get readOnly;

  /// Helper explaining read-only email
  ///
  /// In en, this message translates to:
  /// **'Your login email is managed through your account'**
  String get emailHelper;

  /// Label when phone was verified at auth
  ///
  /// In en, this message translates to:
  /// **'Verified Login Phone'**
  String get verifiedLoginPhone;

  /// Label for contact phone
  ///
  /// In en, this message translates to:
  /// **'Contact Phone Number'**
  String get contactPhoneNumber;

  /// Badge for auth-verified phone
  ///
  /// In en, this message translates to:
  /// **'Verified Auth'**
  String get verifiedAuth;

  /// Helper for verified phone
  ///
  /// In en, this message translates to:
  /// **'This phone number is verified and tied to your login credentials'**
  String get verifiedPhoneHelper;

  /// Hint for contact phone
  ///
  /// In en, this message translates to:
  /// **'Enter 10-digit mobile number'**
  String get enter10DigitPhoneHint;

  /// Helper for contact phone
  ///
  /// In en, this message translates to:
  /// **'Used to contact you about your business (Contact phone only)'**
  String get contactPhoneHelper;

  /// Header inside Step 2 card
  ///
  /// In en, this message translates to:
  /// **'Business & Craft Details'**
  String get step2Header;

  /// Description inside Step 2 card
  ///
  /// In en, this message translates to:
  /// **'Tell buyers about your enterprise, workshop, or home-based artisanal work.'**
  String get step2Description;

  /// Business name input label with required star
  ///
  /// In en, this message translates to:
  /// **'Business / Workshop Name *'**
  String get businessNameLabel;

  /// Business name input hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Sharma Pickles, Punjab Phulkari Works'**
  String get businessNameHint;

  /// Business name helper text
  ///
  /// In en, this message translates to:
  /// **'Name of your business, workshop, or home-based work'**
  String get businessNameHelper;

  /// Craft category label with star
  ///
  /// In en, this message translates to:
  /// **'Craft / Product Category *'**
  String get craftCategoryLabel;

  /// Craft category helper
  ///
  /// In en, this message translates to:
  /// **'Select your main product category so commercial buyers can find you easily'**
  String get craftCategoryHelper;

  /// Custom category label with star
  ///
  /// In en, this message translates to:
  /// **'Specify Your Category *'**
  String get specifyCategory;

  /// Custom category hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Bamboo Crafts, Clay Pottery, Stone Carving'**
  String get specifyCategoryHint;

  /// Custom category helper
  ///
  /// In en, this message translates to:
  /// **'Enter your custom artisanal or product category'**
  String get specifyCategoryHelper;

  /// Bio description label
  ///
  /// In en, this message translates to:
  /// **'Short Description (Optional)'**
  String get shortDescriptionLabel;

  /// Bio description hint
  ///
  /// In en, this message translates to:
  /// **'Tell buyers what you make in a few words (e.g. handwoven cotton stoles using organic natural dyes)'**
  String get shortDescriptionHint;

  /// Bio description helper
  ///
  /// In en, this message translates to:
  /// **'Tell buyers what you make in a few words'**
  String get shortDescriptionHelper;

  /// Category: Food
  ///
  /// In en, this message translates to:
  /// **'Food & Homemade Products'**
  String get catFood;

  /// Category: Handicrafts
  ///
  /// In en, this message translates to:
  /// **'Handicrafts'**
  String get catHandicrafts;

  /// Category: Handloom
  ///
  /// In en, this message translates to:
  /// **'Handloom & Textiles'**
  String get catHandloom;

  /// Category: Clothing
  ///
  /// In en, this message translates to:
  /// **'Clothing & Embroidery'**
  String get catClothing;

  /// Category: Jewellery
  ///
  /// In en, this message translates to:
  /// **'Jewellery & Accessories'**
  String get catJewellery;

  /// Category: Woodwork
  ///
  /// In en, this message translates to:
  /// **'Woodwork'**
  String get catWoodwork;

  /// Category: Metal
  ///
  /// In en, this message translates to:
  /// **'Metal Craft'**
  String get catMetalCraft;

  /// Category: Home Decor
  ///
  /// In en, this message translates to:
  /// **'Home Decor'**
  String get catHomeDecor;

  /// Category: Beauty
  ///
  /// In en, this message translates to:
  /// **'Beauty / Personal Care'**
  String get catBeauty;

  /// Category: Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get catOther;

  /// Header inside Step 3 card
  ///
  /// In en, this message translates to:
  /// **'Workshop Location'**
  String get step3Header;

  /// Description inside Step 3 card
  ///
  /// In en, this message translates to:
  /// **'Provide your workshop or home production address so commercial buyers can calculate logistics and pickup.'**
  String get step3Description;

  /// State dropdown label with required star
  ///
  /// In en, this message translates to:
  /// **'State / Union Territory *'**
  String get stateLabel;

  /// State dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select your state or union territory'**
  String get selectStateHint;

  /// District label with star
  ///
  /// In en, this message translates to:
  /// **'District *'**
  String get districtLabel;

  /// District hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Jaipur, Ludhiana'**
  String get districtHint;

  /// District helper text
  ///
  /// In en, this message translates to:
  /// **'District where you make your products'**
  String get districtHelper;

  /// City or village label with star
  ///
  /// In en, this message translates to:
  /// **'City / Village *'**
  String get cityVillageLabel;

  /// City or village hint
  ///
  /// In en, this message translates to:
  /// **'e.g. Sanganer, Khanna'**
  String get cityVillageHint;

  /// City or village helper
  ///
  /// In en, this message translates to:
  /// **'Your city, town, or village'**
  String get cityVillageHelper;

  /// Pincode label with star
  ///
  /// In en, this message translates to:
  /// **'Pincode *'**
  String get pincodeLabel;

  /// Pincode hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 302029'**
  String get pincodeHint;

  /// Pincode helper
  ///
  /// In en, this message translates to:
  /// **'6-digit postal PIN code (cannot start with 0)'**
  String get pincodeHelper;

  /// Address label with star
  ///
  /// In en, this message translates to:
  /// **'Workshop / Business Address *'**
  String get addressLabel;

  /// Address hint
  ///
  /// In en, this message translates to:
  /// **'Street, landmark, lane, or house/unit details...'**
  String get addressHint;

  /// Address helper
  ///
  /// In en, this message translates to:
  /// **'Where you make or manage your products'**
  String get addressHelper;

  /// Header inside Step 4 card
  ///
  /// In en, this message translates to:
  /// **'Identity & Compliance'**
  String get step4Header;

  /// Description inside Step 4 card
  ///
  /// In en, this message translates to:
  /// **'Verify your details to build trust with buyers.'**
  String get step4Description;

  /// Disclosure banner in Step 4
  ///
  /// In en, this message translates to:
  /// **'Demo verification environment • Verification is simulated in this prototype.'**
  String get demoDisclosure;

  /// Title for PAN card in unverified state
  ///
  /// In en, this message translates to:
  /// **'PAN Verification'**
  String get panVerification;

  /// Badge when PAN is verified
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get panVerified;

  /// Subtitle for PAN card unverified
  ///
  /// In en, this message translates to:
  /// **'Secure identity verification'**
  String get secureIdentityVerification;

  /// Subtitle for PAN card verified
  ///
  /// In en, this message translates to:
  /// **'Verified in demo verification environment'**
  String get verifiedInDemoEnvironment;

  /// Label for verified PAN box
  ///
  /// In en, this message translates to:
  /// **'Verified PAN'**
  String get verifiedPan;

  /// Action to reset and re-enter PAN
  ///
  /// In en, this message translates to:
  /// **'Edit Details'**
  String get editDetails;

  /// Security note under verified PAN
  ///
  /// In en, this message translates to:
  /// **'Your PAN details are securely verified. Plaintext PAN is never stored.'**
  String get panSecurityNote;

  /// PAN number input label with star
  ///
  /// In en, this message translates to:
  /// **'PAN Number *'**
  String get panNumberLabel;

  /// PAN number input hint
  ///
  /// In en, this message translates to:
  /// **'ABCDE1234F'**
  String get panNumberHint;

  /// PAN number helper
  ///
  /// In en, this message translates to:
  /// **'10-character alphanumeric PAN'**
  String get panNumberHelper;

  /// Name as per PAN label with star
  ///
  /// In en, this message translates to:
  /// **'Name as per PAN *'**
  String get nameAsPerPanLabel;

  /// Name as per PAN hint
  ///
  /// In en, this message translates to:
  /// **'Enter name as shown on PAN card'**
  String get nameAsPerPanHint;

  /// Name as per PAN helper
  ///
  /// In en, this message translates to:
  /// **'Must match official PAN records'**
  String get nameAsPerPanHelper;

  /// Date of birth label with star
  ///
  /// In en, this message translates to:
  /// **'Date of Birth *'**
  String get dobLabel;

  /// Date of birth picker hint
  ///
  /// In en, this message translates to:
  /// **'Select Date of Birth (DD/MM/YYYY)'**
  String get selectDobHint;

  /// Privacy shield note above PAN verify button
  ///
  /// In en, this message translates to:
  /// **'Your PAN number is used only for verification and is not stored in plain text.'**
  String get panPrivacyShield;

  /// PAN verify button label
  ///
  /// In en, this message translates to:
  /// **'Verify PAN'**
  String get verifyPan;

  /// Button label during verification
  ///
  /// In en, this message translates to:
  /// **'Checking Details...'**
  String get checkingDetails;

  /// Button label when verification failed
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Title for Aadhaar card
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Verification'**
  String get aadhaarVerification;

  /// Subtitle for Aadhaar card
  ///
  /// In en, this message translates to:
  /// **'Identity verification via authorized service'**
  String get aadhaarSubtitle;

  /// Description on Aadhaar card
  ///
  /// In en, this message translates to:
  /// **'Verify your identity using Aadhaar. Fast, secure, and helps build trust with commercial buyers.'**
  String get aadhaarDescription;

  /// Button label to open Aadhaar dialog
  ///
  /// In en, this message translates to:
  /// **'Verify Aadhaar'**
  String get verifyAadhaar;

  /// Content of Aadhaar dialog
  ///
  /// In en, this message translates to:
  /// **'Aadhaar verification will be available through an authorized verification service. It is not enabled in this prototype.'**
  String get aadhaarDialogContent;

  /// Action button on Aadhaar dialog
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get gotIt;

  /// Title for GST card
  ///
  /// In en, this message translates to:
  /// **'GST Registration'**
  String get gstRegistration;

  /// Subtitle when GST registered is declared
  ///
  /// In en, this message translates to:
  /// **'Declared GST registration'**
  String get gstDeclared;

  /// Subtitle when GST is not declared
  ///
  /// In en, this message translates to:
  /// **'Business tax registration status'**
  String get gstStatusSubtitle;

  /// Question for GST registration
  ///
  /// In en, this message translates to:
  /// **'Are you registered for GST? *'**
  String get areYouGstRegistered;

  /// Yes choice
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No choice
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// Information box when No is chosen for GST
  ///
  /// In en, this message translates to:
  /// **'GST not registered. Micro-producers below registration thresholds can continue without GST.'**
  String get gstNotRegisteredNotice;

  /// GSTIN number label with star
  ///
  /// In en, this message translates to:
  /// **'GSTIN Number *'**
  String get gstinNumberLabel;

  /// GSTIN input hint
  ///
  /// In en, this message translates to:
  /// **'07AAAAA0000A1Z5'**
  String get gstinHint;

  /// GSTIN helper text
  ///
  /// In en, this message translates to:
  /// **'15-character alphanumeric GSTIN'**
  String get gstinHelper;

  /// Button to format-check GSTIN
  ///
  /// In en, this message translates to:
  /// **'Verify GSTIN'**
  String get verifyGstin;

  /// Information message after format-checking GSTIN
  ///
  /// In en, this message translates to:
  /// **'GST verification integration will be added next.'**
  String get gstUpcomingNotice;

  /// Verification badge: not verified
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get badgeNotVerified;

  /// Verification badge: checking
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get badgeChecking;

  /// Verification badge: verified
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get badgeVerified;

  /// Verification badge: could not verify
  ///
  /// In en, this message translates to:
  /// **'Could Not Verify'**
  String get badgeCouldNotVerify;

  /// Verification badge: coming soon
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get badgeComingSoon;

  /// Verification badge: not registered
  ///
  /// In en, this message translates to:
  /// **'Not Registered'**
  String get badgeNotRegistered;

  /// Title on Step 5 review card
  ///
  /// In en, this message translates to:
  /// **'Review & Submit Onboarding'**
  String get step5CardTitle;

  /// Description on Step 5 review card
  ///
  /// In en, this message translates to:
  /// **'Review your profile setup before submitting. You can edit your craft catalog anytime from your dashboard.'**
  String get step5CardDescription;

  /// Label for profile status in review
  ///
  /// In en, this message translates to:
  /// **'Profile Status'**
  String get profileStatus;

  /// Value for ready for submission
  ///
  /// In en, this message translates to:
  /// **'Ready for Submission'**
  String get readyForSubmission;

  /// Label for next stage in review
  ///
  /// In en, this message translates to:
  /// **'Next Stage'**
  String get nextStage;

  /// Value describing direct access after onboarding
  ///
  /// In en, this message translates to:
  /// **'Direct access to Buyer Needs & Products'**
  String get nextStageDescription;

  /// Greeting with producer name
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String welcomeProducer(String name);

  /// Default fallback name for producer
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get producerDefaultName;

  /// Subtitle below producer greeting on Home
  ///
  /// In en, this message translates to:
  /// **'Manage your craft and connect with buyers'**
  String get producerHomeSubtitle;

  /// Subtitle on the primary Add Product action card
  ///
  /// In en, this message translates to:
  /// **'Show buyers what you make'**
  String get addProductActionSubtitle;

  /// Subtitle for My Products shortcut
  ///
  /// In en, this message translates to:
  /// **'See the products you have added'**
  String get myProductsShortcutSubtitle;

  /// Subtitle for Buyer Needs shortcut
  ///
  /// In en, this message translates to:
  /// **'See what buyers are looking for'**
  String get buyerNeedsShortcutSubtitle;

  /// Subtitle for What Buyers Want shortcut
  ///
  /// In en, this message translates to:
  /// **'See what products people want'**
  String get whatBuyersWantShortcutSubtitle;

  /// Title for empty products status card
  ///
  /// In en, this message translates to:
  /// **'No products added yet'**
  String get noProductsListedTitle;

  /// Subtitle for empty products status card
  ///
  /// In en, this message translates to:
  /// **'Add your first product so buyers can discover your craft'**
  String get noProductsListedSubtitle;

  /// Title for waiting buyer needs status card
  ///
  /// In en, this message translates to:
  /// **'Buyer needs will appear here'**
  String get buyerNeedsWaitingTitle;

  /// Subtitle for waiting buyer needs status card
  ///
  /// In en, this message translates to:
  /// **'Buyer requests will be listed here when available'**
  String get buyerNeedsWaitingSubtitle;

  /// Description on placeholder destinations
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in the next update'**
  String get featureComingSoon;

  /// Sign out button label
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOutAction;

  /// Subtitle for My Products header
  ///
  /// In en, this message translates to:
  /// **'Manage the products you make and sell'**
  String get myProductsSubtitle;

  /// Filter tab for all products
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter tab for active products
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get filterActive;

  /// Filter tab for draft products
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get filterDraft;

  /// Filter tab for inactive products
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get filterHidden;

  /// Status badge for active products
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// Status badge for draft products
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// Status badge for hidden/inactive products
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusHidden;

  /// Label when product price is not specified
  ///
  /// In en, this message translates to:
  /// **'Price not set'**
  String get priceNotSet;

  /// Indicator on draft cards that product details are incomplete
  ///
  /// In en, this message translates to:
  /// **'Needs price or details'**
  String get draftNeedsCompletion;

  /// Title when active filter has zero results
  ///
  /// In en, this message translates to:
  /// **'No active products'**
  String get noActiveProductsTitle;

  /// Subtitle when active filter has zero results
  ///
  /// In en, this message translates to:
  /// **'Products ready for listing will appear here'**
  String get noActiveProductsSubtitle;

  /// Title when draft filter has zero results
  ///
  /// In en, this message translates to:
  /// **'No draft products'**
  String get noDraftProductsTitle;

  /// Subtitle when draft filter has zero results
  ///
  /// In en, this message translates to:
  /// **'Products that still need details will appear here'**
  String get noDraftProductsSubtitle;

  /// Title when hidden/inactive filter has zero results
  ///
  /// In en, this message translates to:
  /// **'No inactive products'**
  String get noHiddenProductsTitle;

  /// Subtitle when hidden/inactive filter has zero results
  ///
  /// In en, this message translates to:
  /// **'Products you temporarily hide will appear here'**
  String get noHiddenProductsSubtitle;

  /// Button to clear filters and view all products
  ///
  /// In en, this message translates to:
  /// **'Show All Products'**
  String get showAllProducts;

  /// Error title when product loading fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your products'**
  String get unableToLoadProducts;

  /// Error subtitle when product loading fails
  ///
  /// In en, this message translates to:
  /// **'Please check your connection and try again'**
  String get unableToLoadSubtitle;

  /// Error message when user is not authenticated
  ///
  /// In en, this message translates to:
  /// **'Please sign in to view your products'**
  String get notAuthenticatedMessage;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Action button to hide a product
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hideAction;

  /// Action button to activate/show a product
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showAction;

  /// Action button to delete a product
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// Title of delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Product?'**
  String get deleteProductTitle;

  /// Body message of delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this product? This action cannot be undone.'**
  String get deleteProductConfirmation;

  /// Feedback message when product is hidden
  ///
  /// In en, this message translates to:
  /// **'Product hidden'**
  String get productHiddenSuccess;

  /// Feedback message when product is activated
  ///
  /// In en, this message translates to:
  /// **'Product marked active'**
  String get productActivatedSuccess;

  /// Feedback message when product is deleted
  ///
  /// In en, this message translates to:
  /// **'Product deleted'**
  String get productDeletedSuccess;

  /// Error feedback when updating product status fails
  ///
  /// In en, this message translates to:
  /// **'Unable to update product. Please try again.'**
  String get productActionFailed;

  /// Error feedback when deleting product fails
  ///
  /// In en, this message translates to:
  /// **'Unable to delete product. Please try again.'**
  String get productDeleteFailed;

  /// Progress step indicator text
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String stepCount(int current, int total);

  /// Title for Add Product Step 1
  ///
  /// In en, this message translates to:
  /// **'What do you make?'**
  String get addProductStep1Title;

  /// Title for Add Product Step 2
  ///
  /// In en, this message translates to:
  /// **'Price & Details'**
  String get addProductStep2Title;

  /// Title for Add Product Step 3
  ///
  /// In en, this message translates to:
  /// **'Add Photos & Save'**
  String get addProductStep3Title;

  /// Label for product name input field
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// Placeholder hint for product name
  ///
  /// In en, this message translates to:
  /// **'e.g. Homemade Mango Pickle'**
  String get productNameHint;

  /// Validation error when continuing with empty product name
  ///
  /// In en, this message translates to:
  /// **'Please enter a product name first'**
  String get productNameRequired;

  /// Label for category selector
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// Category option: Food
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// Category option: Handicraft
  ///
  /// In en, this message translates to:
  /// **'Handicraft'**
  String get categoryHandicraft;

  /// Category option: Clothing
  ///
  /// In en, this message translates to:
  /// **'Clothing'**
  String get categoryClothing;

  /// Category option: Home Products
  ///
  /// In en, this message translates to:
  /// **'Home Products'**
  String get categoryHome;

  /// Category option: Beauty & Care
  ///
  /// In en, this message translates to:
  /// **'Beauty & Care'**
  String get categoryBeauty;

  /// Category option: Jewellery
  ///
  /// In en, this message translates to:
  /// **'Jewellery'**
  String get categoryJewellery;

  /// Category option: Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// Label for custom category text input
  ///
  /// In en, this message translates to:
  /// **'Describe category'**
  String get customCategoryLabel;

  /// Label for production capacity unit dropdown
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// Unit option: Piece
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get unitPiece;

  /// Capacity unit kg
  ///
  /// In en, this message translates to:
  /// **'Kg'**
  String get unitKg;

  /// Unit option: Gram
  ///
  /// In en, this message translates to:
  /// **'Gram (g)'**
  String get unitGram;

  /// Unit option: Litre
  ///
  /// In en, this message translates to:
  /// **'Litre (L)'**
  String get unitLitre;

  /// Unit option: Millilitre
  ///
  /// In en, this message translates to:
  /// **'Millilitre (ml)'**
  String get unitMl;

  /// Unit option: Pack
  ///
  /// In en, this message translates to:
  /// **'Pack'**
  String get unitPack;

  /// Unit option: Dozen
  ///
  /// In en, this message translates to:
  /// **'Dozen'**
  String get unitDozen;

  /// Label for price input field
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get priceLabel;

  /// Helper text for price input
  ///
  /// In en, this message translates to:
  /// **'Enter the price for one unit'**
  String get priceHelper;

  /// Error text for invalid price input
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price (e.g. 250 or 250.50)'**
  String get priceInvalidError;

  /// Label for description field
  ///
  /// In en, this message translates to:
  /// **'Tell buyers about your product'**
  String get descriptionLabel;

  /// Helper text for description field
  ///
  /// In en, this message translates to:
  /// **'What is it made from? What makes it special?'**
  String get descriptionHelper;

  /// Heading for photos step
  ///
  /// In en, this message translates to:
  /// **'Add Photos'**
  String get addPhotosHeading;

  /// Subtitle for photos step
  ///
  /// In en, this message translates to:
  /// **'Photos help buyers see the quality of your craft'**
  String get addPhotosSubtitle;

  /// Temporary message indicating photo picker arrives in next step
  ///
  /// In en, this message translates to:
  /// **'Photo selection will be added next'**
  String get photoUploadComingNext;

  /// Action button to save current product as a draft
  ///
  /// In en, this message translates to:
  /// **'Save Draft'**
  String get saveDraftAction;

  /// Action button to mark product ready/active
  ///
  /// In en, this message translates to:
  /// **'Mark Ready'**
  String get markReadyAction;

  /// Guidance message explaining what is missing to mark product ready
  ///
  /// In en, this message translates to:
  /// **'Add name, category, and price to mark ready'**
  String get markReadyGuidance;

  /// Feedback message when draft is saved
  ///
  /// In en, this message translates to:
  /// **'Draft saved'**
  String get draftSavedMessage;

  /// Feedback message when product is marked active/ready
  ///
  /// In en, this message translates to:
  /// **'Product marked ready'**
  String get productMarkedReadyMessage;

  /// Error feedback when saving draft fails
  ///
  /// In en, this message translates to:
  /// **'Could not save draft. Please try again.'**
  String get saveDraftFailed;

  /// Error feedback when marking ready fails
  ///
  /// In en, this message translates to:
  /// **'Could not mark ready. Please try again.'**
  String get markReadyFailed;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'My Orders'**
  String get myOrders;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Wishlist'**
  String get wishlist;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'My Requirements'**
  String get myRequirements;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Business Information'**
  String get businessInformation;

  /// Label for business name
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for email
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Recent Activity'**
  String get recentActivity;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Quick Links'**
  String get quickLinks;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Added for profile screen
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Bottom navigation bar item
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get navDiscover;

  /// Bottom navigation bar item
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get navSearch;

  /// Bottom navigation bar item
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// Bottom navigation bar item
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Search for Products, Brands and More'**
  String get searchHint;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get allCategories;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Handlooms'**
  String get handlooms;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Spices'**
  String get spices;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Handicrafts'**
  String get handicrafts;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get food;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Gifting'**
  String get gifting;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get forYou;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Textiles'**
  String get textiles;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Recommended For You'**
  String get recommendedForYou;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'VIEW ALL'**
  String get viewAll;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'No products found.'**
  String get noProductsFound;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Order Now'**
  String get orderNow;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Added to wishlist'**
  String get addedToWishlist;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Removed from wishlist'**
  String get removedFromWishlist;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Filter by Category'**
  String get filterByCategory;

  /// Added for Home tab
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'Search products...'**
  String get searchProducts;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'My Cart'**
  String get myCart;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'No Products'**
  String get noProducts;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'No products available in this category yet.'**
  String get noProductsCategory;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get noRequests;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'Post a custom requirement to start receiving quotes from verified producers.'**
  String get noRequestsSub;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'Responses'**
  String get responsesText;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'Receiving Quotes'**
  String get receivingQuotes;

  /// Added for search and requests screen
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get closed;

  /// Header for Step 1 producer signup
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createYourAccountTitle;

  /// Supporting copy for Step 1 producer signup
  ///
  /// In en, this message translates to:
  /// **'Start setting up your business on VyaparSetu.'**
  String get createAccountSupportingCopy;

  /// Header for email OTP verification screen
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmailTitle;

  /// Subtitle on email OTP screen showing masked email
  ///
  /// In en, this message translates to:
  /// **'We sent a 6-digit code to {email}'**
  String verifyYourEmailSubtitle(String email);

  /// Label above 6-digit OTP input
  ///
  /// In en, this message translates to:
  /// **'Enter 6-digit verification code'**
  String get enterOtpPrompt;

  /// Primary action button to verify OTP
  ///
  /// In en, this message translates to:
  /// **'Verify & Continue'**
  String get verifyAndContinue;

  /// Button to resend email verification code
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Cooldown indicator on resend button
  ///
  /// In en, this message translates to:
  /// **'Resend Code in {seconds}s'**
  String resendCodeIn(int seconds);

  /// Button to go back and change email address
  ///
  /// In en, this message translates to:
  /// **'Change Email'**
  String get changeEmail;

  /// Error shown when OTP is fewer than 6 digits
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit code'**
  String get otpInvalidLength;

  /// Error shown when OTP verification fails
  ///
  /// In en, this message translates to:
  /// **'That code is incorrect or has expired.'**
  String get otpIncorrectOrExpired;

  /// Success message when OTP is resent
  ///
  /// In en, this message translates to:
  /// **'A new 6-digit code has been sent to your email.'**
  String get otpSentSuccess;

  /// Filter tab for inactive products
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get filterInactive;

  /// Status badge for inactive products
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get statusInactive;

  /// Action button to edit a product
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editAction;

  /// Action button to continue editing a draft product
  ///
  /// In en, this message translates to:
  /// **'Continue Editing'**
  String get continueEditingAction;

  /// Action button to save edits to an existing product
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChangesAction;

  /// Action button to make an inactive product active
  ///
  /// In en, this message translates to:
  /// **'Make Active'**
  String get makeActiveAction;

  /// Action button to make an active product inactive
  ///
  /// In en, this message translates to:
  /// **'Make Inactive'**
  String get makeInactiveAction;

  /// Modal title when editing an existing product
  ///
  /// In en, this message translates to:
  /// **'Edit Product'**
  String get editProductTitle;

  /// Modal subtitle when editing an existing product
  ///
  /// In en, this message translates to:
  /// **'Update your product details and photos'**
  String get editProductHelper;

  /// Confirmation title when deleting a product
  ///
  /// In en, this message translates to:
  /// **'Delete product?'**
  String get deleteProductConfirmTitle;

  /// Confirmation body when deleting a product
  ///
  /// In en, this message translates to:
  /// **'This will permanently remove this product and its photos.'**
  String get deleteProductConfirmBody;

  /// Toast message when product details are updated
  ///
  /// In en, this message translates to:
  /// **'Product updated'**
  String get productUpdatedSuccess;

  /// Toast message when product is made active
  ///
  /// In en, this message translates to:
  /// **'Product made active'**
  String get productMadeActiveSuccess;

  /// Toast message when product is made inactive
  ///
  /// In en, this message translates to:
  /// **'Product made inactive'**
  String get productMadeInactiveSuccess;

  /// Error toast when product update fails
  ///
  /// In en, this message translates to:
  /// **'Could not update product'**
  String get couldNotUpdateProduct;

  /// Error toast when product photo fails to load
  ///
  /// In en, this message translates to:
  /// **'Could not load product photo'**
  String get couldNotLoadProductPhoto;

  /// Guidance toast when trying to activate an incomplete product
  ///
  /// In en, this message translates to:
  /// **'Please edit product to fill name, category, and price before making it active.'**
  String get incompleteProductCannotActivate;

  /// Title when inactive filter has zero results
  ///
  /// In en, this message translates to:
  /// **'No inactive products'**
  String get noInactiveProductsTitle;

  /// Subtitle when inactive filter has zero results
  ///
  /// In en, this message translates to:
  /// **'Products you mark as inactive will appear here'**
  String get noInactiveProductsSubtitle;

  /// Subtitle for What Buyers Want screen
  ///
  /// In en, this message translates to:
  /// **'See sample market demand trends from different places.'**
  String get whatBuyersWantSubtitle;

  /// Badge indicating market intelligence signals are sample data
  ///
  /// In en, this message translates to:
  /// **'Sample market insights'**
  String get sampleMarketInsightsBadge;

  /// Note clarifying that market trends are sample data
  ///
  /// In en, this message translates to:
  /// **'These regional trends are based on sample market activity to help you understand buyer interest.'**
  String get sampleMarketInsightsNote;

  /// High market demand label
  ///
  /// In en, this message translates to:
  /// **'High demand'**
  String get demandHigh;

  /// Medium market demand label
  ///
  /// In en, this message translates to:
  /// **'Medium demand'**
  String get demandMedium;

  /// Low market demand label
  ///
  /// In en, this message translates to:
  /// **'Low demand'**
  String get demandLow;

  /// Demand score out of 100
  ///
  /// In en, this message translates to:
  /// **'{score}/100'**
  String demandScoreOutOf(String score);

  /// Label for product district in market intelligence
  ///
  /// In en, this message translates to:
  /// **'District: {district}'**
  String signalDistrictLabel(String district);

  /// Label for top purchasing city
  ///
  /// In en, this message translates to:
  /// **'Top buying city: {city}'**
  String topBuyingCityLabel(String city);

  /// Label for estimated monthly demand
  ///
  /// In en, this message translates to:
  /// **'Estimated monthly demand'**
  String get estimatedMonthlyDemandLabel;

  /// Formatted units count
  ///
  /// In en, this message translates to:
  /// **'{count} units'**
  String estimatedUnitsValue(String count);

  /// Label for typical order value
  ///
  /// In en, this message translates to:
  /// **'Typical order value'**
  String get typicalOrderValueLabel;

  /// Category: Agriculture
  ///
  /// In en, this message translates to:
  /// **'Agriculture'**
  String get categoryAgriculture;

  /// Category: Textile
  ///
  /// In en, this message translates to:
  /// **'Textile'**
  String get categoryTextile;

  /// Category: Food processing
  ///
  /// In en, this message translates to:
  /// **'Food processing'**
  String get categoryFoodProcessing;

  /// Category: Manufacturing
  ///
  /// In en, this message translates to:
  /// **'Manufacturing'**
  String get categoryManufacturing;

  /// Empty state message when no market signals are present
  ///
  /// In en, this message translates to:
  /// **'No market insights available yet.'**
  String get noMarketInsights;

  /// Option to take a photo using the device camera
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhotoAction;

  /// Option to select a photo from device photo library
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGalleryAction;

  /// Progress message while image is uploading
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get uploadingPhotoProgress;

  /// Tooltip/button to remove a photo
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhotoAction;

  /// Error message when image upload fails
  ///
  /// In en, this message translates to:
  /// **'Photo could not be uploaded. Please try again.'**
  String get photoUploadFailed;

  /// Error message when chosen photo format is unsupported
  ///
  /// In en, this message translates to:
  /// **'Unsupported photo format. Please select a JPEG, PNG, or WebP photo.'**
  String get unsupportedPhotoFormat;

  /// Error message when chosen photo exceeds 5 MB
  ///
  /// In en, this message translates to:
  /// **'Photo exceeds 5 MB limit. Please select a smaller photo.'**
  String get photoTooLarge;

  /// Notice when 4 photos have been added
  ///
  /// In en, this message translates to:
  /// **'Maximum 4 photos reached'**
  String get maxPhotosReached;

  /// Prompt asking the user to choose another image
  ///
  /// In en, this message translates to:
  /// **'Please choose another photo'**
  String get tryAnotherPhoto;

  /// Confirmation prompt before deleting a photo
  ///
  /// In en, this message translates to:
  /// **'Do you want to remove this photo?'**
  String get removePhotoConfirmation;

  /// Snackbar message when a photo is removed
  ///
  /// In en, this message translates to:
  /// **'Photo removed'**
  String get photoRemovedMessage;

  /// Title of the photo source selection bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Add Product Photo'**
  String get choosePhotoSource;

  /// Confirm button text to delete a photo
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deletePhoto;

  /// Error message when product must be saved before uploading photos
  ///
  /// In en, this message translates to:
  /// **'Please save product draft before adding photos'**
  String get productMustBeSavedBeforePhotos;

  /// Button label to improve a photo using AI
  ///
  /// In en, this message translates to:
  /// **'Improve Photo'**
  String get improvePhotoAction;

  /// Loading message when AI is processing photo
  ///
  /// In en, this message translates to:
  /// **'Improving photo...'**
  String get improvingPhotoProgress;

  /// Label for the original product photo
  ///
  /// In en, this message translates to:
  /// **'Original'**
  String get originalPhotoLabel;

  /// Label for the AI-improved product photo
  ///
  /// In en, this message translates to:
  /// **'Improved'**
  String get improvedPhotoLabel;

  /// Action to discard AI changes and keep original photo
  ///
  /// In en, this message translates to:
  /// **'Keep Original'**
  String get keepOriginalAction;

  /// Action to accept AI improved photo
  ///
  /// In en, this message translates to:
  /// **'Use Improved Photo'**
  String get useImprovedAction;

  /// Dialog or section title when photo has been improved by AI
  ///
  /// In en, this message translates to:
  /// **'Photo Improved'**
  String get photoImprovedTitle;

  /// Error message when AI photo improvement fails
  ///
  /// In en, this message translates to:
  /// **'Could not improve photo. Please try again.'**
  String get photoImproveFailed;

  /// Truthfulness disclaimer for AI photo improvement
  ///
  /// In en, this message translates to:
  /// **'AI improves only the presentation, not your product.'**
  String get aiImproveDisclaimer;

  /// Explanation of what AI photo improvement accomplishes
  ///
  /// In en, this message translates to:
  /// **'Cleans background, improves lighting, and centers the product.'**
  String get aiImproveHelpText;

  /// Title for the photo comparison screen or dialog
  ///
  /// In en, this message translates to:
  /// **'Compare Photos'**
  String get comparePhotosTitle;

  /// Confirmation message when improved photo is selected
  ///
  /// In en, this message translates to:
  /// **'Improved photo applied'**
  String get photoImproveSuccessMessage;

  /// Title for product photos section in Add Product sheet
  ///
  /// In en, this message translates to:
  /// **'Product Photos'**
  String get productPhotosTitle;

  /// Validation message when attempting to add photos without a product name
  ///
  /// In en, this message translates to:
  /// **'Add a product name before adding photos.'**
  String get addPhotosNameFirst;

  /// Action label to choose a photo on web or single-source platforms
  ///
  /// In en, this message translates to:
  /// **'Choose Photo'**
  String get choosePhotoAction;

  /// Friendly subtitle helper for Add Product sheet
  ///
  /// In en, this message translates to:
  /// **'Enter product details, price, and optional photos.'**
  String get addProductHelper;

  /// Title for confirmation dialog when closing form with unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get discardChangesTitle;

  /// Message for confirmation dialog when closing form with unsaved changes
  ///
  /// In en, this message translates to:
  /// **'Your unsaved product details will be lost.'**
  String get discardChangesMessage;

  /// Action button to keep editing when prompted to discard changes
  ///
  /// In en, this message translates to:
  /// **'Keep Editing'**
  String get keepEditingAction;

  /// Action button to discard changes and close modal
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discardAction;

  /// Error message when device/platform photo picker is not available
  ///
  /// In en, this message translates to:
  /// **'Photo picker is not available on this device. Please restart the application.'**
  String get pickerUnavailableError;

  /// Error message when product image storage service is unavailable
  ///
  /// In en, this message translates to:
  /// **'Image storage service is not available.'**
  String get storageUnavailableError;

  /// Title for product details view
  ///
  /// In en, this message translates to:
  /// **'Product Details'**
  String get productDetailsTitle;

  /// Placeholder text when product description is empty
  ///
  /// In en, this message translates to:
  /// **'No description added'**
  String get noDescriptionAdded;

  /// Menu action to delete a product
  ///
  /// In en, this message translates to:
  /// **'Delete Product'**
  String get deleteProductAction;

  /// Header for verification and compliance section
  ///
  /// In en, this message translates to:
  /// **'Verification & Compliance'**
  String get verificationAndCompliance;

  /// Header for business and producer info section
  ///
  /// In en, this message translates to:
  /// **'Business & Producer Details'**
  String get businessProducerInfo;

  /// Header for account and security section
  ///
  /// In en, this message translates to:
  /// **'Account & Security'**
  String get accountAndSecurity;

  /// Header for help and about section
  ///
  /// In en, this message translates to:
  /// **'Help & About'**
  String get helpAndAbout;

  /// Label for voice guidance language setting
  ///
  /// In en, this message translates to:
  /// **'Voice Guidance Language'**
  String get voiceGuidanceLanguage;

  /// Voice guidance option matching app language
  ///
  /// In en, this message translates to:
  /// **'Same as App Language'**
  String get voiceGuidanceSameAsApp;

  /// Badge for verified producer
  ///
  /// In en, this message translates to:
  /// **'Verified Producer'**
  String get verifiedProducer;

  /// Badge for unverified producer
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get unverifiedProducer;

  /// Badge when PAN is not verified
  ///
  /// In en, this message translates to:
  /// **'Not Verified'**
  String get panNotVerified;

  /// Status when identity verification is complete
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get identityVerified;

  /// Status when identity verification is pending
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get identityNotVerified;

  /// Badge when GST is registered
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get gstRegisteredBadge;

  /// Badge when GST is not registered
  ///
  /// In en, this message translates to:
  /// **'Not Registered'**
  String get gstNotRegisteredBadge;

  /// Label for Aadhaar status row
  ///
  /// In en, this message translates to:
  /// **'Aadhaar Identity'**
  String get aadhaarStatusLabel;

  /// Label for PAN identity row
  ///
  /// In en, this message translates to:
  /// **'PAN Identity'**
  String get panIdentityLabel;

  /// Label for GST compliance row
  ///
  /// In en, this message translates to:
  /// **'GST'**
  String get gstComplianceLabel;

  /// Label for workshop location
  ///
  /// In en, this message translates to:
  /// **'Workshop Location'**
  String get workshopLocationLabel;

  /// Section title for business location in onboarding
  ///
  /// In en, this message translates to:
  /// **'Business Location'**
  String get businessLocationTitle;

  /// Action to reset account password
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Description for reset password action
  ///
  /// In en, this message translates to:
  /// **'Send password reset instructions to your registered email'**
  String get resetPasswordDesc;

  /// Confirmation when reset password email is dispatched
  ///
  /// In en, this message translates to:
  /// **'Password reset link sent to your email'**
  String get resetPasswordSuccess;

  /// Label for current session
  ///
  /// In en, this message translates to:
  /// **'Current Session'**
  String get activeSession;

  /// Description for signed in session status
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get activeSessionTruthful;

  /// Title of sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Sign out of VyaparSetu?'**
  String get signOutConfirmTitle;

  /// Body message of sign out confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get signOutConfirmMessage;

  /// Title for how vyaparsetu works info dialog
  ///
  /// In en, this message translates to:
  /// **'How VyaparSetu Works'**
  String get howVyaparSetuWorks;

  /// Description text for how vyaparsetu works
  ///
  /// In en, this message translates to:
  /// **'VyaparSetu connects artisan producers directly with verified bulk and retail buyers. Add your products, share photos, and respond to buyer inquiries with complete transparency.'**
  String get howVyaparSetuWorksContent;

  /// Title for privacy and data info dialog
  ///
  /// In en, this message translates to:
  /// **'Privacy & Data'**
  String get privacyAndData;

  /// Description text for privacy and data
  ///
  /// In en, this message translates to:
  /// **'Sensitive identity information is minimized. Raw PAN is not displayed in the app. Aadhaar numbers are not displayed or carried in the Profile UI. Access to producer data is protected by authentication and database ownership policies.'**
  String get privacyAndDataContent;

  /// Title for about vyaparsetu info dialog
  ///
  /// In en, this message translates to:
  /// **'About VyaparSetu'**
  String get aboutVyaparSetu;

  /// Description text for about vyaparsetu
  ///
  /// In en, this message translates to:
  /// **'VyaparSetu v1.0 — Empowering Indian artisan producers and manufacturers through direct commerce, localization, and trusted verification.'**
  String get aboutVyaparSetuContent;

  /// Label for contact phone
  ///
  /// In en, this message translates to:
  /// **'Contact Phone'**
  String get phoneLabel;

  /// Accessibility and tooltip for quick action menu
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickMenuTitle;

  /// Button label for OK
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Label for craft category
  ///
  /// In en, this message translates to:
  /// **'Craft Category'**
  String get craftCategory;

  /// Label for identity verification
  ///
  /// In en, this message translates to:
  /// **'Identity Verification'**
  String get identityVerification;

  /// Role badge for producer
  ///
  /// In en, this message translates to:
  /// **'Producer'**
  String get producerRoleBadge;

  /// Button to sign in using email OTP
  ///
  /// In en, this message translates to:
  /// **'Sign in with OTP'**
  String get signInWithEmailOtp;

  /// Divider text between login methods
  ///
  /// In en, this message translates to:
  /// **'OR'**
  String get orDivider;

  /// Title for OTP sign-in verification stage
  ///
  /// In en, this message translates to:
  /// **'Check Your Email'**
  String get checkYourEmailTitle;

  /// Subtitle for OTP sign-in showing masked email
  ///
  /// In en, this message translates to:
  /// **'We sent a verification code to {email}'**
  String checkYourEmailSubtitle(String email);

  /// Primary action button for OTP sign-in
  ///
  /// In en, this message translates to:
  /// **'Verify & Sign In'**
  String get verifyAndSignIn;

  /// Title for password recovery email entry
  ///
  /// In en, this message translates to:
  /// **'Reset Your Password'**
  String get forgotPasswordTitle;

  /// Subtitle for password recovery email entry
  ///
  /// In en, this message translates to:
  /// **'Enter your email address to receive a recovery code.'**
  String get forgotPasswordSubtitle;

  /// Button to request password recovery code
  ///
  /// In en, this message translates to:
  /// **'Send Recovery Code'**
  String get sendRecoveryCode;

  /// Account enumeration safe notice after requesting recovery
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, we\'ve sent a verification code.'**
  String get recoveryEmailSentNeutralNotice;

  /// Subtitle for recovery OTP verification showing masked email
  ///
  /// In en, this message translates to:
  /// **'Enter the verification code sent to {email}'**
  String enterRecoveryCodeSubtitle(String email);

  /// Button to verify recovery OTP code
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get verifyCode;

  /// Title for set new password stage
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPasswordTitle;

  /// Subtitle for set new password stage
  ///
  /// In en, this message translates to:
  /// **'Create a new strong password for your account.'**
  String get createNewPasswordSubtitle;

  /// Label for new password input
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Hint for new password input
  ///
  /// In en, this message translates to:
  /// **'Enter new password (min 6 characters)'**
  String get newPasswordHint;

  /// Primary action button to update password
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// Success message after password is updated
  ///
  /// In en, this message translates to:
  /// **'Your password has been updated.'**
  String get passwordUpdatedSuccess;

  /// Error message when trying to sign in with OTP for an unregistered email
  ///
  /// In en, this message translates to:
  /// **'No account found with this email. Try signing up.'**
  String get noAccountFoundWithEmail;

  /// Title for the Your Business onboarding step
  ///
  /// In en, this message translates to:
  /// **'Your Business'**
  String get yourBusinessTitle;

  /// Subtitle for the Your Business onboarding step
  ///
  /// In en, this message translates to:
  /// **'Tell us a little about what you make and where your business is based.'**
  String get yourBusinessSubtitle;

  /// Title for the optional About Your Business onboarding step
  ///
  /// In en, this message translates to:
  /// **'About Your Business'**
  String get aboutYourBusinessTitle;

  /// Subtitle for the optional About Your Business onboarding step
  ///
  /// In en, this message translates to:
  /// **'Help us understand your business better. You can skip this step.'**
  String get aboutYourBusinessSubtitle;

  /// Placeholder text for About Your Business step in Pass 3A
  ///
  /// In en, this message translates to:
  /// **'About Your Business details will be available in the upcoming update.'**
  String get aboutYourBusinessPlaceholderNote;

  /// Label for Business or Brand name field
  ///
  /// In en, this message translates to:
  /// **'Business / Brand Name'**
  String get businessBrandNameLabel;

  /// Helper text for Business or Brand name field
  ///
  /// In en, this message translates to:
  /// **'No brand name? You can use your own name.'**
  String get businessBrandNameHelper;

  /// Hint for Business or Brand name field
  ///
  /// In en, this message translates to:
  /// **'e.g. Ramesh Handlooms or Ramesh Kumar'**
  String get businessBrandNameHint;

  /// Label for Business category selection
  ///
  /// In en, this message translates to:
  /// **'Business Category *'**
  String get businessCategoryLabel;

  /// Hint prompting user to select a category
  ///
  /// In en, this message translates to:
  /// **'Select a category'**
  String get selectCategoryHint;

  /// Category option: Food & Homemade Products
  ///
  /// In en, this message translates to:
  /// **'Food & Homemade Products'**
  String get categoryFoodHomemade;

  /// Category option: Handicrafts
  ///
  /// In en, this message translates to:
  /// **'Handicrafts'**
  String get categoryHandicrafts;

  /// Category option: Clothing & Textiles
  ///
  /// In en, this message translates to:
  /// **'Clothing & Textiles'**
  String get categoryClothingTextiles;

  /// Category option: Jewellery & Accessories
  ///
  /// In en, this message translates to:
  /// **'Jewellery & Accessories'**
  String get categoryJewelleryAccessories;

  /// Category option: Home & Decor
  ///
  /// In en, this message translates to:
  /// **'Home & Decor'**
  String get categoryHomeDecor;

  /// Category option: Agriculture-based Products
  ///
  /// In en, this message translates to:
  /// **'Agriculture-based Products'**
  String get categoryAgricultureProducts;

  /// Category option: Beauty & Personal Care
  ///
  /// In en, this message translates to:
  /// **'Beauty & Personal Care'**
  String get categoryBeautyPersonalCare;

  /// Category option: Other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOtherCraft;

  /// Label for optional bio / products description field
  ///
  /// In en, this message translates to:
  /// **'What do you make? (Optional)'**
  String get whatDoYouMakeLabel;

  /// Helper text with examples for what do you make field
  ///
  /// In en, this message translates to:
  /// **'For example: homemade pickles, phulkari suits, wooden toys...'**
  String get whatDoYouMakeHelper;

  /// Hint for what do you make field
  ///
  /// In en, this message translates to:
  /// **'Describe what you make and sell'**
  String get whatDoYouMakeHint;

  /// Label for Area, Village, or City location field
  ///
  /// In en, this message translates to:
  /// **'Area / Village / City *'**
  String get areaVillageCityLabel;

  /// Hint for Area, Village, or City location field
  ///
  /// In en, this message translates to:
  /// **'e.g. Rampur Village or Sanganer'**
  String get areaVillageCityHint;

  /// Validation error when business name is empty or too short
  ///
  /// In en, this message translates to:
  /// **'Please enter your business or brand name (at least 2 characters).'**
  String get businessNameRequired;

  /// Validation error when category is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select your primary product category.'**
  String get categoryRequired;

  /// Validation error when state is not selected
  ///
  /// In en, this message translates to:
  /// **'Please select your state or union territory.'**
  String get stateRequired;

  /// Validation error when district is empty or too short
  ///
  /// In en, this message translates to:
  /// **'Please enter your district (at least 2 characters).'**
  String get districtRequired;

  /// Validation error when city is empty or too short
  ///
  /// In en, this message translates to:
  /// **'Please enter your area, village, or city (at least 2 characters).'**
  String get cityRequired;

  /// Validation error when pincode is not 6 valid digits
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 6-digit Indian PIN code.'**
  String get pincodeInvalid;

  /// Feedback message when Your Business details are saved
  ///
  /// In en, this message translates to:
  /// **'Business details saved successfully.'**
  String get yourBusinessSaved;

  /// Title for team or business size section
  ///
  /// In en, this message translates to:
  /// **'Team / Business Size'**
  String get teamSizeTitle;

  /// Solo artisan option
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get teamSizeSolo;

  /// 2 to 5 people option
  ///
  /// In en, this message translates to:
  /// **'2–5 people'**
  String get teamSize2_5;

  /// 6 to 10 people option
  ///
  /// In en, this message translates to:
  /// **'6–10 people'**
  String get teamSize6_10;

  /// 11 to 25 people option
  ///
  /// In en, this message translates to:
  /// **'11–25 people'**
  String get teamSize11_25;

  /// 25 or more people option
  ///
  /// In en, this message translates to:
  /// **'25+ people'**
  String get teamSize25Plus;

  /// Title for typical monthly sales range section
  ///
  /// In en, this message translates to:
  /// **'Typical Monthly Sales'**
  String get monthlySalesTitle;

  /// Monthly sales below 10k
  ///
  /// In en, this message translates to:
  /// **'Less than ₹10,000'**
  String get monthlySalesBelow10k;

  /// Monthly sales 10k to 50k
  ///
  /// In en, this message translates to:
  /// **'₹10,000–₹50,000'**
  String get monthlySales10k50k;

  /// Monthly sales 50k to 1 lakh
  ///
  /// In en, this message translates to:
  /// **'₹50,000–₹1 lakh'**
  String get monthlySales50k1l;

  /// Monthly sales 1 to 5 lakh
  ///
  /// In en, this message translates to:
  /// **'₹1–₹5 lakh'**
  String get monthlySales1l5l;

  /// Monthly sales above 5 lakh
  ///
  /// In en, this message translates to:
  /// **'Above ₹5 lakh'**
  String get monthlySalesAbove5l;

  /// Prefer not to disclose sales
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get monthlySalesPreferNotToSay;

  /// Title for production capacity section
  ///
  /// In en, this message translates to:
  /// **'How much can you usually produce?'**
  String get productionCapacityTitle;

  /// Label for quantity input
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get quantityLabel;

  /// Hint for production capacity quantity
  ///
  /// In en, this message translates to:
  /// **'e.g. 50'**
  String get quantityHint;

  /// Label for production capacity period dropdown
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get periodLabel;

  /// Capacity unit pieces
  ///
  /// In en, this message translates to:
  /// **'Pieces'**
  String get unitPieces;

  /// Capacity unit litres
  ///
  /// In en, this message translates to:
  /// **'Litres'**
  String get unitLitres;

  /// Capacity unit packs
  ///
  /// In en, this message translates to:
  /// **'Packs'**
  String get unitPacks;

  /// Capacity unit boxes
  ///
  /// In en, this message translates to:
  /// **'Boxes'**
  String get unitBoxes;

  /// Capacity unit other
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get unitOther;

  /// Capacity period per week
  ///
  /// In en, this message translates to:
  /// **'Per Week'**
  String get periodWeek;

  /// Capacity period per month
  ///
  /// In en, this message translates to:
  /// **'Per Month'**
  String get periodMonth;

  /// Capacity period per year
  ///
  /// In en, this message translates to:
  /// **'Per Year'**
  String get periodYear;

  /// Title for current selling channels section
  ///
  /// In en, this message translates to:
  /// **'Where do you currently sell?'**
  String get sellingChannelsTitle;

  /// Selling channel local customers
  ///
  /// In en, this message translates to:
  /// **'Local customers'**
  String get channelLocalCustomers;

  /// Selling channel local shops
  ///
  /// In en, this message translates to:
  /// **'Local shops'**
  String get channelLocalShops;

  /// Selling channel WhatsApp
  ///
  /// In en, this message translates to:
  /// **'WhatsApp'**
  String get channelWhatsapp;

  /// Selling channel social media
  ///
  /// In en, this message translates to:
  /// **'Instagram / Facebook'**
  String get channelSocialMedia;

  /// Selling channel online marketplaces
  ///
  /// In en, this message translates to:
  /// **'Online marketplaces'**
  String get channelOnlineMarketplaces;

  /// Selling channel exhibitions and fairs
  ///
  /// In en, this message translates to:
  /// **'Exhibitions / Fairs'**
  String get channelExhibitionsFairs;

  /// Selling channel not selling yet
  ///
  /// In en, this message translates to:
  /// **'Haven’t started selling yet'**
  String get channelNotSellingYet;

  /// Action to skip optional onboarding step
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Action to complete onboarding and enter home
  ///
  /// In en, this message translates to:
  /// **'Complete Setup'**
  String get completeSetup;

  /// Validation error when production capacity is partially filled
  ///
  /// In en, this message translates to:
  /// **'Please specify quantity, unit, and period for production capacity, or leave all three empty.'**
  String get capacityAllOrNoneRequired;

  /// Validation error when capacity quantity is not positive
  ///
  /// In en, this message translates to:
  /// **'Production capacity quantity must be a positive number.'**
  String get capacityPositiveRequired;

  /// Badge indicating an optional step or field
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalBadge;

  /// Title for Home verification banner
  ///
  /// In en, this message translates to:
  /// **'Reach more buyers across India'**
  String get reachMoreBuyers;

  /// Body for Home verification banner
  ///
  /// In en, this message translates to:
  /// **'Verify your business to build trust and unlock eligible wider-market features.'**
  String get verifyBusinessPrompt;

  /// Action button on Home verification banner
  ///
  /// In en, this message translates to:
  /// **'Verify My Business'**
  String get verifyMyBusiness;

  /// Title for Business Verification section and screen
  ///
  /// In en, this message translates to:
  /// **'Business Verification'**
  String get businessVerification;

  /// Subtitle for Business Verification entry point in Profile
  ///
  /// In en, this message translates to:
  /// **'Verify your business details and build buyer trust.'**
  String get businessVerificationSubtitle;

  /// Intro on Business Verification overview screen
  ///
  /// In en, this message translates to:
  /// **'Complete your business details to build trust and access eligible VyaparSetu features.'**
  String get businessVerificationIntro;

  /// Status text when all applicable verification steps are completed
  ///
  /// In en, this message translates to:
  /// **'Business details recorded'**
  String get businessVerificationComplete;

  /// Count of remaining verification steps
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 step remaining} other{{count} steps remaining}}'**
  String verificationStepsRemaining(int count);

  /// Fraction of completed steps
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total} completed'**
  String verificationStepsCompleted(int completed, int total);

  /// Label for Email verification card
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailVerificationLabel;

  /// Badge when email is verified
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get emailVerifiedBadge;

  /// Badge when email is not verified
  ///
  /// In en, this message translates to:
  /// **'Not verified'**
  String get emailNotVerifiedBadge;

  /// Label for Business Identity / PAN verification card
  ///
  /// In en, this message translates to:
  /// **'Business Identity'**
  String get businessIdentityLabel;

  /// Description for Business Identity card
  ///
  /// In en, this message translates to:
  /// **'Verify your PAN to confirm your business identity.'**
  String get businessIdentityDesc;

  /// Badge when PAN details have been added
  ///
  /// In en, this message translates to:
  /// **'Details Added'**
  String get panVerifiedBadge;

  /// Badge when PAN is not provided
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get panNotVerifiedBadge;

  /// Label for GST Registration card
  ///
  /// In en, this message translates to:
  /// **'GST Registration'**
  String get gstRegistrationLabel;

  /// Description for GST Registration card
  ///
  /// In en, this message translates to:
  /// **'Record your GST registration to access eligible wider-market features on VyaparSetu.'**
  String get gstRegistrationDesc;

  /// Badge when GST is optional and not provided
  ///
  /// In en, this message translates to:
  /// **'Optional • Not provided'**
  String get gstOptionalNotProvided;

  /// Informational note for non-GST producers
  ///
  /// In en, this message translates to:
  /// **'GST details are optional here. You can add them later if applicable to your business.'**
  String get gstOptionalDesc;

  /// Badge when GST format check is in progress
  ///
  /// In en, this message translates to:
  /// **'Checking format'**
  String get gstVerificationPending;

  /// Badge when GST details have been added
  ///
  /// In en, this message translates to:
  /// **'Details Added'**
  String get gstVerifiedBadge;

  /// Badge when GST is not provided
  ///
  /// In en, this message translates to:
  /// **'Not provided'**
  String get gstNotVerifiedBadge;

  /// Action button to add PAN
  ///
  /// In en, this message translates to:
  /// **'Add PAN'**
  String get verifyPanAction;

  /// Action button to add GSTIN
  ///
  /// In en, this message translates to:
  /// **'Add GSTIN'**
  String get addOrVerifyGstAction;

  /// Title for PAN verification info dialog
  ///
  /// In en, this message translates to:
  /// **'PAN Verification'**
  String get panVerificationComingSoonTitle;

  /// Description for PAN verification info dialog
  ///
  /// In en, this message translates to:
  /// **'PAN verification flow is being updated for progressive onboarding. Your recorded status will appear here once submitted.'**
  String get panVerificationComingSoonDesc;

  /// Title for GST verification info dialog
  ///
  /// In en, this message translates to:
  /// **'GST Registration'**
  String get gstVerificationComingSoonTitle;

  /// Description for GST verification info dialog
  ///
  /// In en, this message translates to:
  /// **'GST details are optional here. You can add them later if applicable to your business.'**
  String get gstVerificationComingSoonDesc;

  /// Title for PAN bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Business Identity (PAN)'**
  String get panVerificationSheetTitle;

  /// Description for PAN bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Enter your 10-character PAN to record your business identity on VyaparSetu.'**
  String get panVerificationSheetDesc;

  /// Label for PAN input field
  ///
  /// In en, this message translates to:
  /// **'PAN Number'**
  String get panInputLabel;

  /// Hint for PAN input field
  ///
  /// In en, this message translates to:
  /// **'e.g. ABCDE1234F'**
  String get panInputHint;

  /// Error message when PAN format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 10-character PAN (e.g. ABCDE1234F).'**
  String get panInvalidFormatError;

  /// Success message after PAN details are recorded
  ///
  /// In en, this message translates to:
  /// **'PAN details recorded successfully.'**
  String get panVerificationSuccess;

  /// Error message when account already has a recorded PAN
  ///
  /// In en, this message translates to:
  /// **'A PAN is already associated with this account.'**
  String get panAlreadyLinkedError;

  /// Error message when PAN recording fails
  ///
  /// In en, this message translates to:
  /// **'PAN details could not be recorded. Please check your details.'**
  String get panVerificationFailedError;

  /// Title for GST bottom sheet
  ///
  /// In en, this message translates to:
  /// **'GST Registration (GSTIN)'**
  String get gstVerificationSheetTitle;

  /// Description for GST bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Enter your 15-character GSTIN to record your GST details on VyaparSetu.'**
  String get gstVerificationSheetDesc;

  /// Label for GSTIN input field
  ///
  /// In en, this message translates to:
  /// **'GSTIN'**
  String get gstInputLabel;

  /// Hint for GSTIN input field
  ///
  /// In en, this message translates to:
  /// **'e.g. 07AAAAA0000A1Z5'**
  String get gstInputHint;

  /// Error message when GSTIN format is invalid
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid 15-character GSTIN (e.g. 07AAAAA0000A1Z5).'**
  String get gstInvalidFormatError;

  /// Error message when GSTIN state code is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid state code in GSTIN. First 2 digits must be between 01-38, 97, or 99.'**
  String get gstInvalidStateCodeError;

  /// Success message after GSTIN details are recorded
  ///
  /// In en, this message translates to:
  /// **'GSTIN details recorded successfully.'**
  String get gstVerificationSuccess;

  /// Error message when account already has a recorded GSTIN
  ///
  /// In en, this message translates to:
  /// **'A GSTIN is already associated with this account.'**
  String get gstAlreadyLinkedError;

  /// Error message when GSTIN recording fails
  ///
  /// In en, this message translates to:
  /// **'GSTIN details could not be recorded. Please check your 15-digit GSTIN.'**
  String get gstVerificationFailedError;

  /// Button label while request is in progress
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get verifyingAction;

  /// Button label to submit format check
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get verifyAction;

  /// Button label to request price guidance
  ///
  /// In en, this message translates to:
  /// **'Set a Good Price'**
  String get setGoodPriceButton;

  /// Guidance when category or description is missing before requesting price
  ///
  /// In en, this message translates to:
  /// **'Add a product category and description first so we can suggest a price.'**
  String get setGoodPriceMissingInfo;

  /// Message when no pricing profile is available for the product
  ///
  /// In en, this message translates to:
  /// **'Personalized price guidance is not available for this product yet.'**
  String get setGoodPriceNotAvailable;

  /// Loading message while fetching price guidance
  ///
  /// In en, this message translates to:
  /// **'Getting price guidance...'**
  String get setGoodPriceLoading;

  /// Title of bottom sheet showing price guidance
  ///
  /// In en, this message translates to:
  /// **'Price Guidance'**
  String get priceGuidanceTitle;

  /// Label for break-even floor cost
  ///
  /// In en, this message translates to:
  /// **'Cost to make'**
  String get priceCostToMake;

  /// Label for market ceiling price
  ///
  /// In en, this message translates to:
  /// **'Similar market price'**
  String get priceSimilarMarket;

  /// Label for recommended price
  ///
  /// In en, this message translates to:
  /// **'Suggested price'**
  String get priceSuggested;

  /// Disclosure text regarding pricing prototype data
  ///
  /// In en, this message translates to:
  /// **'Prototype guidance based on sample market data. Final price is your choice.'**
  String get priceGuidanceDisclosure;

  /// Button to apply the suggested price to the form
  ///
  /// In en, this message translates to:
  /// **'Use This Price'**
  String get useThisPriceButton;

  /// Message when pricing API is offline or times out
  ///
  /// In en, this message translates to:
  /// **'Price guidance is temporarily unavailable. You can enter your price manually.'**
  String get priceGuidanceUnavailable;

  /// Title for orders and sales section on producer home
  ///
  /// In en, this message translates to:
  /// **'Orders & Sales'**
  String get ordersAndSalesTitle;

  /// Subtitle explaining completed sales
  ///
  /// In en, this message translates to:
  /// **'Your completed marketplace sales'**
  String get ordersSummarySubtitle;

  /// Label for completed sales amount
  ///
  /// In en, this message translates to:
  /// **'Completed Sales'**
  String get completedSalesLabel;

  /// Label for completed orders count
  ///
  /// In en, this message translates to:
  /// **'Completed Orders'**
  String get completedOrdersLabel;

  /// Label for pending or confirmed orders count
  ///
  /// In en, this message translates to:
  /// **'Pending / Confirmed'**
  String get pendingOrdersLabel;

  /// Label for total orders count
  ///
  /// In en, this message translates to:
  /// **'Total Orders'**
  String get totalOrdersLabel;

  /// Title for products section on producer home
  ///
  /// In en, this message translates to:
  /// **'Your Products'**
  String get yourProductsTitle;

  /// Badge showing active product count
  ///
  /// In en, this message translates to:
  /// **'{count} Active'**
  String activeProductsBadge(int count);

  /// Action link to view all items
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllAction;

  /// Title for active buyer requests section on producer home
  ///
  /// In en, this message translates to:
  /// **'Active Buyer Needs'**
  String get activeBuyerNeedsTitle;

  /// Button to open buyer needs tab
  ///
  /// In en, this message translates to:
  /// **'View Buyer Needs'**
  String get viewBuyerNeedsAction;

  /// Empty state message when there are zero active buyer requests
  ///
  /// In en, this message translates to:
  /// **'No active buyer needs right now. Check again later.'**
  String get noActiveBuyerNeeds;

  /// Title for market demand signals preview on producer home
  ///
  /// In en, this message translates to:
  /// **'Market Demand'**
  String get marketDemandTitle;

  /// Action button to open full market intelligence
  ///
  /// In en, this message translates to:
  /// **'View Market Radar'**
  String get viewMarketRadarAction;

  /// Display label for buyer target price
  ///
  /// In en, this message translates to:
  /// **'Target: {price}'**
  String targetPriceLabel(String price);

  /// Display label for buyer requested quantity and unit
  ///
  /// In en, this message translates to:
  /// **'Qty: {quantity} {unit}'**
  String quantityWithUnit(String quantity, String unit);

  /// Urgency badge high
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get highUrgency;

  /// Urgency badge medium
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get mediumUrgency;

  /// Urgency badge low
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get lowUrgency;

  /// Demand level high interest
  ///
  /// In en, this message translates to:
  /// **'High interest'**
  String get highInterestDemand;

  /// Demand level growing demand
  ///
  /// In en, this message translates to:
  /// **'Growing demand'**
  String get growingDemand;

  /// Demand level steady demand
  ///
  /// In en, this message translates to:
  /// **'Steady demand'**
  String get steadyDemand;

  /// Loading state message for home dashboard
  ///
  /// In en, this message translates to:
  /// **'Loading marketplace updates...'**
  String get loadingDashboard;

  /// Error fallback message for home dashboard
  ///
  /// In en, this message translates to:
  /// **'Marketplace updates unavailable'**
  String get dashboardUnavailable;

  /// Section title for optional cost breakdown inputs in pricing sheet
  ///
  /// In en, this message translates to:
  /// **'Your making cost (optional)'**
  String get pricingCostInputsTitle;

  /// Label for raw material cost input
  ///
  /// In en, this message translates to:
  /// **'Raw material cost (₹)'**
  String get pricingRawMaterialCost;

  /// Label for packaging cost input
  ///
  /// In en, this message translates to:
  /// **'Packaging cost (₹)'**
  String get pricingPackagingCost;

  /// Label for labour cost input
  ///
  /// In en, this message translates to:
  /// **'Labour cost (₹)'**
  String get pricingLabourCost;

  /// Label for other miscellaneous cost input
  ///
  /// In en, this message translates to:
  /// **'Other cost (₹)'**
  String get pricingOtherCost;

  /// Label for quantity produced in this batch
  ///
  /// In en, this message translates to:
  /// **'Quantity made'**
  String get pricingProductionQuantity;

  /// Label for desired profit margin percentage input
  ///
  /// In en, this message translates to:
  /// **'Desired profit %'**
  String get pricingDesiredMargin;

  /// Primary action button to request V2 pricing
  ///
  /// In en, this message translates to:
  /// **'Get Price Suggestion'**
  String get pricingGetSuggestion;

  /// Label for the market comparable price range
  ///
  /// In en, this message translates to:
  /// **'Similar items sell for'**
  String get pricingSimilarItemsRange;

  /// Label for cost floor (minimum price covering costs + margin)
  ///
  /// In en, this message translates to:
  /// **'Minimum sustainable price'**
  String get pricingMinSustainable;

  /// Label for suggested wholesale/bulk price
  ///
  /// In en, this message translates to:
  /// **'Bulk price'**
  String get pricingBulkPrice;

  /// Section label for the AI reason text
  ///
  /// In en, this message translates to:
  /// **'Why this price?'**
  String get pricingWhyThisPrice;

  /// Confidence label when confidence=high
  ///
  /// In en, this message translates to:
  /// **'Strong estimate'**
  String get pricingConfidenceStrong;

  /// Confidence label when confidence=medium
  ///
  /// In en, this message translates to:
  /// **'Good estimate'**
  String get pricingConfidenceGood;

  /// Confidence label when confidence=low
  ///
  /// In en, this message translates to:
  /// **'Basic estimate'**
  String get pricingConfidenceBasic;

  /// Validation error for negative cost inputs
  ///
  /// In en, this message translates to:
  /// **'Cost values cannot be negative'**
  String get pricingNegativeCostError;

  /// Validation error for zero or negative quantity
  ///
  /// In en, this message translates to:
  /// **'Quantity must be greater than zero'**
  String get pricingInvalidQuantityError;

  /// Subtitle for What Buyers Want screen with live data
  ///
  /// In en, this message translates to:
  /// **'See real-time demand and buyer requests across regions.'**
  String get whatBuyersWantLiveSubtitle;

  /// Message shown when there is zero active buyer demand
  ///
  /// In en, this message translates to:
  /// **'No active buyer demand found right now. Check again later.'**
  String get noActiveBuyerDemand;

  /// Error message when loading market demand fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load market demand right now.'**
  String get marketDemandLoadError;

  /// Label for active buyer requests count
  ///
  /// In en, this message translates to:
  /// **'Active buyer needs'**
  String get activeBuyerNeedsLabel;

  /// Count of buyer requests
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request} other{{count} requests}}'**
  String requestsCount(int count);

  /// Label for aggregate quantity requested
  ///
  /// In en, this message translates to:
  /// **'Quantity wanted'**
  String get quantityWantedLabel;

  /// Label for buyer target price range
  ///
  /// In en, this message translates to:
  /// **'Buyer price range'**
  String get buyerPriceRangeLabel;

  /// Label for geographic demand location
  ///
  /// In en, this message translates to:
  /// **'Where buyers are'**
  String get whereBuyersAreLabel;

  /// Count of high urgency buyer requests
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 urgent} other{{count} urgent}}'**
  String urgentNeedsCount(int count);

  /// Notice when requested items have different units
  ///
  /// In en, this message translates to:
  /// **'Multiple unit types'**
  String get multipleUnitTypes;

  /// Subtitle for Buyer Needs tab
  ///
  /// In en, this message translates to:
  /// **'Active requirements from buyers waiting for producers'**
  String get buyerNeedsSubtitle;

  /// Hint text for buyer needs search input
  ///
  /// In en, this message translates to:
  /// **'Search by product, category, location...'**
  String get searchBuyerNeedsHint;

  /// Filter tab for buyer needs matching producer category
  ///
  /// In en, this message translates to:
  /// **'For You'**
  String get filterForYou;

  /// Filter tab for buyer needs from same district or state
  ///
  /// In en, this message translates to:
  /// **'Nearby'**
  String get filterNearby;

  /// Filter tab for high urgency buyer requests
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get filterUrgent;

  /// Empty state message when no buyer needs match query
  ///
  /// In en, this message translates to:
  /// **'No buyer needs match your search.'**
  String get noBuyerNeedsMatchSearch;

  /// Empty state message when no buyer needs match selected filter
  ///
  /// In en, this message translates to:
  /// **'No opportunities found for this filter.'**
  String get noBuyerNeedsMatchFilter;

  /// Error message when loading buyer needs fails
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load buyer needs right now.'**
  String get buyerNeedsLoadError;

  /// Label for buyer requested quantity
  ///
  /// In en, this message translates to:
  /// **'Buyer wants'**
  String get buyerWantsLabel;

  /// Label for buyer target price
  ///
  /// In en, this message translates to:
  /// **'Target price'**
  String get buyerTargetPriceLabel;

  /// Badge for high urgency buyer needs
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get urgentBadge;
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
      <String>['en', 'hi', 'pa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'pa':
      return AppLocalizationsPa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
