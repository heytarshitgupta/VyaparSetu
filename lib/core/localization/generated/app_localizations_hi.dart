// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'व्यापार सेतु';

  @override
  String get appSubtitle =>
      'कारीगरों और उत्पादकों को सीधे भारत भर के खरीदारों से जोड़ना';

  @override
  String get chooseHowToContinue =>
      'चुनें कि आप ऐप का उपयोग कैसे करना चाहते हैं:';

  @override
  String get roleBuyerTitle => 'मुझे उत्पाद खरीदने हैं';

  @override
  String get roleBuyerDescription => 'उत्पाद खोजें और सीधे उत्पादकों से जुड़ें';

  @override
  String get roleProducerTitle => 'मैं सामान बनाता और बेचता हूँ';

  @override
  String get roleProducerDescription =>
      'अपनी प्रोफाइल बनाएं और अधिक खरीदारों तक पहुंचें';

  @override
  String get roleSelectionFooter =>
      'आप कभी भी अपने फोन या ईमेल से बदल या पंजीकरण कर सकते हैं।';

  @override
  String get home => 'होम';

  @override
  String get myProducts => 'मेरे उत्पाद';

  @override
  String get addProduct => 'उत्पाद जोड़ें';

  @override
  String get buyerNeeds => 'खरीदारों की जरूरतें';

  @override
  String get whatBuyersWant => 'खरीदार क्या चाहते हैं';

  @override
  String get myProfile => 'मेरी प्रोफाइल';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get welcome => 'स्वागत है';

  @override
  String get continueButton => 'आगे बढ़ें';

  @override
  String get back => 'पीछे जाएं';

  @override
  String get save => 'सहेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get verify => 'सत्यापित करें';

  @override
  String get verified => 'सत्यापित';

  @override
  String get notVerified => 'सत्यापित नहीं';

  @override
  String get signInTitle => 'लॉग इन करें';

  @override
  String get signInSubtitle =>
      'अपने उत्पाद प्रबंधित करने, खरीदारों की जरूरतें देखने और ऑर्डर ट्रैक करने के लिए लॉग इन करें।';

  @override
  String get createAccountTitle => 'खाता बनाएं';

  @override
  String get createYourAccountTitle => 'अपना खाता बनाएं';

  @override
  String get createAccountSubtitle =>
      'एक कारीगर उत्पादक के रूप में अपनी यात्रा शुरू करें और सीधे खरीदारों से जुड़ें।';

  @override
  String get createAccountSupportingCopy =>
      'व्यापार सेतु पर अपना व्यवसाय शुरू करें।';

  @override
  String get verifyYourEmailTitle => 'अपना ईमेल सत्यापित करें';

  @override
  String verifyYourEmailSubtitle(String email) {
    return 'हमने $email पर 6 अंकों का कोड भेजा है';
  }

  @override
  String get enterOtpPrompt => '6 अंकों का सत्यापन कोड दर्ज करें';

  @override
  String get verifyAndContinue => 'सत्यापित करें और आगे बढ़ें';

  @override
  String get resendCode => 'कोड दोबारा भेजें';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds सेकंड में कोड दोबारा भेजें';
  }

  @override
  String get changeEmail => 'ईमेल बदलें';

  @override
  String get otpInvalidLength => 'कृपया 6 अंकों का सही कोड दर्ज करें';

  @override
  String get otpIncorrectOrExpired => 'वह कोड गलत है या समाप्त हो गया है।';

  @override
  String get otpSentSuccess =>
      'आपकी ईमेल पर एक नया 6 अंकों का कोड भेज दिया गया है।';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get fullNameHint => 'उदा. रमेश कुमार';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get emailHint => 'producer@example.com';

  @override
  String get password => 'पासवर्ड';

  @override
  String get passwordHint => 'अपना पासवर्ड दर्ज करें';

  @override
  String get createPasswordHint => 'पासवर्ड बनाएं (कम से कम 6 अक्षर)';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get confirmPasswordHint => 'अपना पासवर्ड दोबारा दर्ज करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get signInWithPhone => 'फोन ओटीपी से लॉग इन करें';

  @override
  String get signUpWithPhone => 'फोन ओटीपी से खाता बनाएं';

  @override
  String get newHere => 'नए हैं? ';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? ';

  @override
  String get enterFullName => 'कृपया अपना पूरा नाम दर्ज करें';

  @override
  String get nameTooShort => 'नाम कम से कम 2 अक्षरों का होना चाहिए';

  @override
  String get enterEmail => 'कृपया अपना ईमेल पता दर्ज करें';

  @override
  String get enterValidEmail => 'कृपया एक मान्य ईमेल पता दर्ज करें';

  @override
  String get enterPassword => 'कृपया अपना पासवर्ड दर्ज करें';

  @override
  String get createPassword => 'कृपया पासवर्ड बनाएं';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए';

  @override
  String get confirmYourPassword => 'कृपया अपने पासवर्ड की पुष्टि करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get phoneFeatureUpcoming =>
      'फोन से लॉग इन अगली अपडेट में उपलब्ध होगा।';

  @override
  String get forgotPasswordUpcoming => 'पासवर्ड रीसेट जल्द ही उपलब्ध होगा।';

  @override
  String get language => 'भाषा';

  @override
  String get appearance => 'रंग-रूप';

  @override
  String get chooseAppearance => 'रंग-रूप चुनें';

  @override
  String get themeLight => 'लाइट (हल्का)';

  @override
  String get themeDark => 'डार्क (गहरा)';

  @override
  String get themeSystem => 'फोन की सेटिंग अनुसार';

  @override
  String get producerSetup => 'उत्पादक पंजीकरण';

  @override
  String get exit => 'बाहर निकलें';

  @override
  String stepOf(int current, int total) {
    return 'कदम $current / $total';
  }

  @override
  String percentCompleted(int percent) {
    return '$percent% पूरा हुआ';
  }

  @override
  String get submitApplication => 'आवेदन जमा करें';

  @override
  String get onboardingReviewSubmitted =>
      'समीक्षा जमा कर दी गई है। अंतिम प्रक्रिया अगले चरणों में पूरी होगी।';

  @override
  String get step1Title => 'आपके बारे में';

  @override
  String get step1Subtitle => 'आपका नाम और संपर्क विवरण';

  @override
  String get step2Title => 'आपका काम';

  @override
  String get step2Subtitle => 'आप क्या बनाते और बेचते हैं';

  @override
  String get step3Title => 'काम का पता';

  @override
  String get step3Subtitle => 'आपकी कार्यशाला या दुकान का पता';

  @override
  String get step4Title => 'सत्यापन';

  @override
  String get step4Subtitle => 'पहचान और कार्य विवरण';

  @override
  String get step5Title => 'जांचें और जमा करें';

  @override
  String get step5Subtitle => 'पुष्टि करें और बेचना शुरू करें';

  @override
  String get step1Header => 'कारीगर का मूल विवरण';

  @override
  String get step1Description =>
      'खरीदारों से बातचीत के लिए अपना नाम और संपर्क जानकारी दर्ज करें।';

  @override
  String get fullNameLabel => 'पूरा नाम *';

  @override
  String get enterFullNameHint => 'अपना पूरा नाम दर्ज करें';

  @override
  String get fullNameHelper => 'वह नाम जो व्यापार सेतु पर दिखेगा';

  @override
  String get emailAddressLogin => 'ईमेल पता (लॉग इन)';

  @override
  String get notProvided => 'उपलब्ध नहीं';

  @override
  String get readOnly => 'केवल पढ़ने के लिए';

  @override
  String get emailHelper => 'आपका लॉगिन ईमेल आपके खाते से जुड़ा है';

  @override
  String get verifiedLoginPhone => 'सत्यापित फोन नंबर';

  @override
  String get contactPhoneNumber => 'संपर्क फोन नंबर';

  @override
  String get verifiedAuth => 'सत्यापित';

  @override
  String get verifiedPhoneHelper =>
      'यह फोन नंबर सत्यापित है और आपके खाते से जुड़ा है';

  @override
  String get enter10DigitPhoneHint => '10 अंकों का मोबाइल नंबर दर्ज करें';

  @override
  String get contactPhoneHelper => 'व्यापार संबंधी बातचीत के लिए संपर्क नंबर';

  @override
  String get step2Header => 'काम और उत्पाद का विवरण';

  @override
  String get step2Description =>
      'खरीदारों को अपने काम, दुकान या घर से बने उत्पादों के बारे में बताएं।';

  @override
  String get businessNameLabel => 'काम या दुकान का नाम *';

  @override
  String get businessNameHint => 'उदा. शर्मा अचार, पंजाब फुलकारी वर्क्स';

  @override
  String get businessNameHelper => 'आपके काम, दुकान या कार्यशाला का नाम';

  @override
  String get craftCategoryLabel => 'उत्पाद की श्रेणी *';

  @override
  String get craftCategoryHelper =>
      'मुख्य श्रेणी चुनें ताकि खरीदार आपको आसानी से ढूंढ सकें';

  @override
  String get specifyCategory => 'अपनी श्रेणी बताएं *';

  @override
  String get specifyCategoryHint =>
      'उदा. बांस का काम, मिट्टी के बर्तन, पत्थर की नक्काशी';

  @override
  String get specifyCategoryHelper => 'अपनी श्रेणी का नाम लिखें';

  @override
  String get shortDescriptionLabel => 'संक्षिप्त विवरण (वैकल्पिक)';

  @override
  String get shortDescriptionHint => 'खरीदारों को बताएं कि आप क्या बनाते हैं';

  @override
  String get shortDescriptionHelper => 'संक्षेप में बताएं कि आप क्या बनाते हैं';

  @override
  String get catFood => 'खाद्य और घरेलू उत्पाद';

  @override
  String get catHandicrafts => 'हस्तशिल्प';

  @override
  String get catHandloom => 'हथकरघा और वस्त्र';

  @override
  String get catClothing => 'कपड़े और कढ़ाई';

  @override
  String get catJewellery => 'गहने और आभूषण';

  @override
  String get catWoodwork => 'लकड़ी का काम';

  @override
  String get catMetalCraft => 'धातु शिल्प';

  @override
  String get catHomeDecor => 'घर की सजावट';

  @override
  String get catBeauty => 'सौंदर्य और देखभाल';

  @override
  String get catOther => 'अन्य';

  @override
  String get step3Header => 'काम करने का स्थान';

  @override
  String get step3Description =>
      'अपनी दुकान, कार्यशाला या घर का पता दर्ज करें ताकि खरीदार डिलीवरी और पिकअप की योजना बना सकें।';

  @override
  String get stateLabel => 'राज्य / केंद्र शासित प्रदेश *';

  @override
  String get selectStateHint => 'अपना राज्य या केंद्र शासित प्रदेश चुनें';

  @override
  String get districtLabel => 'जिला *';

  @override
  String get districtHint => 'उदा. जयपुर, लुधियाना';

  @override
  String get districtHelper => 'वह जिला जहाँ आप सामान बनाते हैं';

  @override
  String get cityVillageLabel => 'शहर / गाँव *';

  @override
  String get cityVillageHint => 'उदा. सांगानेर, खन्ना';

  @override
  String get cityVillageHelper => 'आपका शहर, कस्बा या गाँव';

  @override
  String get pincodeLabel => 'पिन कोड *';

  @override
  String get pincodeHint => 'उदा. 302029';

  @override
  String get pincodeHelper => '6 अंकों का पिन कोड (0 से शुरू नहीं हो सकता)';

  @override
  String get addressLabel => 'काम या कार्यशाला का पता *';

  @override
  String get addressHint => 'गली, लैंडमार्क, या मकान नंबर...';

  @override
  String get addressHelper => 'जहाँ आप उत्पाद बनाते या रखते हैं';

  @override
  String get step4Header => 'पहचान और सत्यापन';

  @override
  String get step4Description =>
      'खरीदारों का भरोसा जीतने के लिए अपनी जानकारी सत्यापित करें।';

  @override
  String get demoDisclosure =>
      'डेमो सत्यापन वातावरण • इस प्रोटोटाइप में सत्यापन सिम्युलेटेड है।';

  @override
  String get panVerification => 'पैन सत्यापन';

  @override
  String get panVerified => 'सत्यापित';

  @override
  String get secureIdentityVerification => 'सुरक्षित पहचान सत्यापन';

  @override
  String get verifiedInDemoEnvironment => 'डेमो वातावरण में सत्यापित';

  @override
  String get verifiedPan => 'सत्यापित पैन';

  @override
  String get editDetails => 'विवरण बदलें';

  @override
  String get panSecurityNote =>
      'आपके पैन विवरण सुरक्षित रूप से सत्यापित हैं। प्लेनटेक्स्ट पैन कभी संग्रहीत नहीं होता है।';

  @override
  String get panNumberLabel => 'पैन नंबर *';

  @override
  String get panNumberHint => 'ABCDE1234F';

  @override
  String get panNumberHelper => '10 अक्षरों का पैन नंबर';

  @override
  String get nameAsPerPanLabel => 'पैन अनुसार नाम *';

  @override
  String get nameAsPerPanHint => 'पैन कार्ड पर लिखा नाम दर्ज करें';

  @override
  String get nameAsPerPanHelper => 'आधिकारिक पैन रिकॉर्ड से मेल खाना चाहिए';

  @override
  String get dobLabel => 'जन्म तिथि *';

  @override
  String get selectDobHint => 'जन्म तिथि चुनें (दिन/महीना/वर्ष)';

  @override
  String get panPrivacyShield =>
      'आपके पैन नंबर का उपयोग केवल सत्यापन के लिए किया जाता है।';

  @override
  String get verifyPan => 'पैन सत्यापित करें';

  @override
  String get checkingDetails => 'जांच हो रही है...';

  @override
  String get tryAgain => 'पुनः प्रयास करें';

  @override
  String get aadhaarVerification => 'आधार सत्यापन';

  @override
  String get aadhaarSubtitle => 'अधिकृत सेवा के माध्यम से पहचान सत्यापन';

  @override
  String get aadhaarDescription =>
      'आधार का उपयोग करके अपनी पहचान सत्यापित करें। यह सुरक्षित है और खरीदारों का भरोसा बढ़ाता है।';

  @override
  String get verifyAadhaar => 'आधार सत्यापित करें';

  @override
  String get aadhaarDialogContent =>
      'आधार सत्यापन अधिकृत सेवा के माध्यम से उपलब्ध होगा। यह इस प्रोटोटाइप में सक्षम नहीं है।';

  @override
  String get gotIt => 'समझ गया';

  @override
  String get gstRegistration => 'जीएसटी पंजीकरण';

  @override
  String get gstDeclared => 'घोषित जीएसटी पंजीकरण';

  @override
  String get gstStatusSubtitle => 'व्यावसायिक कर पंजीकरण स्थिति';

  @override
  String get areYouGstRegistered => 'क्या आप जीएसटी के लिए पंजीकृत हैं? *';

  @override
  String get yes => 'हाँ';

  @override
  String get no => 'नहीं';

  @override
  String get gstNotRegisteredNotice =>
      'जीएसटी पंजीकृत नहीं है। सीमा से कम वाले कारीगर बिना जीएसटी जारी रख सकते हैं।';

  @override
  String get gstinNumberLabel => 'जीएसटी नंबर *';

  @override
  String get gstinHint => '07AAAAA0000A1Z5';

  @override
  String get gstinHelper => '15 अक्षरों का जीएसटी नंबर';

  @override
  String get verifyGstin => 'जीएसटी सत्यापित करें';

  @override
  String get gstUpcomingNotice => 'जीएसटी सत्यापन जल्द ही जोड़ा जाएगा।';

  @override
  String get badgeNotVerified => 'सत्यापित नहीं';

  @override
  String get badgeChecking => 'जांच हो रही है...';

  @override
  String get badgeVerified => 'सत्यापित';

  @override
  String get badgeCouldNotVerify => 'सत्यापित नहीं हो सका';

  @override
  String get badgeComingSoon => 'जल्द आ रहा है';

  @override
  String get badgeNotRegistered => 'पंजीकृत नहीं';

  @override
  String get step5CardTitle => 'समीक्षा और सबमिट करें';

  @override
  String get step5CardDescription =>
      'जमा करने से पहले अपने विवरण की समीक्षा करें। आप अपने डैशबोर्ड से कभी भी बदलाव कर सकते हैं।';

  @override
  String get profileStatus => 'प्रोफाइल स्थिति';

  @override
  String get readyForSubmission => 'जमा करने के लिए तैयार';

  @override
  String get nextStage => 'अगला चरण';

  @override
  String get nextStageDescription =>
      'खरीदारों की जरूरतों और उत्पादों तक सीधी पहुंच';

  @override
  String welcomeProducer(String name) {
    return 'नमस्ते, $name';
  }

  @override
  String get producerDefaultName => 'उत्पादक';

  @override
  String get producerHomeSubtitle =>
      'अपनी कारीगरी का प्रबंधन करें और खरीदारों से जुड़ें';

  @override
  String get addProductActionSubtitle =>
      'खरीदारों को दिखाएं कि आप क्या बनाते हैं';

  @override
  String get myProductsShortcutSubtitle => 'अपने जोड़े हुए उत्पाद देखें';

  @override
  String get buyerNeedsShortcutSubtitle => 'देखें कि खरीदार क्या खोज रहे हैं';

  @override
  String get whatBuyersWantShortcutSubtitle =>
      'देखें कि लोग कौन से उत्पाद चाहते हैं';

  @override
  String get noProductsListedTitle => 'अभी तक कोई उत्पाद नहीं जोड़ा गया';

  @override
  String get noProductsListedSubtitle =>
      'खरीदारों को अपनी कारीगरी दिखाने के लिए अपना पहला उत्पाद जोड़ें';

  @override
  String get buyerNeedsWaitingTitle => 'खरीदारों की जरूरतें यहाँ दिखेंगी';

  @override
  String get buyerNeedsWaitingSubtitle =>
      'खरीदारों की मांगें उपलब्ध होने पर यहाँ दिखाई देंगी';

  @override
  String get featureComingSoon => 'यह सुविधा अगले अपडेट में उपलब्ध होगी';

  @override
  String get signOutAction => 'साइन आउट';

  @override
  String get myProductsSubtitle =>
      'अपने बनाए और बेचे जाने वाले उत्पादों का प्रबंधन करें';

  @override
  String get filterAll => 'सभी';

  @override
  String get filterActive => 'सक्रिय';

  @override
  String get filterDraft => 'ड्राफ्ट';

  @override
  String get filterHidden => 'निष्क्रिय';

  @override
  String get filterInactive => 'निष्क्रिय';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusDraft => 'ड्राफ्ट';

  @override
  String get statusHidden => 'निष्क्रिय';

  @override
  String get statusInactive => 'निष्क्रिय';

  @override
  String get editAction => 'संपादित करें';

  @override
  String get continueEditingAction => 'संपादन जारी रखें';

  @override
  String get saveChangesAction => 'बदलाव सहेजें';

  @override
  String get makeActiveAction => 'सक्रिय करें';

  @override
  String get makeInactiveAction => 'निष्क्रिय करें';

  @override
  String get editProductTitle => 'उत्पाद संपादित करें';

  @override
  String get editProductHelper => 'अपने उत्पाद का विवरण और फ़ोटो अपडेट करें';

  @override
  String get deleteProductConfirmTitle => 'उत्पाद हटाएं?';

  @override
  String get deleteProductConfirmBody =>
      'यह इस उत्पाद और इसकी तस्वीरों को स्थायी रूप से हटा देगा।';

  @override
  String get productUpdatedSuccess => 'उत्पाद अपडेट हो गया';

  @override
  String get productMadeActiveSuccess => 'उत्पाद सक्रिय कर दिया गया';

  @override
  String get productMadeInactiveSuccess => 'उत्पाद निष्क्रिय कर दिया गया';

  @override
  String get couldNotUpdateProduct => 'उत्पाद अपडेट नहीं किया जा सका';

  @override
  String get couldNotLoadProductPhoto => 'उत्पाद की फ़ोटो लोड नहीं हो सकी';

  @override
  String get incompleteProductCannotActivate =>
      'सक्रिय करने से पहले नाम, श्रेणी और कीमत भरने के लिए कृपया उत्पाद संपादित करें।';

  @override
  String get priceNotSet => 'कीमत तय नहीं';

  @override
  String get draftNeedsCompletion => 'कीमत या विवरण बाकी है';

  @override
  String get noActiveProductsTitle => 'कोई सक्रिय उत्पाद नहीं';

  @override
  String get noActiveProductsSubtitle =>
      'लिस्टिंग के लिए तैयार उत्पाद यहाँ दिखाई देंगे';

  @override
  String get noDraftProductsTitle => 'कोई ड्राफ्ट उत्पाद नहीं';

  @override
  String get noDraftProductsSubtitle =>
      'अधूरे उत्पाद जिन पर काम बाकी है, यहाँ दिखाई देंगे';

  @override
  String get noHiddenProductsTitle => 'कोई निष्क्रिय उत्पाद नहीं';

  @override
  String get noHiddenProductsSubtitle =>
      'अस्थायी रूप से निष्क्रिय किए गए उत्पाद यहाँ दिखाई देंगे';

  @override
  String get noInactiveProductsTitle => 'कोई निष्क्रिय उत्पाद नहीं';

  @override
  String get noInactiveProductsSubtitle =>
      'आपके द्वारा निष्क्रिय किए गए उत्पाद यहां दिखाई देंगे';

  @override
  String get showAllProducts => 'सभी उत्पाद देखें';

  @override
  String get unableToLoadProducts => 'हम आपके उत्पाद लोड नहीं कर सके';

  @override
  String get unableToLoadSubtitle =>
      'कृपया अपना इंटरनेट कनेक्शन जांचें और पुनः प्रयास करें';

  @override
  String get notAuthenticatedMessage =>
      'अपने उत्पाद देखने के लिए कृपया साइन इन करें';

  @override
  String get retry => 'पुनः प्रयास करें';

  @override
  String get hideAction => 'छिपाएं';

  @override
  String get showAction => 'दिखाएं';

  @override
  String get deleteAction => 'हटाएं';

  @override
  String get deleteProductTitle => 'उत्पाद हटाएं?';

  @override
  String get deleteProductConfirmation =>
      'क्या आप वाकई इस उत्पाद को हटाना चाहते हैं? यह क्रिया पूर्ववत नहीं की जा सकती।';

  @override
  String get productHiddenSuccess => 'उत्पाद छिपा दिया गया';

  @override
  String get productActivatedSuccess => 'उत्पाद सक्रिय चिह्नित किया गया';

  @override
  String get productDeletedSuccess => 'उत्पाद हटा दिया गया';

  @override
  String get productActionFailed =>
      'उत्पाद अपडेट नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get productDeleteFailed =>
      'उत्पाद हटाया नहीं जा सका। कृपया पुनः प्रयास करें।';

  @override
  String stepCount(int current, int total) {
    return 'चरण $current / $total';
  }

  @override
  String get addProductStep1Title => 'आप क्या बनाते हैं?';

  @override
  String get addProductStep2Title => 'कीमत और विवरण';

  @override
  String get addProductStep3Title => 'फोटो जोड़ें और सेव करें';

  @override
  String get productNameLabel => 'उत्पाद का नाम';

  @override
  String get productNameHint => 'जैसे: घर का बना आम का अचार';

  @override
  String get productNameRequired => 'कृपया पहले उत्पाद का नाम दर्ज करें';

  @override
  String get categoryLabel => 'श्रेणी';

  @override
  String get categoryFood => 'खाद्य सामग्री';

  @override
  String get categoryHandicraft => 'हस्तशिल्प';

  @override
  String get categoryClothing => 'वस्त्र एवं परिधान';

  @override
  String get categoryHome => 'घरेलू सामान';

  @override
  String get categoryBeauty => 'सौंदर्य और देखभाल';

  @override
  String get categoryJewellery => 'आभूषण';

  @override
  String get categoryOther => 'अन्य';

  @override
  String get customCategoryLabel => 'श्रेणी बताएं';

  @override
  String get unitLabel => 'इकाई';

  @override
  String get unitPiece => 'नग / पीस';

  @override
  String get unitKg => 'किग्रा (Kg)';

  @override
  String get unitGram => 'ग्राम (g)';

  @override
  String get unitLitre => 'लीटर (L)';

  @override
  String get unitMl => 'मिलीलीटर (ml)';

  @override
  String get unitPack => 'पैकेट';

  @override
  String get unitDozen => 'दर्जन';

  @override
  String get priceLabel => 'कीमत';

  @override
  String get priceHelper => 'एक इकाई की कीमत दर्ज करें';

  @override
  String get priceInvalidError =>
      'कृपया सही कीमत दर्ज करें (जैसे: 250 या 250.50)';

  @override
  String get descriptionLabel => 'खरीदारों को अपने उत्पाद के बारे में बताएं';

  @override
  String get descriptionHelper => 'यह किस चीज़ से बना है? इसमें क्या खास है?';

  @override
  String get addPhotosHeading => 'फोटो जोड़ें';

  @override
  String get addPhotosSubtitle =>
      'फोटो खरीदारों को आपकी कारीगरी की गुणवत्ता देखने में मदद करती हैं';

  @override
  String get photoUploadComingNext =>
      'फोटो चयन की सुविधा अगले चरण में जोड़ी जाएगी';

  @override
  String get saveDraftAction => 'ड्राफ्ट सेव करें';

  @override
  String get markReadyAction => 'तैयार चिह्नित करें';

  @override
  String get markReadyGuidance => 'तैयार करने के लिए नाम, श्रेणी और कीमत भरें';

  @override
  String get draftSavedMessage => 'ड्राफ्ट सहेजा गया';

  @override
  String get productMarkedReadyMessage => 'उत्पाद तैयार चिह्नित किया गया';

  @override
  String get saveDraftFailed =>
      'ड्राफ्ट सेव नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get markReadyFailed =>
      'तैयार चिह्नित नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get whatBuyersWantSubtitle =>
      'अलग-अलग क्षेत्रों में मांग के नमूना रुझान देखें।';

  @override
  String get sampleMarketInsightsBadge => 'नमूना बाज़ार रुझान';

  @override
  String get sampleMarketInsightsNote =>
      'यह क्षेत्रीय रुझान खरीदारों की रुचि को समझने में मदद करने के लिए नमूना बाज़ार डेटा पर आधारित हैं।';

  @override
  String get demandHigh => 'अधिक मांग';

  @override
  String get demandMedium => 'मध्यम मांग';

  @override
  String get demandLow => 'कम मांग';

  @override
  String demandScoreOutOf(String score) {
    return '$score/100';
  }

  @override
  String signalDistrictLabel(String district) {
    return 'ज़िला: $district';
  }

  @override
  String topBuyingCityLabel(String city) {
    return 'प्रमुख खरीदार शहर: $city';
  }

  @override
  String get estimatedMonthlyDemandLabel => 'अनुमानित मासिक मांग';

  @override
  String estimatedUnitsValue(String count) {
    return '$count इकाइयां';
  }

  @override
  String get typicalOrderValueLabel => 'औसत ऑर्डर मूल्य';

  @override
  String get categoryAgriculture => 'कृषि';

  @override
  String get categoryTextile => 'वस्त्र उद्योग';

  @override
  String get categoryFoodProcessing => 'खाद्य प्रसंस्करण';

  @override
  String get categoryManufacturing => 'विनिर्माण';

  @override
  String get noMarketInsights => 'अभी कोई बाज़ार रुझान उपलब्ध नहीं हैं।';

  @override
  String get takePhotoAction => 'फ़ोटो खींचें';

  @override
  String get chooseFromGalleryAction => 'गैलरी से चुनें';

  @override
  String get uploadingPhotoProgress => 'फ़ोटो अपलोड हो रही है...';

  @override
  String get removePhotoAction => 'फ़ोटो हटाएं';

  @override
  String get photoUploadFailed =>
      'फ़ोटो अपलोड नहीं हो सकी। कृपया पुनः प्रयास करें।';

  @override
  String get unsupportedPhotoFormat =>
      'असमर्थित फ़ोटो प्रारूप। कृपया JPEG, PNG या WebP फ़ोटो चुनें।';

  @override
  String get photoTooLarge =>
      'फ़ोटो 5 MB सीमा से अधिक है। कृपया छोटी फ़ोटो चुनें।';

  @override
  String get maxPhotosReached => 'अधिकतम 4 फ़ोटो की सीमा पूरी हो गई है';

  @override
  String get tryAnotherPhoto => 'कृपया कोई अन्य फ़ोटो चुनें';

  @override
  String get removePhotoConfirmation => 'क्या आप इस फ़ोटो को हटाना चाहते हैं?';

  @override
  String get photoRemovedMessage => 'फ़ोटो हटा दी गई';

  @override
  String get choosePhotoSource => 'उत्पाद फ़ोटो जोड़ें';

  @override
  String get deletePhoto => 'हटाएं';

  @override
  String get productMustBeSavedBeforePhotos =>
      'फ़ोटो जोड़ने से पहले कृपया उत्पाद ड्राफ़्ट सहेजें';

  @override
  String get improvePhotoAction => 'फोटो सुधारें';

  @override
  String get improvingPhotoProgress => 'फोटो सुधारी जा रही है...';

  @override
  String get originalPhotoLabel => 'मूल फोटो';

  @override
  String get improvedPhotoLabel => 'सुधारी गई फोटो';

  @override
  String get keepOriginalAction => 'मूल फोटो रखें';

  @override
  String get useImprovedAction => 'सुधारी गई फोटो उपयोग करें';

  @override
  String get photoImprovedTitle => 'फोटो में सुधार हुआ';

  @override
  String get photoImproveFailed =>
      'फोटो नहीं सुधारी जा सकी। कृपया पुनः प्रयास करें।';

  @override
  String get aiImproveDisclaimer =>
      'एआई केवल प्रस्तुति में सुधार करता है, आपके उत्पाद में नहीं।';

  @override
  String get aiImproveHelpText =>
      'पृष्ठभूमि साफ करता है, रोशनी में सुधार करता है और उत्पाद को केंद्रित करता है।';

  @override
  String get comparePhotosTitle => 'फोटो की तुलना करें';

  @override
  String get photoImproveSuccessMessage => 'सुधारी गई फोटो लागू की गई';

  @override
  String get productPhotosTitle => 'उत्पाद की तस्वीरें';

  @override
  String get addPhotosNameFirst =>
      'तस्वीरें जोड़ने से पहले उत्पाद का नाम दर्ज करें।';

  @override
  String get choosePhotoAction => 'तस्वीर चुनें';

  @override
  String get addProductHelper =>
      'उत्पाद का विवरण, मूल्य और तस्वीरें दर्ज करें।';

  @override
  String get discardChangesTitle => 'बदलाव छोड़ें?';

  @override
  String get discardChangesMessage => 'आपके सहेजे न गए उत्पाद विवरण खो जाएंगे।';

  @override
  String get keepEditingAction => 'संपादन जारी रखें';

  @override
  String get discardAction => 'छोड़ें';

  @override
  String get pickerUnavailableError =>
      'इस उपकरण पर फोटो चयन उपलब्ध नहीं है। कृपया ऐप पुनः चालू करें।';

  @override
  String get storageUnavailableError => 'फोटो संग्रहण सेवा उपलब्ध नहीं है।';

  @override
  String get productDetailsTitle => 'उत्पाद विवरण';

  @override
  String get noDescriptionAdded => 'कोई विवरण नहीं जोड़ा गया';

  @override
  String get deleteProductAction => 'उत्पाद हटाएं';

  @override
  String get verificationAndCompliance => 'सत्यापन एवं अनुपालन';

  @override
  String get businessProducerInfo => 'व्यापार एवं निर्माता विवरण';

  @override
  String get accountAndSecurity => 'खाता एवं सुरक्षा';

  @override
  String get helpAndAbout => 'सहायता एवं परिचय';

  @override
  String get voiceGuidanceLanguage => 'आवाज मार्गदर्शन भाषा';

  @override
  String get voiceGuidanceSameAsApp => 'ऐप भाषा के समान';

  @override
  String get verifiedProducer => 'सत्यापित निर्माता';

  @override
  String get unverifiedProducer => 'निर्माता';

  @override
  String get panNotVerified => 'सत्यापित नहीं';

  @override
  String get identityVerified => 'पूर्ण';

  @override
  String get identityNotVerified => 'लंबित';

  @override
  String get gstRegisteredBadge => 'पंजीकृत';

  @override
  String get gstNotRegisteredBadge => 'पंजीकृत नहीं';

  @override
  String get aadhaarStatusLabel => 'आधार पहचान';

  @override
  String get panIdentityLabel => 'पैन पहचान';

  @override
  String get gstComplianceLabel => 'जीएसटी (GST)';

  @override
  String get workshopLocationLabel => 'कार्यशाला का स्थान';

  @override
  String get businessLocationTitle => 'व्यवसाय का स्थान';

  @override
  String get resetPassword => 'पासवर्ड रीसेट करें';

  @override
  String get resetPasswordDesc =>
      'अपने पंजीकृत ईमेल पर पासवर्ड रीसेट निर्देश भेजें';

  @override
  String get resetPasswordSuccess =>
      'पासवर्ड रीसेट लिंक आपके ईमेल पर भेज दिया गया है';

  @override
  String get activeSession => 'वर्तमान सत्र';

  @override
  String get activeSessionTruthful => 'साइन इन';

  @override
  String get signOutConfirmTitle => 'व्यापारसेतु से साइन आउट करें?';

  @override
  String get signOutConfirmMessage => 'क्या आप वाकई साइन आउट करना चाहते हैं?';

  @override
  String get howVyaparSetuWorks => 'व्यापारसेतु कैसे काम करता है';

  @override
  String get howVyaparSetuWorksContent =>
      'व्यापारसेतु कारीगरों और निर्माताओं को सीधे सत्यापित थोक व खुदरा खरीदारों से जोड़ता है। अपने उत्पाद जोड़ें, फोटो साझा करें और पूरी पारदर्शिता के साथ खरीदारों की पूछताछ का उत्तर दें।';

  @override
  String get privacyAndData => 'गोपनीयता एवं डेटा';

  @override
  String get privacyAndDataContent =>
      'संवेदनशील पहचान जानकारी को न्यूनतम रखा गया है। ऐप में मूल पैन (PAN) प्रदर्शित नहीं किया जाता है। आधार संख्या को प्रोफ़ाइल में प्रदर्शित या संग्रहीत नहीं किया जाता है। उत्पादक डेटा तक पहुंच प्रमाणीकरण और डेटाबेस स्वामित्व नीतियों द्वारा सुरक्षित है।';

  @override
  String get aboutVyaparSetu => 'व्यापारसेतु के बारे में';

  @override
  String get aboutVyaparSetuContent =>
      'व्यापारसेतु v1.0 — प्रत्यक्ष वाणिज्य, स्थानीयकरण और विश्वसनीय सत्यापन के माध्यम से भारतीय कारीगरों और निर्माताओं को सशक्त बनाना।';

  @override
  String get phoneLabel => 'संपर्क फोन';

  @override
  String get quickMenuTitle => 'त्वरित क्रियाएं';

  @override
  String get email => 'ईमेल';

  @override
  String get ok => 'ठीक है';

  @override
  String get businessName => 'व्यवसाय का नाम';

  @override
  String get craftCategory => 'शिल्प श्रेणी';

  @override
  String get identityVerification => 'पहचान सत्यापन';

  @override
  String get producerRoleBadge => 'कारीगर / उत्पादक';

  @override
  String get signInWithEmailOtp => 'ओटीपी से लॉग इन करें';

  @override
  String get orDivider => 'या';

  @override
  String get checkYourEmailTitle => 'अपना ईमेल देखें';

  @override
  String checkYourEmailSubtitle(String email) {
    return 'हमने $email पर एक सत्यापन कोड भेजा है';
  }

  @override
  String get verifyAndSignIn => 'सत्यापित करें और लॉग इन करें';

  @override
  String get forgotPasswordTitle => 'अपना पासवर्ड रीसेट करें';

  @override
  String get forgotPasswordSubtitle =>
      'रिकवरी कोड प्राप्त करने के लिए अपना ईमेल पता दर्ज करें।';

  @override
  String get sendRecoveryCode => 'रिकवरी कोड भेजें';

  @override
  String get recoveryEmailSentNeutralNotice =>
      'यदि इस ईमेल के लिए कोई खाता मौजूद है, तो हमने एक सत्यापन कोड भेजा है।';

  @override
  String enterRecoveryCodeSubtitle(String email) {
    return '$email पर भेजा गया सत्यापन कोड दर्ज करें';
  }

  @override
  String get verifyCode => 'कोड सत्यापित करें';

  @override
  String get createNewPasswordTitle => 'नया पासवर्ड बनाएं';

  @override
  String get createNewPasswordSubtitle =>
      'अपने खाते के लिए एक नया मजबूत पासवर्ड बनाएं।';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get newPasswordHint => 'नया पासवर्ड दर्ज करें (न्यूनतम 6 वर्ण)';

  @override
  String get updatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get passwordUpdatedSuccess => 'आपका पासवर्ड अपडेट कर दिया गया है।';

  @override
  String get noAccountFoundWithEmail =>
      'इस ईमेल से कोई खाता नहीं मिला। खाता बनाने का प्रयास करें।';

  @override
  String get yourBusinessTitle => 'आपका व्यवसाय';

  @override
  String get yourBusinessSubtitle =>
      'हमें थोड़ा बताएं कि आप क्या बनाते हैं और आपका व्यवसाय कहाँ स्थित है।';

  @override
  String get aboutYourBusinessTitle => 'आपके व्यवसाय के बारे में';

  @override
  String get aboutYourBusinessSubtitle =>
      'अपने व्यवसाय को बेहतर ढंग से समझने में हमारी सहायता करें। आप इस चरण को छोड़ सकते हैं।';

  @override
  String get aboutYourBusinessPlaceholderNote =>
      'व्यवसाय विवरण का यह चरण अगले अपडेट में उपलब्ध होगा।';

  @override
  String get businessBrandNameLabel => 'व्यवसाय / ब्रांड का नाम';

  @override
  String get businessBrandNameHelper =>
      'कोई ब्रांड नाम नहीं है? आप अपने नाम का उपयोग कर सकते हैं।';

  @override
  String get businessBrandNameHint => 'जैसे रमेश हैंडलूम या रमेश कुमार';

  @override
  String get businessCategoryLabel => 'व्यवसाय श्रेणी *';

  @override
  String get selectCategoryHint => 'एक श्रेणी चुनें';

  @override
  String get categoryFoodHomemade => 'खाद्य और घरेलू उत्पाद';

  @override
  String get categoryHandicrafts => 'हस्तशिल्प';

  @override
  String get categoryClothingTextiles => 'वस्त्र और परिधान';

  @override
  String get categoryJewelleryAccessories => 'आभूषण और सहायक उपकरण';

  @override
  String get categoryHomeDecor => 'गृह सज्जा';

  @override
  String get categoryAgricultureProducts => 'कृषि आधारित उत्पाद';

  @override
  String get categoryBeautyPersonalCare => 'सौंदर्य और व्यक्तिगत देखभाल';

  @override
  String get categoryOtherCraft => 'अन्य';

  @override
  String get whatDoYouMakeLabel => 'आप क्या बनाते हैं? (वैकल्पिक)';

  @override
  String get whatDoYouMakeHelper =>
      'उदाहरण के लिए: घर का बना अचार, फुलकारी सूट, लकड़ी के खिलौने...';

  @override
  String get whatDoYouMakeHint =>
      'आप जो उत्पाद बनाते और बेचते हैं उनका विवरण दें';

  @override
  String get areaVillageCityLabel => 'क्षेत्र / गाँव / शहर *';

  @override
  String get areaVillageCityHint => 'जैसे रामपुर गाँव या सांगानेर';

  @override
  String get businessNameRequired =>
      'कृपया अपने व्यवसाय या ब्रांड का नाम दर्ज करें (कम से कम 2 अक्षर)।';

  @override
  String get categoryRequired => 'कृपया अपनी मुख्य उत्पाद श्रेणी चुनें।';

  @override
  String get stateRequired => 'कृपया अपना राज्य या केंद्र शासित प्रदेश चुनें।';

  @override
  String get districtRequired =>
      'कृपया अपना ज़िला दर्ज करें (कम से कम 2 अक्षर)।';

  @override
  String get cityRequired =>
      'कृपया अपना क्षेत्र, गाँव या शहर दर्ज करें (कम से कम 2 अक्षर)।';

  @override
  String get pincodeInvalid => 'कृपया एक वैध 6-अंकों का पिन कोड दर्ज करें।';

  @override
  String get yourBusinessSaved => 'व्यवसाय विवरण सफलतापूर्वक सहेजा गया।';

  @override
  String get teamSizeTitle => 'टीम / व्यवसाय का आकार';

  @override
  String get teamSizeSolo => 'सिर्फ मैं';

  @override
  String get teamSize2_5 => '2–5 लोग';

  @override
  String get teamSize6_10 => '6–10 लोग';

  @override
  String get teamSize11_25 => '11–25 लोग';

  @override
  String get teamSize25Plus => '25+ लोग';

  @override
  String get monthlySalesTitle => 'सामान्य मासिक बिक्री';

  @override
  String get monthlySalesBelow10k => '₹10,000 से कम';

  @override
  String get monthlySales10k50k => '₹10,000–₹50,000';

  @override
  String get monthlySales50k1l => '₹50,000–₹1 लाख';

  @override
  String get monthlySales1l5l => '₹1–₹5 लाख';

  @override
  String get monthlySalesAbove5l => '₹5 लाख से अधिक';

  @override
  String get monthlySalesPreferNotToSay => 'बताना नहीं चाहते';

  @override
  String get productionCapacityTitle =>
      'आप आमतौर पर कितना उत्पादन कर सकते हैं?';

  @override
  String get quantityLabel => 'मात्रा';

  @override
  String get quantityHint => 'जैसे 50';

  @override
  String get periodLabel => 'अवधि';

  @override
  String get unitPieces => 'पीस (Pieces)';

  @override
  String get unitLitres => 'लीटर (Litres)';

  @override
  String get unitPacks => 'पैक (Packs)';

  @override
  String get unitBoxes => 'बॉक्स (Boxes)';

  @override
  String get unitOther => 'अन्य';

  @override
  String get periodWeek => 'प्रति सप्ताह';

  @override
  String get periodMonth => 'प्रति माह';

  @override
  String get periodYear => 'प्रति वर्ष';

  @override
  String get sellingChannelsTitle => 'वर्तमान में आप कहाँ बेचते हैं?';

  @override
  String get channelLocalCustomers => 'स्थानीय ग्राहक';

  @override
  String get channelLocalShops => 'स्थानीय दुकानें';

  @override
  String get channelWhatsapp => 'व्हाट्सएप (WhatsApp)';

  @override
  String get channelSocialMedia => 'इंस्टाग्राम / फेसबुक';

  @override
  String get channelOnlineMarketplaces => 'ऑनलाइन मार्केटप्लेस';

  @override
  String get channelExhibitionsFairs => 'प्रदर्शनियां / मेले';

  @override
  String get channelNotSellingYet => 'अभी बेचना शुरू नहीं किया';

  @override
  String get skipForNow => 'अभी छोड़ें';

  @override
  String get completeSetup => 'सेटअप पूरा करें';

  @override
  String get capacityAllOrNoneRequired =>
      'कृपया उत्पादन क्षमता के लिए मात्रा, इकाई और अवधि निर्दिष्ट करें, या तीनों को खाली छोड़ दें।';

  @override
  String get capacityPositiveRequired =>
      'उत्पादन क्षमता की मात्रा एक धनात्मक संख्या होनी चाहिए।';

  @override
  String get optionalBadge => 'वैकल्पिक';

  @override
  String get reachMoreBuyers => 'पूरे भारत में अधिक खरीदारों तक पहुँचें';

  @override
  String get verifyBusinessPrompt =>
      'विश्वास बनाने और बड़े बाज़ार की सुविधाओं का लाभ उठाने के लिए अपने व्यवसाय को सत्यापित करें।';

  @override
  String get verifyMyBusiness => 'व्यवसाय सत्यापित करें';

  @override
  String get businessVerification => 'व्यवसाय सत्यापन';

  @override
  String get businessVerificationSubtitle =>
      'खरीदारों का विश्वास बनाने के लिए अपने व्यवसाय का विवरण सत्यापित करें।';

  @override
  String get businessVerificationIntro =>
      'विश्वास बनाने और योग्य व्यापारसेतु सुविधाओं का लाभ उठाने के लिए अपने व्यवसाय का विवरण पूरा करें।';

  @override
  String get businessVerificationComplete => 'व्यवसाय विवरण दर्ज';

  @override
  String verificationStepsRemaining(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count चरण शेष',
      one: '1 चरण शेष',
    );
    return '$_temp0';
  }

  @override
  String verificationStepsCompleted(int completed, int total) {
    return '$total में से $completed पूर्ण';
  }

  @override
  String get emailVerificationLabel => 'ईमेल';

  @override
  String get emailVerifiedBadge => 'सत्यापित';

  @override
  String get emailNotVerifiedBadge => 'सत्यापित नहीं';

  @override
  String get businessIdentityLabel => 'व्यवसाय पहचान';

  @override
  String get businessIdentityDesc =>
      'अपने व्यवसाय की पहचान की पुष्टि करने के लिए पैन दर्ज करें।';

  @override
  String get panVerifiedBadge => 'विवरण दर्ज';

  @override
  String get panNotVerifiedBadge => 'प्रदान नहीं किया गया';

  @override
  String get gstRegistrationLabel => 'जीएसटी पंजीकरण';

  @override
  String get gstRegistrationDesc =>
      'व्यापारसेतु पर व्यापक बाज़ार सुविधाओं का लाभ उठाने के लिए अपना जीएसटी पंजीकरण दर्ज करें।';

  @override
  String get gstOptionalNotProvided => 'वैकल्पिक • प्रदान नहीं किया गया';

  @override
  String get gstOptionalDesc =>
      'यहाँ जीएसटी विवरण वैकल्पिक है। यदि आपके व्यवसाय पर लागू हो तो आप इसे बाद में जोड़ सकते हैं।';

  @override
  String get gstVerificationPending => 'प्रारूप जांचा जा रहा है';

  @override
  String get gstVerifiedBadge => 'विवरण दर्ज';

  @override
  String get gstNotVerifiedBadge => 'प्रदान नहीं किया गया';

  @override
  String get verifyPanAction => 'पैन जोड़ें';

  @override
  String get addOrVerifyGstAction => 'जीएसटीआईएन जोड़ें';

  @override
  String get panVerificationComingSoonTitle => 'पैन सत्यापन';

  @override
  String get panVerificationComingSoonDesc =>
      'पैन सत्यापन प्रक्रिया को अपडेट किया जा रहा है। सबमिट करने के बाद आपकी स्थिति यहाँ दिखाई देगी।';

  @override
  String get gstVerificationComingSoonTitle => 'जीएसटी पंजीकरण';

  @override
  String get gstVerificationComingSoonDesc =>
      'यहाँ जीएसटी विवरण वैकल्पिक है। यदि आपके व्यवसाय पर लागू हो तो आप इसे बाद में जोड़ सकते हैं।';

  @override
  String get panVerificationSheetTitle => 'व्यवसाय पहचान (पैन)';

  @override
  String get panVerificationSheetDesc =>
      'व्यापारसेतु पर अपनी व्यावसायिक पहचान दर्ज करने के लिए अपना 10-अंकीय पैन दर्ज करें।';

  @override
  String get panInputLabel => 'पैन नंबर';

  @override
  String get panInputHint => 'उदा. ABCDE1234F';

  @override
  String get panInvalidFormatError =>
      'कृपया एक मान्य 10-अंकीय पैन दर्ज करें (उदा. ABCDE1234F)।';

  @override
  String get panVerificationSuccess => 'पैन विवरण सफलतापूर्वक दर्ज हो गया।';

  @override
  String get panAlreadyLinkedError =>
      'इस खाते के साथ पहले से ही एक पैन जुड़ा हुआ है।';

  @override
  String get panVerificationFailedError =>
      'पैन विवरण दर्ज नहीं हो सके। कृपया अपना विवरण जांचें।';

  @override
  String get gstVerificationSheetTitle => 'जीएसटी पंजीकरण (GSTIN)';

  @override
  String get gstVerificationSheetDesc =>
      'व्यापारसेतु पर अपने जीएसटी विवरण दर्ज करने के लिए अपना 15-अंकीय जीएसटीआईएन दर्ज करें।';

  @override
  String get gstInputLabel => 'जीएसटीआईएन (GSTIN)';

  @override
  String get gstInputHint => 'उदा. 07AAAAA0000A1Z5';

  @override
  String get gstInvalidFormatError =>
      'कृपया एक मान्य 15-अक्षर का जीएसटीआईएन (उदा. 07AAAAA0000A1Z5) दर्ज करें।';

  @override
  String get gstInvalidStateCodeError =>
      'जीएसटीआईएन में अमान्य राज्य कोड। पहले 2 अंक 01-38, 97, या 99 होने चाहिए।';

  @override
  String get gstVerificationSuccess =>
      'जीएसटीआईएन विवरण सफलतापूर्वक दर्ज हो गया।';

  @override
  String get gstAlreadyLinkedError =>
      'इस खाते के साथ पहले से ही एक जीएसटीआईएन जुड़ा हुआ है।';

  @override
  String get gstVerificationFailedError =>
      'जीएसटीआईएन विवरण दर्ज नहीं हो सका। कृपया अपना 15-अंकीय जीएसटीआईएन जांचें।';

  @override
  String get verifyingAction => 'जांचा जा रहा है...';

  @override
  String get verifyAction => 'सबमिट करें';
}
