import 'package:uuid/uuid.dart';
import '../../domain/models/crop_input_params.dart';
import '../../domain/models/crop_recommendation.dart';

class RuleBasedCropEngine {
  static const _uuid = Uuid();

  /// Agronomy Recommendation Logic based on ICAR & State Agricultural University guidelines
  static CropRecommendation recommend(CropInputParams params) {
    final now = DateTime.now();

    // 1. Rabi Season (Winter)
    if (params.season == 'rabi') {
      if (params.soilType == 'black_soil' || params.soilType == 'clay_loam') {
        if (params.waterSource == 'rainfed') {
          // Low water rabi crop -> Desi Chana (Bengal Gram)
          return _buildChickpeaPlan(params, now);
        } else {
          // Irrigated black soil -> Sharbati Wheat C-306
          return _buildWheatPlan(params, now);
        }
      } else if (params.soilType == 'sandy_loam') {
        // Sandy loam with light irrigation -> Potato or Mustard
        return _buildMustardPlan(params, now);
      } else {
        return _buildWheatPlan(params, now);
      }
    }

    // 2. Kharif Season (Monsoon)
    else if (params.season == 'kharif') {
      if (params.waterSource == 'canal' || params.soilType == 'clay') {
        // High water -> Sona Masoori Rice (Paddy)
        return _buildPaddyPlan(params, now);
      } else {
        // Black soil rainfed / tube well -> Yellow Soybean JS-9560
        return _buildSoybeanPlan(params, now);
      }
    }

    // 3. Zaid Season (Summer)
    else {
      return _buildMoongPlan(params, now);
    }
  }

  // Wheat Plan (शरबती गेहूं C-306 / सुजाता)
  static CropRecommendation _buildWheatPlan(CropInputParams params, DateTime baseDate) {
    final minPerAcre = 16.0;
    final maxPerAcre = 20.0;
    final totalExpected = ((minPerAcre + maxPerAcre) / 2) * params.landAreaAcres;

    return CropRecommendation(
      cropId: 'crop_wheat_sharbati',
      nameHi: 'शरबती गेहूं (Sharbati Wheat)',
      nameEn: 'Sharbati Wheat',
      scientificName: 'Triticum aestivum',
      variety: 'C-306 / सुजाता (Sujata) HI-617',
      expectedYieldMinQuintal: minPerAcre,
      expectedYieldMaxQuintal: maxPerAcre,
      totalExpectedYieldQuintal: double.parse(totalExpected.toStringAsFixed(1)),
      confidenceScore: 0.94,
      summaryHi: 'काली गहरी मिट्टी एवं 3-4 सिंचाई के लिए शरबती गेहूं अत्यधिक उपयुक्त है। बाजार में इसके दाने की चमक और मिठास के कारण गुणवत्ता आधारित प्रीमियम दर प्राप्त हो सकती है।',
      calendarSchedule: [
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'खेत की तैयारी व जैविक खाद',
          titleEn: 'Field Preparation & Organic Compost',
          descriptionHi: '2 बार गहरी जुताई करें। प्रति एकड़ 4-5 ट्रॉली सड़ी गोबर की खाद एवं 50 किग्रा डीएपी मिलाएं।',
          descriptionEn: 'Deep plowing twice. Apply 4-5 trolleys well-rotted FYM and 50 kg DAP per acre.',
          stage: 'soil_prep',
          daysAfterSowing: -7,
          dueDate: baseDate.add(const Duration(days: 0)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'बीज उपचार एवं बोआई (Sowing)',
          titleEn: 'Seed Treatment & Sowing',
          descriptionHi: '40 किग्रा बीज प्रति एकड़। ट्राइकोडर्मा (5 ग्राम/किग्रा) से बीज उपचारित कर कतार से कतार 20 सेमी की दूरी पर बोएं।',
          descriptionEn: '40 kg seed per acre. Treat with Trichoderma (5g/kg) and sow at 20 cm row spacing.',
          stage: 'sowing',
          daysAfterSowing: 0,
          dueDate: baseDate.add(const Duration(days: 7)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'प्रथम सिंचाई: मुकुट जड़ (CRI चरण) [अत्यंत महत्वपूर्ण]',
          titleEn: 'First Irrigation: Crown Root (CRI Stage)',
          descriptionHi: 'बोआई के 20-25 दिन बाद मुकुट जड़ निकलती है। इस समय हल्की सिंचाई करें और 30 किग्रा यूरिया प्रति एकड़ दें।',
          descriptionEn: 'Crucial irrigation at 21 days after sowing. Top dress with 30 kg Urea per acre.',
          stage: 'irrigation',
          daysAfterSowing: 21,
          dueDate: baseDate.add(const Duration(days: 28)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'खरपतवार नियंत्रण व निंदाई-गुड़ाई',
          titleEn: 'Weed Control & Hoeing',
          descriptionHi: 'सकरी व चौड़ी पत्ती के खरपतवार निकालें। निंदाई कर मिट्टी ढीली रखें जिससे जड़ों का फैलाव अच्छा हो।',
          descriptionEn: 'Manual weeding or recommended herbicide to prevent nutrient competition.',
          stage: 'pest_control',
          daysAfterSowing: 32,
          dueDate: baseDate.add(const Duration(days: 39)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'द्वितीय सिंचाई व कल्ले फूटते समय खाद',
          titleEn: 'Second Irrigation & Tillering',
          descriptionHi: 'कल्ले फूटने की अवस्था (40-45 दिन) पर दूसरी सिंचाई करें एवं जिंक सल्फेट का छिड़काव करें।',
          descriptionEn: 'Second irrigation at tillering stage with zinc supplementation.',
          stage: 'irrigation',
          daysAfterSowing: 45,
          dueDate: baseDate.add(const Duration(days: 52)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'तृतीय सिंचाई: गभोट व फूल आने की अवस्था',
          titleEn: 'Third Irrigation: Booting & Flowering',
          descriptionHi: 'बालियां निकलने के समय खेत में नमी की कमी न होने दें। आवश्यकतानुसार तीसरी सिंचाई करें।',
          descriptionEn: 'Maintain soil moisture during ear-head emergence and flowering.',
          stage: 'irrigation',
          daysAfterSowing: 70,
          dueDate: baseDate.add(const Duration(days: 77)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'चतुर्थ सिंचाई: दाना भराव (Milk / Dough Stage)',
          titleEn: 'Fourth Irrigation: Grain Filling',
          descriptionHi: 'दाना मोटा व चमकदार बनाने के लिए हल्की सिंचाई करें। तेज हवा चलने पर पानी न दें ताकि फसल गिरे नहीं।',
          descriptionEn: 'Light irrigation during grain filling. Avoid irrigating in high wind.',
          stage: 'irrigation',
          daysAfterSowing: 95,
          dueDate: baseDate.add(const Duration(days: 102)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'फसल कटाई व सुरक्षित भंडारण (Harvesting)',
          titleEn: 'Harvesting & Threshing',
          descriptionHi: 'बालियां सुनहरी होने और दानों में 12-14% नमी रहने पर कंबाइन हार्वेस्टर या दरांती से कटाई करें।',
          descriptionEn: 'Harvest when grains turn golden and moisture drops to 12-14%.',
          stage: 'harvesting',
          daysAfterSowing: 130,
          dueDate: baseDate.add(const Duration(days: 137)),
        ),
      ],
    );
  }

  // Chickpea Plan (देसी चना JG-11 / काबुली)
  static CropRecommendation _buildChickpeaPlan(CropInputParams params, DateTime baseDate) {
    final minPerAcre = 7.5;
    final maxPerAcre = 10.0;
    final totalExpected = ((minPerAcre + maxPerAcre) / 2) * params.landAreaAcres;

    return CropRecommendation(
      cropId: 'crop_chickpea',
      nameHi: 'देसी चना (Desi Chickpea)',
      nameEn: 'Desi Chickpea',
      scientificName: 'Cicer arietinum',
      variety: 'JG-11 / जाकी 9218',
      expectedYieldMinQuintal: minPerAcre,
      expectedYieldMaxQuintal: maxPerAcre,
      totalExpectedYieldQuintal: double.parse(totalExpected.toStringAsFixed(1)),
      confidenceScore: 0.92,
      summaryHi: 'कम पानी वाली काली व दोमट मिट्टी के लिए चना सर्वोत्तम है। यह जमीन में नाइट्रोजन स्थिर कर मिट्टी की उर्वरता बढ़ाता है।',
      calendarSchedule: [
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'भूमि उपचार व राइजोबियम संवर्धन',
          titleEn: 'Soil Prep & Rhizobium Inoculation',
          descriptionHi: 'राइजोबियम कल्चर (10 ग्राम/किग्रा) एवं ट्राइकोडर्मा से बीज उपचार करें। उकठा (Wilt) रोग से बचाव होगा।',
          descriptionEn: 'Treat seeds with Rhizobium culture to fix atmospheric nitrogen.',
          stage: 'soil_prep',
          daysAfterSowing: 0,
          dueDate: baseDate.add(const Duration(days: 5)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'शाखाएं फूटते समय प्रथम सिंचाई (Branching)',
          titleEn: 'First Light Irrigation',
          descriptionHi: 'बोआई के 30-35 दिन बाद हल्की सिंचाई करें। फूल आने से पहले पानी देना आवश्यक है।',
          descriptionEn: 'Light irrigation at branching stage (30-35 days). Never irrigate during peak bloom.',
          stage: 'irrigation',
          daysAfterSowing: 32,
          dueDate: baseDate.add(const Duration(days: 37)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'घेंटी बनते समय फली छेदक (इल्ली) नियंत्रण',
          titleEn: 'Pod Borer (Helicoverpa) Control',
          descriptionHi: 'नीम का तेल (5ml/L) अथवा फेरोमोन ट्रैप लगाएं। इल्ली दिखने पर अनुशंसित जैव कीटनाशक का छिड़काव करें।',
          descriptionEn: 'Install pheromone traps and spray bio-pesticide against pod borer.',
          stage: 'pest_control',
          daysAfterSowing: 60,
          dueDate: baseDate.add(const Duration(days: 65)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'कटाई व गहाई (Harvesting)',
          titleEn: 'Harvesting',
          descriptionHi: 'पत्तियां पीली पड़कर सूखने और घंटियों में दाना खड़कने लगे तब कटाई करें।',
          descriptionEn: 'Harvest when pods rattle and leaves shed dry.',
          stage: 'harvesting',
          daysAfterSowing: 110,
          dueDate: baseDate.add(const Duration(days: 115)),
        ),
      ],
    );
  }

  // Soybean Plan (पीला सोयाबीन JS-9560 / JS-2034)
  static CropRecommendation _buildSoybeanPlan(CropInputParams params, DateTime baseDate) {
    final minPerAcre = 8.0;
    final maxPerAcre = 12.0;
    final totalExpected = ((minPerAcre + maxPerAcre) / 2) * params.landAreaAcres;

    return CropRecommendation(
      cropId: 'crop_soybean',
      nameHi: 'पीला सोयाबीन (Yellow Soybean)',
      nameEn: 'Yellow Soybean',
      scientificName: 'Glycine max',
      variety: 'JS-9560 / JS-2034',
      expectedYieldMinQuintal: minPerAcre,
      expectedYieldMaxQuintal: maxPerAcre,
      totalExpectedYieldQuintal: double.parse(totalExpected.toStringAsFixed(1)),
      confidenceScore: 0.91,
      summaryHi: 'मानसून आधारित काली मध्यम मिट्टी में 90-95 दिनों में पकने वाली सबसे लोकप्रिय खरीफ फसल।',
      calendarSchedule: [
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'मानसून आगमन पर बोआई',
          titleEn: 'Monsoon Sowing',
          descriptionHi: '100 मिमी अच्छी मानसूनी वर्षा होने के बाद ही 30-35 किग्रा बीज प्रति एकड़ बोएं।',
          descriptionEn: 'Sow after at least 100mm monsoon rainfall has saturated the soil.',
          stage: 'sowing',
          daysAfterSowing: 0,
          dueDate: baseDate.add(const Duration(days: 2)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'गर्डल बीटल व सेमीलूपर इल्ली नियंत्रण',
          titleEn: 'Girdle Beetle Pest Control',
          descriptionHi: 'बोआई के 20-25 दिन बाद तना काटने वाले कीड़ों के लिए नीम तेल का छिड़काव करें।',
          descriptionEn: 'Check for girdle beetle symptoms and apply biological pest control.',
          stage: 'pest_control',
          daysAfterSowing: 25,
          dueDate: baseDate.add(const Duration(days: 27)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'फलियां पकने पर कटाई (Harvesting)',
          titleEn: 'Harvesting',
          descriptionHi: 'पत्तियां झड़ने और फलियां भूरी होने पर तुरंत कटाई करें जिससे दाने चटकने से नुकसान न हो।',
          descriptionEn: 'Harvest promptly when pods turn brown to avoid shattering.',
          stage: 'harvesting',
          daysAfterSowing: 95,
          dueDate: baseDate.add(const Duration(days: 97)),
        ),
      ],
    );
  }

  // Paddy Plan (सोना मसूरी धान)
  static CropRecommendation _buildPaddyPlan(CropInputParams params, DateTime baseDate) {
    final minPerAcre = 20.0;
    final maxPerAcre = 26.0;
    final totalExpected = ((minPerAcre + maxPerAcre) / 2) * params.landAreaAcres;

    return CropRecommendation(
      cropId: 'crop_paddy',
      nameHi: 'सोना मसूरी धान (Rice Paddy)',
      nameEn: 'Sona Masoori Rice',
      scientificName: 'Oryza sativa',
      variety: 'सोना मसूरी (BPT-5204)',
      expectedYieldMinQuintal: minPerAcre,
      expectedYieldMaxQuintal: maxPerAcre,
      totalExpectedYieldQuintal: double.parse(totalExpected.toStringAsFixed(1)),
      confidenceScore: 0.95,
      summaryHi: 'नहर अथवा भरपूर पानी वाले क्षेत्रों के लिए सबसे अधिक पैदावार देने वाली सुगंधित धान किस्म।',
      calendarSchedule: [
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'नर्सरी तैयार करना व थरहा बोआई',
          titleEn: 'Nursery Sowing',
          descriptionHi: 'स्वस्थ अंकुरित बीज नर्सरी क्यारी में डालें। 20-25 दिन में रोपाई योग्य पौध तैयार होगी।',
          descriptionEn: 'Prepare raised nursery beds for healthy seedling emergence.',
          stage: 'sowing',
          daysAfterSowing: -25,
          dueDate: baseDate.add(const Duration(days: 0)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'लेहयुक्त खेत में रोपाई (Transplanting)',
          titleEn: 'Field Transplanting',
          descriptionHi: 'खेत में पानी भरकर कद्दू (Puddling) करें। 2-3 पौधे प्रति थान 20x15 सेमी दूरी पर लगाएं।',
          descriptionEn: 'Transplant 2-3 seedlings per hill in puddled field.',
          stage: 'sowing',
          daysAfterSowing: 0,
          dueDate: baseDate.add(const Duration(days: 25)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'कटाई व मड़ाई (Harvesting)',
          titleEn: 'Harvesting',
          descriptionHi: 'बालियां 85% सुनहरी होने पर पानी निकालें और कटाई करें।',
          descriptionEn: 'Drain water 10 days before harvest and harvest at 85% golden head stage.',
          stage: 'harvesting',
          daysAfterSowing: 135,
          dueDate: baseDate.add(const Duration(days: 160)),
        ),
      ],
    );
  }

  // Mustard Plan (पीली सरसों)
  static CropRecommendation _buildMustardPlan(CropInputParams params, DateTime baseDate) {
    final minPerAcre = 8.0;
    final maxPerAcre = 11.0;
    final totalExpected = ((minPerAcre + maxPerAcre) / 2) * params.landAreaAcres;

    return CropRecommendation(
      cropId: 'crop_mustard',
      nameHi: 'पीली सरसों (Mustard)',
      nameEn: 'Yellow Mustard',
      scientificName: 'Brassica juncea',
      variety: 'पूसा बोल्ड / गिरिराज',
      expectedYieldMinQuintal: minPerAcre,
      expectedYieldMaxQuintal: maxPerAcre,
      totalExpectedYieldQuintal: double.parse(totalExpected.toStringAsFixed(1)),
      confidenceScore: 0.90,
      summaryHi: 'दोमट एवं हल्की मिट्टी में केवल 2 सिंचाइयों में तैयार होने वाली तेल तिलहन फसल।',
      calendarSchedule: [
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'अक्टूबर बोआई',
          titleEn: 'October Sowing',
          descriptionHi: '1.5-2 किग्रा बीज प्रति एकड़। कतारों में बोआई करें।',
          descriptionEn: 'Sow in rows with 1.5-2 kg seed rate.',
          stage: 'sowing',
          daysAfterSowing: 0,
          dueDate: baseDate.add(const Duration(days: 5)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'माहू (Aphid) कीट नियंत्रण',
          titleEn: 'Aphid Pest Control',
          descriptionHi: 'दिसंबर-जनवरी में बादल होने पर माहू का प्रकोप हो सकता है। नीम अर्क का छिड़काव करें।',
          descriptionEn: 'Scout for aphid colonies and apply neem-based formulation.',
          stage: 'pest_control',
          daysAfterSowing: 50,
          dueDate: baseDate.add(const Duration(days: 55)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'फलियां पीली होने पर कटाई',
          titleEn: 'Harvesting',
          descriptionHi: 'सुबह के समय कटाई करें ताकि फलियां चटके नहीं।',
          descriptionEn: 'Harvest in early morning to prevent shattering.',
          stage: 'harvesting',
          daysAfterSowing: 115,
          dueDate: baseDate.add(const Duration(days: 120)),
        ),
      ],
    );
  }

  // Moong Plan (ग्रीष्मकालीन मूंग)
  static CropRecommendation _buildMoongPlan(CropInputParams params, DateTime baseDate) {
    final minPerAcre = 4.5;
    final maxPerAcre = 6.5;
    final totalExpected = ((minPerAcre + maxPerAcre) / 2) * params.landAreaAcres;

    return CropRecommendation(
      cropId: 'crop_moong',
      nameHi: 'ग्रीष्मकालीन मूंग (Green Gram)',
      nameEn: 'Summer Moong',
      scientificName: 'Vigna radiata',
      variety: 'विराट (IPM 205-7) / शिखा',
      expectedYieldMinQuintal: minPerAcre,
      expectedYieldMaxQuintal: maxPerAcre,
      totalExpectedYieldQuintal: double.parse(totalExpected.toStringAsFixed(1)),
      confidenceScore: 0.91,
      summaryHi: 'गेहूं कटाई के बाद खाली खेत में 60 दिनों में तैयार होने वाली नकदी दलहन फसल।',
      calendarSchedule: [
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'बोआई व पलेवा',
          titleEn: 'Sowing',
          descriptionHi: '10 किग्रा बीज प्रति एकड़। राइजोबियम कल्चर से उपचारित कर बोएं।',
          descriptionEn: 'Sow at 10 kg/acre after wheat harvest.',
          stage: 'sowing',
          daysAfterSowing: 0,
          dueDate: baseDate.add(const Duration(days: 3)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'पीला मोजेक वायरस नियंत्रण',
          titleEn: 'Yellow Mosaic Virus Control',
          descriptionHi: 'सफेद मक्खी से पीलिया फैलता है। पीले चिपचिपे कार्ड (Yellow Sticky Traps) लगाएं।',
          descriptionEn: 'Install yellow sticky traps to control whitefly vector.',
          stage: 'pest_control',
          daysAfterSowing: 25,
          dueDate: baseDate.add(const Duration(days: 28)),
        ),
        CropCalendarTask(
          id: _uuid.v4(),
          titleHi: 'तुड़ाई व कटाई',
          titleEn: 'Harvesting',
          descriptionHi: 'फलियां काली पड़ते ही तुड़ाई करें।',
          descriptionEn: 'Pick pods as they turn blackish-brown.',
          stage: 'harvesting',
          daysAfterSowing: 60,
          dueDate: baseDate.add(const Duration(days: 63)),
        ),
      ],
    );
  }
}

