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
  String get panVerified => 'Verified';

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

  @override
  String get myProductsSubtitle => 'Manage the products you make and sell';

  @override
  String get filterAll => 'All';

  @override
  String get filterActive => 'Active';

  @override
  String get filterDraft => 'Draft';

  @override
  String get filterHidden => 'Inactive';

  @override
  String get statusActive => 'Active';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusHidden => 'Inactive';

  @override
  String get priceNotSet => 'Price not set';

  @override
  String get draftNeedsCompletion => 'Needs price or details';

  @override
  String get noActiveProductsTitle => 'No active products';

  @override
  String get noActiveProductsSubtitle =>
      'Products ready for listing will appear here';

  @override
  String get noDraftProductsTitle => 'No draft products';

  @override
  String get noDraftProductsSubtitle =>
      'Products that still need details will appear here';

  @override
  String get noHiddenProductsTitle => 'No inactive products';

  @override
  String get noHiddenProductsSubtitle =>
      'Products you temporarily hide will appear here';

  @override
  String get showAllProducts => 'Show All Products';

  @override
  String get unableToLoadProducts => 'We couldn\'t load your products';

  @override
  String get unableToLoadSubtitle =>
      'Please check your connection and try again';

  @override
  String get notAuthenticatedMessage => 'Please sign in to view your products';

  @override
  String get retry => 'Retry';

  @override
  String get hideAction => 'Hide';

  @override
  String get showAction => 'Show';

  @override
  String get deleteAction => 'Delete';

  @override
  String get deleteProductTitle => 'Delete Product?';

  @override
  String get deleteProductConfirmation =>
      'Are you sure you want to delete this product? This action cannot be undone.';

  @override
  String get productHiddenSuccess => 'Product hidden';

  @override
  String get productActivatedSuccess => 'Product marked active';

  @override
  String get productDeletedSuccess => 'Product deleted';

  @override
  String get productActionFailed =>
      'Unable to update product. Please try again.';

  @override
  String get productDeleteFailed =>
      'Unable to delete product. Please try again.';

  @override
  String stepCount(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get addProductStep1Title => 'What do you make?';

  @override
  String get addProductStep2Title => 'Price & Details';

  @override
  String get addProductStep3Title => 'Add Photos & Save';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get productNameHint => 'e.g. Homemade Mango Pickle';

  @override
  String get productNameRequired => 'Please enter a product name first';

  @override
  String get categoryLabel => 'Category';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryHandicraft => 'Handicraft';

  @override
  String get categoryClothing => 'Clothing';

  @override
  String get categoryHome => 'Home Products';

  @override
  String get categoryBeauty => 'Beauty & Care';

  @override
  String get categoryJewellery => 'Jewellery';

  @override
  String get categoryOther => 'Other';

  @override
  String get customCategoryLabel => 'Describe category';

  @override
  String get unitLabel => 'Unit';

  @override
  String get unitPiece => 'Piece';

  @override
  String get unitKg => 'Kg';

  @override
  String get unitGram => 'Gram (g)';

  @override
  String get unitLitre => 'Litre (L)';

  @override
  String get unitMl => 'Millilitre (ml)';

  @override
  String get unitPack => 'Pack';

  @override
  String get unitDozen => 'Dozen';

  @override
  String get priceLabel => 'Price';

  @override
  String get priceHelper => 'Enter the price for one unit';

  @override
  String get priceInvalidError =>
      'Please enter a valid price (e.g. 250 or 250.50)';

  @override
  String get descriptionLabel => 'Tell buyers about your product';

  @override
  String get descriptionHelper =>
      'What is it made from? What makes it special?';

  @override
  String get addPhotosHeading => 'Add Photos';

  @override
  String get addPhotosSubtitle =>
      'Photos help buyers see the quality of your craft';

  @override
  String get photoUploadComingNext => 'Photo selection will be added next';

  @override
  String get saveDraftAction => 'Save Draft';

  @override
  String get markReadyAction => 'Mark Ready';

  @override
  String get markReadyGuidance => 'Add name, category, and price to mark ready';

  @override
  String get draftSavedMessage => 'Draft saved';

  @override
  String get productMarkedReadyMessage => 'Product marked ready';

  @override
  String get saveDraftFailed => 'Could not save draft. Please try again.';

  @override
  String get markReadyFailed => 'Could not mark ready. Please try again.';

  @override
  String get myOrders => 'My Orders';

  @override
  String get wishlist => 'Wishlist';

  @override
  String get myRequirements => 'My Requirements';

  @override
  String get businessInformation => 'Business Information';

  @override
  String get businessName => 'Business Name';

  @override
  String get category => 'Category';

  @override
  String get email => 'Email';

  @override
  String get phone => 'Phone';

  @override
  String get address => 'Address';

  @override
  String get recentActivity => 'Recent Activity';

  @override
  String get quickLinks => 'Quick Links';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get notifications => 'Notifications';

  @override
  String get logout => 'Logout';

  @override
  String get navDiscover => 'Discover';

  @override
  String get navSearch => 'Search';

  @override
  String get navOrders => 'Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get searchHint => 'Search for Products, Brands and More';

  @override
  String get allCategories => 'All Categories';

  @override
  String get handlooms => 'Handlooms';

  @override
  String get spices => 'Spices';

  @override
  String get handicrafts => 'Handicrafts';

  @override
  String get food => 'Food';

  @override
  String get gifting => 'Gifting';

  @override
  String get forYou => 'For You';

  @override
  String get textiles => 'Textiles';

  @override
  String get recommendedForYou => 'Recommended For You';

  @override
  String get viewAll => 'VIEW ALL';

  @override
  String get noProductsFound => 'No products found.';

  @override
  String get orderNow => 'Order Now';

  @override
  String get addedToWishlist => 'Added to wishlist';

  @override
  String get removedFromWishlist => 'Removed from wishlist';

  @override
  String get filters => 'Filters';

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get close => 'Close';

  @override
  String get searchProducts => 'Search products...';

  @override
  String get myCart => 'My Cart';

  @override
  String get noProducts => 'No Products';

  @override
  String get noProductsCategory =>
      'No products available in this category yet.';

  @override
  String get noRequests => 'No requests yet';

  @override
  String get noRequestsSub =>
      'Post a custom requirement to start receiving quotes from verified producers.';

  @override
  String get responsesText => 'Responses';

  @override
  String get receivingQuotes => 'Receiving Quotes';

  @override
  String get closed => 'Closed';

  @override
  String get createYourAccountTitle => 'Create Your Account';

  @override
  String get createAccountSupportingCopy =>
      'Start setting up your business on VyaparSetu.';

  @override
  String get verifyYourEmailTitle => 'Verify Your Email';

  @override
  String verifyYourEmailSubtitle(String email) {
    return 'We sent a 6-digit code to $email';
  }

  @override
  String get enterOtpPrompt => 'Enter 6-digit verification code';

  @override
  String get verifyAndContinue => 'Verify & Continue';

  @override
  String get resendCode => 'Resend Code';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend Code in ${seconds}s';
  }

  @override
  String get changeEmail => 'Change Email';

  @override
  String get otpInvalidLength => 'Please enter a valid 6-digit code';

  @override
  String get otpIncorrectOrExpired => 'That code is incorrect or has expired.';

  @override
  String get otpSentSuccess =>
      'A new 6-digit code has been sent to your email.';

  @override
  String get filterInactive => 'Inactive';

  @override
  String get statusInactive => 'Inactive';

  @override
  String get editAction => 'Edit';

  @override
  String get continueEditingAction => 'Continue Editing';

  @override
  String get saveChangesAction => 'Save Changes';

  @override
  String get makeActiveAction => 'Make Active';

  @override
  String get makeInactiveAction => 'Make Inactive';

  @override
  String get editProductTitle => 'Edit Product';

  @override
  String get editProductHelper => 'Update your product details and photos';

  @override
  String get deleteProductConfirmTitle => 'Delete product?';

  @override
  String get deleteProductConfirmBody =>
      'This will permanently remove this product and its photos.';

  @override
  String get productUpdatedSuccess => 'Product updated';

  @override
  String get productMadeActiveSuccess => 'Product made active';

  @override
  String get productMadeInactiveSuccess => 'Product made inactive';

  @override
  String get couldNotUpdateProduct => 'Could not update product';

  @override
  String get couldNotLoadProductPhoto => 'Could not load product photo';

  @override
  String get incompleteProductCannotActivate =>
      'Please edit product to fill name, category, and price before making it active.';

  @override
  String get noInactiveProductsTitle => 'No inactive products';

  @override
  String get noInactiveProductsSubtitle =>
      'Products you mark as inactive will appear here';

  @override
  String get whatBuyersWantSubtitle =>
      'See sample market demand trends from different places.';

  @override
  String get sampleMarketInsightsBadge => 'Sample market insights';

  @override
  String get sampleMarketInsightsNote =>
      'These regional trends are based on sample market activity to help you understand buyer interest.';

  @override
  String get demandHigh => 'High demand';

  @override
  String get demandMedium => 'Medium demand';

  @override
  String get demandLow => 'Low demand';

  @override
  String demandScoreOutOf(String score) {
    return '$score/100';
  }

  @override
  String signalDistrictLabel(String district) {
    return 'District: $district';
  }

  @override
  String topBuyingCityLabel(String city) {
    return 'Top buying city: $city';
  }

  @override
  String get estimatedMonthlyDemandLabel => 'Estimated monthly demand';

  @override
  String estimatedUnitsValue(String count) {
    return '$count units';
  }

  @override
  String get typicalOrderValueLabel => 'Typical order value';

  @override
  String get categoryAgriculture => 'Agriculture';

  @override
  String get categoryTextile => 'Textile';

  @override
  String get categoryFoodProcessing => 'Food processing';

  @override
  String get categoryManufacturing => 'Manufacturing';

  @override
  String get noMarketInsights => 'No market insights available yet.';

  @override
  String get takePhotoAction => 'Take Photo';

  @override
  String get chooseFromGalleryAction => 'Choose from Gallery';

  @override
  String get uploadingPhotoProgress => 'Uploading photo...';

  @override
  String get removePhotoAction => 'Remove photo';

  @override
  String get photoUploadFailed =>
      'Photo could not be uploaded. Please try again.';

  @override
  String get unsupportedPhotoFormat =>
      'Unsupported photo format. Please select a JPEG, PNG, or WebP photo.';

  @override
  String get photoTooLarge =>
      'Photo exceeds 5 MB limit. Please select a smaller photo.';

  @override
  String get maxPhotosReached => 'Maximum 4 photos reached';

  @override
  String get tryAnotherPhoto => 'Please choose another photo';

  @override
  String get removePhotoConfirmation => 'Do you want to remove this photo?';

  @override
  String get photoRemovedMessage => 'Photo removed';

  @override
  String get choosePhotoSource => 'Add Product Photo';

  @override
  String get deletePhoto => 'Delete';

  @override
  String get productMustBeSavedBeforePhotos =>
      'Please save product draft before adding photos';

  @override
  String get improvePhotoAction => 'Improve Photo';

  @override
  String get improvingPhotoProgress => 'Improving photo...';

  @override
  String get originalPhotoLabel => 'Original';

  @override
  String get improvedPhotoLabel => 'Improved';

  @override
  String get keepOriginalAction => 'Keep Original';

  @override
  String get useImprovedAction => 'Use Improved Photo';

  @override
  String get photoImprovedTitle => 'Photo Improved';

  @override
  String get photoImproveFailed => 'Could not improve photo. Please try again.';

  @override
  String get aiImproveDisclaimer =>
      'AI improves only the presentation, not your product.';

  @override
  String get aiImproveHelpText =>
      'Cleans background, improves lighting, and centers the product.';

  @override
  String get comparePhotosTitle => 'Compare Photos';

  @override
  String get photoImproveSuccessMessage => 'Improved photo applied';

  @override
  String get productPhotosTitle => 'Product Photos';

  @override
  String get addPhotosNameFirst => 'Add a product name before adding photos.';

  @override
  String get choosePhotoAction => 'Choose Photo';

  @override
  String get addProductHelper =>
      'Enter product details, price, and optional photos.';

  @override
  String get discardChangesTitle => 'Discard changes?';

  @override
  String get discardChangesMessage =>
      'Your unsaved product details will be lost.';

  @override
  String get keepEditingAction => 'Keep Editing';

  @override
  String get discardAction => 'Discard';

  @override
  String get pickerUnavailableError =>
      'Photo picker is not available on this device. Please restart the application.';

  @override
  String get storageUnavailableError =>
      'Image storage service is not available.';

  @override
  String get productDetailsTitle => 'Product Details';

  @override
  String get noDescriptionAdded => 'No description added';

  @override
  String get deleteProductAction => 'Delete Product';

  @override
  String get verificationAndCompliance => 'Verification & Compliance';

  @override
  String get businessProducerInfo => 'Business & Producer Details';

  @override
  String get accountAndSecurity => 'Account & Security';

  @override
  String get helpAndAbout => 'Help & About';

  @override
  String get voiceGuidanceLanguage => 'Voice Guidance Language';

  @override
  String get voiceGuidanceSameAsApp => 'Same as App Language';

  @override
  String get verifiedProducer => 'Verified Producer';

  @override
  String get unverifiedProducer => 'Producer';

  @override
  String get panNotVerified => 'Not Verified';

  @override
  String get identityVerified => 'Completed';

  @override
  String get identityNotVerified => 'Pending';

  @override
  String get gstRegisteredBadge => 'Registered';

  @override
  String get gstNotRegisteredBadge => 'Not Registered';

  @override
  String get aadhaarStatusLabel => 'Aadhaar Identity';

  @override
  String get panIdentityLabel => 'PAN Identity';

  @override
  String get gstComplianceLabel => 'GST';

  @override
  String get workshopLocationLabel => 'Workshop Location';

  @override
  String get businessLocationTitle => 'Business Location';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get resetPasswordDesc =>
      'Send password reset instructions to your registered email';

  @override
  String get resetPasswordSuccess => 'Password reset link sent to your email';

  @override
  String get activeSession => 'Current Session';

  @override
  String get activeSessionTruthful => 'Signed in';

  @override
  String get signOutConfirmTitle => 'Sign out of VyaparSetu?';

  @override
  String get signOutConfirmMessage => 'Are you sure you want to sign out?';

  @override
  String get howVyaparSetuWorks => 'How VyaparSetu Works';

  @override
  String get howVyaparSetuWorksContent =>
      'VyaparSetu connects artisan producers directly with verified bulk and retail buyers. Add your products, share photos, and respond to buyer inquiries with complete transparency.';

  @override
  String get privacyAndData => 'Privacy & Data';

  @override
  String get privacyAndDataContent =>
      'Sensitive identity information is minimized. Raw PAN is not displayed in the app. Aadhaar numbers are not displayed or carried in the Profile UI. Access to producer data is protected by authentication and database ownership policies.';

  @override
  String get aboutVyaparSetu => 'About VyaparSetu';

  @override
  String get aboutVyaparSetuContent =>
      'VyaparSetu v1.0 — Empowering Indian artisan producers and manufacturers through direct commerce, localization, and trusted verification.';

  @override
  String get phoneLabel => 'Contact Phone';

  @override
  String get quickMenuTitle => 'Quick Actions';

  @override
  String get ok => 'OK';

  @override
  String get craftCategory => 'Craft Category';

  @override
  String get identityVerification => 'Identity Verification';

  @override
  String get producerRoleBadge => 'Producer';

  @override
  String get signInWithEmailOtp => 'Sign in with OTP';

  @override
  String get orDivider => 'OR';

  @override
  String get checkYourEmailTitle => 'Check Your Email';

  @override
  String checkYourEmailSubtitle(String email) {
    return 'We sent a verification code to $email';
  }

  @override
  String get verifyAndSignIn => 'Verify & Sign In';

  @override
  String get forgotPasswordTitle => 'Reset Your Password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email address to receive a recovery code.';

  @override
  String get sendRecoveryCode => 'Send Recovery Code';

  @override
  String get recoveryEmailSentNeutralNotice =>
      'If an account exists for this email, we\'ve sent a verification code.';

  @override
  String enterRecoveryCodeSubtitle(String email) {
    return 'Enter the verification code sent to $email';
  }

  @override
  String get verifyCode => 'Verify Code';

  @override
  String get createNewPasswordTitle => 'Create New Password';

  @override
  String get createNewPasswordSubtitle =>
      'Create a new strong password for your account.';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordHint => 'Enter new password (min 6 characters)';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdatedSuccess => 'Your password has been updated.';

  @override
  String get noAccountFoundWithEmail =>
      'No account found with this email. Try signing up.';

  @override
  String get yourBusinessTitle => 'Your Business';

  @override
  String get yourBusinessSubtitle =>
      'Tell us a little about what you make and where your business is based.';

  @override
  String get aboutYourBusinessTitle => 'About Your Business';

  @override
  String get aboutYourBusinessSubtitle =>
      'Help us understand your business better. You can skip this step.';

  @override
  String get aboutYourBusinessPlaceholderNote =>
      'About Your Business details will be available in the upcoming update.';

  @override
  String get businessBrandNameLabel => 'Business / Brand Name';

  @override
  String get businessBrandNameHelper =>
      'No brand name? You can use your own name.';

  @override
  String get businessBrandNameHint => 'e.g. Ramesh Handlooms or Ramesh Kumar';

  @override
  String get businessCategoryLabel => 'Business Category *';

  @override
  String get selectCategoryHint => 'Select a category';

  @override
  String get categoryFoodHomemade => 'Food & Homemade Products';

  @override
  String get categoryHandicrafts => 'Handicrafts';

  @override
  String get categoryClothingTextiles => 'Clothing & Textiles';

  @override
  String get categoryJewelleryAccessories => 'Jewellery & Accessories';

  @override
  String get categoryHomeDecor => 'Home & Decor';

  @override
  String get categoryAgricultureProducts => 'Agriculture-based Products';

  @override
  String get categoryBeautyPersonalCare => 'Beauty & Personal Care';

  @override
  String get categoryOtherCraft => 'Other';

  @override
  String get whatDoYouMakeLabel => 'What do you make? (Optional)';

  @override
  String get whatDoYouMakeHelper =>
      'For example: homemade pickles, phulkari suits, wooden toys...';

  @override
  String get whatDoYouMakeHint => 'Describe what you make and sell';

  @override
  String get areaVillageCityLabel => 'Area / Village / City *';

  @override
  String get areaVillageCityHint => 'e.g. Rampur Village or Sanganer';

  @override
  String get businessNameRequired =>
      'Please enter your business or brand name (at least 2 characters).';

  @override
  String get categoryRequired => 'Please select your primary product category.';

  @override
  String get stateRequired => 'Please select your state or union territory.';

  @override
  String get districtRequired =>
      'Please enter your district (at least 2 characters).';

  @override
  String get cityRequired =>
      'Please enter your area, village, or city (at least 2 characters).';

  @override
  String get pincodeInvalid => 'Please enter a valid 6-digit Indian PIN code.';

  @override
  String get yourBusinessSaved => 'Business details saved successfully.';

  @override
  String get teamSizeTitle => 'Team / Business Size';

  @override
  String get teamSizeSolo => 'Just me';

  @override
  String get teamSize2_5 => '2–5 people';

  @override
  String get teamSize6_10 => '6–10 people';

  @override
  String get teamSize11_25 => '11–25 people';

  @override
  String get teamSize25Plus => '25+ people';

  @override
  String get monthlySalesTitle => 'Typical Monthly Sales';

  @override
  String get monthlySalesBelow10k => 'Less than ₹10,000';

  @override
  String get monthlySales10k50k => '₹10,000–₹50,000';

  @override
  String get monthlySales50k1l => '₹50,000–₹1 lakh';

  @override
  String get monthlySales1l5l => '₹1–₹5 lakh';

  @override
  String get monthlySalesAbove5l => 'Above ₹5 lakh';

  @override
  String get monthlySalesPreferNotToSay => 'Prefer not to say';

  @override
  String get productionCapacityTitle => 'How much can you usually produce?';

  @override
  String get quantityLabel => 'Quantity';

  @override
  String get quantityHint => 'e.g. 50';

  @override
  String get periodLabel => 'Period';

  @override
  String get unitPieces => 'Pieces';

  @override
  String get unitLitres => 'Litres';

  @override
  String get unitPacks => 'Packs';

  @override
  String get unitBoxes => 'Boxes';

  @override
  String get unitOther => 'Other';

  @override
  String get periodWeek => 'Per Week';

  @override
  String get periodMonth => 'Per Month';

  @override
  String get periodYear => 'Per Year';

  @override
  String get sellingChannelsTitle => 'Where do you currently sell?';

  @override
  String get channelLocalCustomers => 'Local customers';

  @override
  String get channelLocalShops => 'Local shops';

  @override
  String get channelWhatsapp => 'WhatsApp';

  @override
  String get channelSocialMedia => 'Instagram / Facebook';

  @override
  String get channelOnlineMarketplaces => 'Online marketplaces';

  @override
  String get channelExhibitionsFairs => 'Exhibitions / Fairs';

  @override
  String get channelNotSellingYet => 'Haven’t started selling yet';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get completeSetup => 'Complete Setup';

  @override
  String get capacityAllOrNoneRequired =>
      'Please specify quantity, unit, and period for production capacity, or leave all three empty.';

  @override
  String get capacityPositiveRequired =>
      'Production capacity quantity must be a positive number.';

  @override
  String get optionalBadge => 'Optional';

  @override
  String get reachMoreBuyers => 'Reach more buyers across India';

  @override
  String get verifyBusinessPrompt =>
      'Verify your business to build trust and unlock eligible wider-market features.';

  @override
  String get verifyMyBusiness => 'Verify My Business';

  @override
  String get businessVerification => 'Business Verification';

  @override
  String get businessVerificationSubtitle =>
      'Verify your business details and build buyer trust.';

  @override
  String get businessVerificationIntro =>
      'Complete your business details to build trust and access eligible VyaparSetu features.';

  @override
  String get businessVerificationComplete => 'Business details recorded';

  @override
  String verificationStepsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count steps remaining',
      one: '1 step remaining',
    );
    return '$_temp0';
  }

  @override
  String verificationStepsCompleted(int completed, int total) {
    return '$completed of $total completed';
  }

  @override
  String get emailVerificationLabel => 'Email';

  @override
  String get emailVerifiedBadge => 'Verified';

  @override
  String get emailNotVerifiedBadge => 'Not verified';

  @override
  String get businessIdentityLabel => 'Business Identity';

  @override
  String get businessIdentityDesc =>
      'Verify your PAN to confirm your business identity.';

  @override
  String get panVerifiedBadge => 'Details Added';

  @override
  String get panNotVerifiedBadge => 'Not provided';

  @override
  String get gstRegistrationLabel => 'GST Registration';

  @override
  String get gstRegistrationDesc =>
      'Record your GST registration to access eligible wider-market features on VyaparSetu.';

  @override
  String get gstOptionalNotProvided => 'Optional • Not provided';

  @override
  String get gstOptionalDesc =>
      'GST details are optional here. You can add them later if applicable to your business.';

  @override
  String get gstVerificationPending => 'Checking format';

  @override
  String get gstVerifiedBadge => 'Details Added';

  @override
  String get gstNotVerifiedBadge => 'Not provided';

  @override
  String get verifyPanAction => 'Add PAN';

  @override
  String get addOrVerifyGstAction => 'Add GSTIN';

  @override
  String get panVerificationComingSoonTitle => 'PAN Verification';

  @override
  String get panVerificationComingSoonDesc =>
      'PAN verification flow is being updated for progressive onboarding. Your recorded status will appear here once submitted.';

  @override
  String get gstVerificationComingSoonTitle => 'GST Registration';

  @override
  String get gstVerificationComingSoonDesc =>
      'GST details are optional here. You can add them later if applicable to your business.';

  @override
  String get panVerificationSheetTitle => 'Business Identity (PAN)';

  @override
  String get panVerificationSheetDesc =>
      'Enter your 10-character PAN to record your business identity on VyaparSetu.';

  @override
  String get panInputLabel => 'PAN Number';

  @override
  String get panInputHint => 'e.g. ABCDE1234F';

  @override
  String get panInvalidFormatError =>
      'Please enter a valid 10-character PAN (e.g. ABCDE1234F).';

  @override
  String get panVerificationSuccess => 'PAN details recorded successfully.';

  @override
  String get panAlreadyLinkedError =>
      'A PAN is already associated with this account.';

  @override
  String get panVerificationFailedError =>
      'PAN details could not be recorded. Please check your details.';

  @override
  String get gstVerificationSheetTitle => 'GST Registration (GSTIN)';

  @override
  String get gstVerificationSheetDesc =>
      'Enter your 15-character GSTIN to record your GST details on VyaparSetu.';

  @override
  String get gstInputLabel => 'GSTIN';

  @override
  String get gstInputHint => 'e.g. 07AAAAA0000A1Z5';

  @override
  String get gstInvalidFormatError =>
      'Please enter a valid 15-character GSTIN (e.g. 07AAAAA0000A1Z5).';

  @override
  String get gstInvalidStateCodeError =>
      'Invalid state code in GSTIN. First 2 digits must be between 01-38, 97, or 99.';

  @override
  String get gstVerificationSuccess => 'GSTIN details recorded successfully.';

  @override
  String get gstAlreadyLinkedError =>
      'A GSTIN is already associated with this account.';

  @override
  String get gstVerificationFailedError =>
      'GSTIN details could not be recorded. Please check your 15-digit GSTIN.';

  @override
  String get verifyingAction => 'Checking...';

  @override
  String get verifyAction => 'Submit';
}
