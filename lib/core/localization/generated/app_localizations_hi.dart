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
  String get createAccountSubtitle =>
      'एक कारीगर उत्पादक के रूप में अपनी यात्रा शुरू करें और सीधे खरीदारों से जुड़ें।';

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
  String get panVerified => 'पैन सत्यापित';

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
  String get featureComingSoon =>
      'This feature will be available in the next update';

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
  String get filterHidden => 'छिपे हुए';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusDraft => 'ड्राफ्ट';

  @override
  String get statusHidden => 'छिपा हुआ';

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
  String get noHiddenProductsTitle => 'कोई छिपा हुआ उत्पाद नहीं';

  @override
  String get noHiddenProductsSubtitle =>
      'अस्थायी रूप से छिपाए गए उत्पाद यहाँ दिखाई देंगे';

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
}
