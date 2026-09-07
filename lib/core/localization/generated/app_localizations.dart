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

  /// Filter tab for inactive products
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get filterInactive;

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

  /// Label for measurement unit selector
  ///
  /// In en, this message translates to:
  /// **'Unit'**
  String get unitLabel;

  /// Unit option: Piece
  ///
  /// In en, this message translates to:
  /// **'Piece'**
  String get unitPiece;

  /// Unit option: Kilogram
  ///
  /// In en, this message translates to:
  /// **'Kilogram (kg)'**
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
