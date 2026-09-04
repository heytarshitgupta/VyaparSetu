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

  /// Placeholder when data is not provided
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

  /// Title for PAN card in verified state
  ///
  /// In en, this message translates to:
  /// **'PAN Verified'**
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
