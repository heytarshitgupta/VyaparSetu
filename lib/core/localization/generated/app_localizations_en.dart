// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'VyaparSetu';

  @override
  String get appSubtitle =>
      'Connecting artisan producers directly with commercial buyers across India';

  @override
  String get chooseHowToContinue => 'Choose how you want to continue:';

  @override
  String get roleBuyerTitle => 'I Want to Buy Products';

  @override
  String get roleBuyerDescription =>
      'Discover products and connect with producers';

  @override
  String get roleProducerTitle => 'I Make & Sell Products';

  @override
  String get roleProducerDescription =>
      'Create your profile and reach more buyers';

  @override
  String get roleSelectionFooter =>
      'You can switch or register anytime with your phone or email.';

  @override
  String get home => 'Home';

  @override
  String get myProducts => 'My Products';

  @override
  String get addProduct => 'Add Product';

  @override
  String get buyerNeeds => 'Buyer Needs';

  @override
  String get whatBuyersWant => 'What Buyers Want';

  @override
  String get myProfile => 'My Profile';

  @override
  String get settings => 'Settings';

  @override
  String get welcome => 'Welcome';

  @override
  String get continueButton => 'Continue';

  @override
  String get back => 'Back';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get verify => 'Verify';

  @override
  String get verified => 'Verified';

  @override
  String get notVerified => 'Not Verified';

  @override
  String get signInTitle => 'Sign In';

  @override
  String get signInSubtitle =>
      'Sign in to manage your products, view buyer needs, and track orders.';

  @override
  String get createAccountTitle => 'Create Account';

  @override
  String get createAccountSubtitle =>
      'Start your journey as an artisan producer and reach direct commercial buyers.';

  @override
  String get fullName => 'Full Name';

  @override
  String get fullNameHint => 'e.g. Ramesh Kumar';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get emailHint => 'producer@example.com';

  @override
  String get password => 'Password';

  @override
  String get passwordHint => 'Enter your password';

  @override
  String get createPasswordHint => 'Create a password (min 6 characters)';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get confirmPasswordHint => 'Re-enter your password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signInWithPhone => 'Sign in with Phone OTP';

  @override
  String get signUpWithPhone => 'Sign up with Phone OTP';

  @override
  String get newHere => 'New here? ';

  @override
  String get alreadyHaveAccount => 'Already have an account? ';

  @override
  String get enterFullName => 'Please enter your full name';

  @override
  String get nameTooShort => 'Name must be at least 2 characters';

  @override
  String get enterEmail => 'Please enter your email address';

  @override
  String get enterValidEmail => 'Please enter a valid email address';

  @override
  String get enterPassword => 'Please enter your password';

  @override
  String get createPassword => 'Please create a password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get confirmYourPassword => 'Please confirm your password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get phoneFeatureUpcoming =>
      'Phone login will be available in the next update.';

  @override
  String get forgotPasswordUpcoming =>
      'Password recovery will be available in a future update.';

  @override
  String get language => 'Language';

  @override
  String get appearance => 'Appearance';

  @override
  String get chooseAppearance => 'Choose appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'Use phone setting';

  @override
  String get producerSetup => 'Producer Setup';

  @override
  String get exit => 'Exit';

  @override
  String stepOf(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% Completed';
  }

  @override
  String get submitApplication => 'Submit Application';

  @override
  String get onboardingReviewSubmitted =>
      'Onboarding review submitted. Full submission will be finalized in upcoming steps.';

  @override
  String get step1Title => 'About You';

  @override
  String get step1Subtitle => 'Your name and contact info';

  @override
  String get step2Title => 'Your Work';

  @override
  String get step2Subtitle => 'What you make and sell';

  @override
  String get step3Title => 'Your Address';

  @override
  String get step3Subtitle => 'Where your workshop is based';

  @override
  String get step4Title => 'Verification';

  @override
  String get step4Subtitle => 'Identity and business details';

  @override
  String get step5Title => 'Check & Submit';

  @override
  String get step5Subtitle => 'Confirm and start selling';

  @override
  String get step1Header => 'Artisan Basic Details';

  @override
  String get step1Description =>
      'Confirm your primary name and contact information for buyer communications.';

  @override
  String get fullNameLabel => 'Full Name *';

  @override
  String get enterFullNameHint => 'Enter your full name';

  @override
  String get fullNameHelper => 'Your name as you want it shown on VyaparSetu';

  @override
  String get emailAddressLogin => 'Email Address (Login)';

  @override
  String get notProvided => 'Not provided';

  @override
  String get readOnly => 'Read Only';

  @override
  String get emailHelper => 'Your login email is managed through your account';

  @override
  String get verifiedLoginPhone => 'Verified Login Phone';

  @override
  String get contactPhoneNumber => 'Contact Phone Number';

  @override
  String get verifiedAuth => 'Verified Auth';

  @override
  String get verifiedPhoneHelper =>
      'This phone number is verified and tied to your login credentials';

  @override
  String get enter10DigitPhoneHint => 'Enter 10-digit mobile number';

  @override
  String get contactPhoneHelper =>
      'Used to contact you about your business (Contact phone only)';

  @override
  String get step2Header => 'Business & Craft Details';

  @override
  String get step2Description =>
      'Tell buyers about your enterprise, workshop, or home-based artisanal work.';

  @override
  String get businessNameLabel => 'Business / Workshop Name *';

  @override
  String get businessNameHint => 'e.g. Sharma Pickles, Punjab Phulkari Works';

  @override
  String get businessNameHelper =>
      'Name of your business, workshop, or home-based work';

  @override
  String get craftCategoryLabel => 'Craft / Product Category *';

  @override
  String get craftCategoryHelper =>
      'Select your main product category so commercial buyers can find you easily';

  @override
  String get specifyCategory => 'Specify Your Category *';

  @override
  String get specifyCategoryHint =>
      'e.g. Bamboo Crafts, Clay Pottery, Stone Carving';

  @override
  String get specifyCategoryHelper =>
      'Enter your custom artisanal or product category';

  @override
  String get shortDescriptionLabel => 'Short Description (Optional)';

  @override
  String get shortDescriptionHint =>
      'Tell buyers what you make in a few words (e.g. handwoven cotton stoles using organic natural dyes)';

  @override
  String get shortDescriptionHelper =>
      'Tell buyers what you make in a few words';

  @override
  String get catFood => 'Food & Homemade Products';

  @override
  String get catHandicrafts => 'Handicrafts';

  @override
  String get catHandloom => 'Handloom & Textiles';

  @override
  String get catClothing => 'Clothing & Embroidery';

  @override
  String get catJewellery => 'Jewellery & Accessories';

  @override
  String get catWoodwork => 'Woodwork';

  @override
  String get catMetalCraft => 'Metal Craft';

  @override
  String get catHomeDecor => 'Home Decor';

  @override
  String get catBeauty => 'Beauty / Personal Care';

  @override
  String get catOther => 'Other';

  @override
  String get step3Header => 'Workshop Location';

  @override
  String get step3Description =>
      'Provide your workshop or home production address so commercial buyers can calculate logistics and pickup.';

  @override
  String get stateLabel => 'State / Union Territory *';

  @override
  String get selectStateHint => 'Select your state or union territory';

  @override
  String get districtLabel => 'District *';

  @override
  String get districtHint => 'e.g. Jaipur, Ludhiana';

  @override
  String get districtHelper => 'District where you make your products';

  @override
  String get cityVillageLabel => 'City / Village *';

  @override
  String get cityVillageHint => 'e.g. Sanganer, Khanna';

  @override
  String get cityVillageHelper => 'Your city, town, or village';

  @override
  String get pincodeLabel => 'Pincode *';

  @override
  String get pincodeHint => 'e.g. 302029';

  @override
  String get pincodeHelper => '6-digit postal PIN code (cannot start with 0)';

  @override
  String get addressLabel => 'Workshop / Business Address *';

  @override
  String get addressHint => 'Street, landmark, lane, or house/unit details...';

  @override
  String get addressHelper => 'Where you make or manage your products';

  @override
  String get step4Header => 'Identity & Compliance';

  @override
  String get step4Description =>
      'Verify your details to build trust with buyers.';

  @override
  String get demoDisclosure =>
      'Demo verification environment • Verification is simulated in this prototype.';

  @override
  String get panVerification => 'PAN Verification';

  @override
  String get panVerified => 'PAN Verified';

  @override
  String get secureIdentityVerification => 'Secure identity verification';

  @override
  String get verifiedInDemoEnvironment =>
      'Verified in demo verification environment';

  @override
  String get verifiedPan => 'Verified PAN';

  @override
  String get editDetails => 'Edit Details';

  @override
  String get panSecurityNote =>
      'Your PAN details are securely verified. Plaintext PAN is never stored.';

  @override
  String get panNumberLabel => 'PAN Number *';

  @override
  String get panNumberHint => 'ABCDE1234F';

  @override
  String get panNumberHelper => '10-character alphanumeric PAN';

  @override
  String get nameAsPerPanLabel => 'Name as per PAN *';

  @override
  String get nameAsPerPanHint => 'Enter name as shown on PAN card';

  @override
  String get nameAsPerPanHelper => 'Must match official PAN records';

  @override
  String get dobLabel => 'Date of Birth *';

  @override
  String get selectDobHint => 'Select Date of Birth (DD/MM/YYYY)';

  @override
  String get panPrivacyShield =>
      'Your PAN number is used only for verification and is not stored in plain text.';

  @override
  String get verifyPan => 'Verify PAN';

  @override
  String get checkingDetails => 'Checking Details...';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get aadhaarVerification => 'Aadhaar Verification';

  @override
  String get aadhaarSubtitle => 'Identity verification via authorized service';

  @override
  String get aadhaarDescription =>
      'Verify your identity using Aadhaar. Fast, secure, and helps build trust with commercial buyers.';

  @override
  String get verifyAadhaar => 'Verify Aadhaar';

  @override
  String get aadhaarDialogContent =>
      'Aadhaar verification will be available through an authorized verification service. It is not enabled in this prototype.';

  @override
  String get gotIt => 'Got It';

  @override
  String get gstRegistration => 'GST Registration';

  @override
  String get gstDeclared => 'Declared GST registration';

  @override
  String get gstStatusSubtitle => 'Business tax registration status';

  @override
  String get areYouGstRegistered => 'Are you registered for GST? *';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get gstNotRegisteredNotice =>
      'GST not registered. Micro-producers below registration thresholds can continue without GST.';

  @override
  String get gstinNumberLabel => 'GSTIN Number *';

  @override
  String get gstinHint => '07AAAAA0000A1Z5';

  @override
  String get gstinHelper => '15-character alphanumeric GSTIN';

  @override
  String get verifyGstin => 'Verify GSTIN';

  @override
  String get gstUpcomingNotice =>
      'GST verification integration will be added next.';

  @override
  String get badgeNotVerified => 'Not Verified';

  @override
  String get badgeChecking => 'Checking...';

  @override
  String get badgeVerified => 'Verified';

  @override
  String get badgeCouldNotVerify => 'Could Not Verify';

  @override
  String get badgeComingSoon => 'Coming Soon';

  @override
  String get badgeNotRegistered => 'Not Registered';

  @override
  String get step5CardTitle => 'Review & Submit Onboarding';

  @override
  String get step5CardDescription =>
      'Review your profile setup before submitting. You can edit your craft catalog anytime from your dashboard.';

  @override
  String get profileStatus => 'Profile Status';

  @override
  String get readyForSubmission => 'Ready for Submission';

  @override
  String get nextStage => 'Next Stage';

  @override
  String get nextStageDescription => 'Direct access to Buyer Needs & Products';

  @override
  String welcomeProducer(String name) {
    return 'Welcome, $name';
  }

  @override
  String get producerDefaultName => 'Producer';

  @override
  String get producerHomeSubtitle =>
      'Manage your craft and connect with buyers';

  @override
  String get addProductActionSubtitle => 'Show buyers what you make';

  @override
  String get myProductsShortcutSubtitle => 'See the products you have added';

  @override
  String get buyerNeedsShortcutSubtitle => 'See what buyers are looking for';

  @override
  String get whatBuyersWantShortcutSubtitle => 'See what products people want';

  @override
  String get noProductsListedTitle => 'No products added yet';

  @override
  String get noProductsListedSubtitle =>
      'Add your first product so buyers can discover your craft';

  @override
  String get buyerNeedsWaitingTitle => 'Buyer needs will appear here';

  @override
  String get buyerNeedsWaitingSubtitle =>
      'Buyer requests will be listed here when available';

  @override
  String get featureComingSoon =>
      'This feature will be available in the next update';

  @override
  String get signOutAction => 'Sign Out';
}
