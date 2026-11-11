import re

def replace_in_file(path, replacements):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = content
    for old, new in replacements:
        if old in modified:
            modified = modified.replace(old, new)
        else:
            print(f"Warning: could not find snippet in {path}:\n{old[:50]}...")
            
    with open(path, 'w', encoding='utf-8') as f:
        f.write(modified)
    print(f"Updated {path}")

# 1. crop_calendar_screen.dart
crop_calendar_replacements = [
    ("_filterChip('all', 'सभी कार्य ($totalCount)')", "_filterChip('all', 'advisor.all_tasks'.tr(namedArgs: {'count': '$totalCount'}))"),
    ("_filterChip('pending', 'बाकी कार्य (${totalCount - completedCount})')", "_filterChip('pending', 'advisor.pending_tasks'.tr(namedArgs: {'count': '${totalCount - completedCount}'}))"),
    ("_filterChip('completed', 'पूर्ण कार्य ($completedCount)')", "_filterChip('completed', 'advisor.completed_tasks'.tr(namedArgs: {'count': '$completedCount'}))"),
    ("title: 'कोई कार्य नहीं मिला'", "title: 'common.empty'.tr()"),
    ("subtitle: 'इस फ़िल्टर के लिए कोई आगामी कृषि कार्य उपलब्ध नहीं है।'", "subtitle: 'advisor.no_tasks_desc'.tr()"),
    ("rec != null ? rec.nameHi : 'सक्रिय फसल कैलेंडर'", "rec != null ? rec.nameHi : 'advisor.crop_calendar'.tr()"),
    ("rec != null ? 'किस्म: ${rec.variety}' : 'सत्र 2026-27'", "rec != null ? '${'advisor.recommended_variety'.tr()} ${rec.variety}' : '2026-27'"),
    ("'${(progress * 100).toInt()}% पूर्ण'", "'${(progress * 100).toInt()}% ${'common.completed'.tr()}'"),
    ("'$completedCount/$totalCount कार्य पूरे हुए'", "'$completedCount/$totalCount ${'advisor.tasks_completed'.tr()}'"),
    ("'ICAR समयबद्ध कैलेंडर'", "'advisor.icar_calendar'.tr()"),
    ("? 'बोआई +${task.daysAfterSowing} दिन'\n                        : 'बोआई से पहले'", "? 'advisor.sowing_plus'.tr(namedArgs: {'days': '${task.daysAfterSowing}'})\n                        : 'advisor.before_sowing'.tr()"),
    ("'अंतिम तिथि: ${DateFormat('dd MMM yyyy').format(task.dueDate)}'", "'${'advisor.due_date'.tr()}: ${DateFormat('dd MMM yyyy').format(task.dueDate)}'"),
    ("'संपन्न'", "'common.done'.tr()"),
    ("return 'खेत की तैयारी';", "return 'advisor.task_field_prep'.tr();"),
    ("return 'बोआई (Sowing)';", "return 'advisor.task_sowing'.tr();"),
    ("return 'सिंचाई (Irrigation)';", "return 'advisor.task_irrigation'.tr();"),
    ("return 'खाद / पोषण';", "return 'advisor.task_fertilizer'.tr();"),
    ("return 'कीट / खरपतवार';", "return 'advisor.task_pest'.tr();"),
    ("return 'कटाई (Harvest)';", "return 'advisor.task_harvest'.tr();"),
    ("return 'कार्य';", "return 'advisor.task_general'.tr();"),
]

replace_in_file('lib/features/crop_advisor/presentation/screens/crop_calendar_screen.dart', crop_calendar_replacements)

# 2. disease_detection_screen.dart
disease_replacements = [
    ("Tab(icon: Icon(Icons.camera_alt_outlined), text: 'नया स्कैन')", "Tab(icon: const Icon(Icons.camera_alt_outlined), text: 'disease.tab_new'.tr())"),
    ("Tab(icon: Icon(Icons.history_rounded), text: 'पुराने स्कैन')", "Tab(icon: const Icon(Icons.history_rounded), text: 'disease.tab_history'.tr())"),
    ("'संक्रमित पत्ती की साफ, धूप में खींची गई फोटो लें ताकि AI रोग की सटीक पहचान कर सके।'", "'disease.guidance'.tr()"),
    ("label: 'कैमरा से दोबारा लें'", "label: 'disease.retake_camera'.tr()"),
    ("label: 'गैलरी से चुनें'", "label: 'disease.retake_gallery'.tr()"),
    ("'फसल की पत्ती स्कैन करें'", "'disease.capture_title'.tr()"),
    ("'आलू, टमाटर, गेहूं व धान के रोगों की तुरंत पहचान व उपचार'", "'disease.capture_desc'.tr()"),
    ("label: 'कैमरा चालू करें'", "label: 'disease.camera_btn'.tr()"),
    ("label: 'गैलरी से लें'", "label: 'disease.gallery_btn'.tr()"),
    ("Text('रोग का विश्लेषण हो रहा है...', style: AppTypography.headlineSmall.copyWith(fontSize: 17.0))", "Text('disease.analyzing'.tr(), style: AppTypography.headlineSmall.copyWith(fontSize: 17.0))"),
    ("_sectionHeader('लक्षण (Symptoms):', Icons.search_rounded)", "_sectionHeader('disease.symptoms_header'.tr(), Icons.search_rounded)"),
    ("_sectionHeader('जैविक उपचार (Organic Control):', Icons.eco_rounded, color: AppColors.primary600)", "_sectionHeader('disease.organic_control'.tr(), Icons.eco_rounded, color: AppColors.primary600)"),
    ("_sectionHeader('रासायनिक उपचार व सुरक्षित डोज (Chemical Spray):', Icons.science_rounded, color: AppColors.wheat700)", "_sectionHeader('disease.chemical_control'.tr(), Icons.science_rounded, color: AppColors.wheat700)"),
    ("'सलाह: गंभीर स्थिति में कृषि विज्ञान केंद्र (KVK) से संपर्क करें।'", "'disease.disclaimer'.tr()"),
    ("title: 'किसान कॉल सेंटर'", "title: 'disease.helpline_title'.tr()"),
    ("subtitle: 'टोल-फ्री नंबर 1800-180-1551 पर विशेषज्ञ से बात करें'", "subtitle: 'disease.helpline_desc'.tr()"),
    ("label: 'कॉल करें'", "label: 'disease.call_helpline'.tr()"),
    ("title: Text('रोग जांच (Disease Scan)')", "title: Text('disease.title'.tr())"),
]

replace_in_file('lib/features/disease_detection/presentation/screens/disease_detection_screen.dart', disease_replacements)

# 3. krishi_sahayak_screen.dart
sahayak_replacements = [
    ("'गेहूं में पहली सिंचाई कब करें?'", "'sahayak.q1'.tr()"),
    ("'पत्तियों पर पीले धब्बे दिख रहे हैं'", "'sahayak.q2'.tr()"),
    ("'क्या आज मौसम छिड़काव के लिए सही है?'", "'sahayak.q3'.tr()"),
    ("'चने में इल्ली नियंत्रण के उपाय'", "'sahayak.q4'.tr()"),
    ("'यूरिया की सही मात्रा कितनी है?'", "'sahayak.q5'.tr()"),
    ("cropContext: advisorState.recommendation?.nameHi ?? 'गेहूं (Wheat)'", "cropContext: advisorState.recommendation?.nameHi ?? 'Wheat'"),
    ("const Text('क्लाउड AI • हिंदी आवाज़ सहायता', style: TextStyle(fontSize: 11.0, color: AppColors.primary600, fontWeight: FontWeight.bold))", "Text('sahayak.ai_voice_assistant'.tr(), style: const TextStyle(fontSize: 11.0, color: AppColors.primary600, fontWeight: FontWeight.bold))"),
    ("tooltip: 'बातचीत साफ करें'", "tooltip: 'sahayak.clear_chat'.tr()"),
    ("Text('कृषि सहायक उत्तर तैयार कर रहे हैं...', style: AppTypography.bodySmall.copyWith(color: AppColors.soil600))", "Text('sahayak.generating_answer'.tr(), style: AppTypography.bodySmall.copyWith(color: AppColors.soil600))"),
    ("'फसल: ${crop?.nameHi ?? \"गेहूं\"} (${advisorState.district})'", "'${'sahayak.crop_context_label'.tr()}: ${crop?.nameHi ?? \"\"} (${advisorState.district})'"),
    ("Text('कृषि सहायक', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary700))", "Text('sahayak.assistant_name'.tr(), style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.primary700))"),
    ("tooltip: 'बोलकर सुनें'", "tooltip: 'sahayak.listen_voice'.tr()"),
    ("hintText: state.isListening ? 'सुन रहे हैं... बोलिए' : 'बोलें या सवाल लिखें...'", "hintText: state.isListening ? 'common.listening'.tr() : 'sahayak.text_hint'.tr()"),
    ("'सुरक्षा चेतावनी: AI कीटनाशक सलाह मार्गदर्शक है। आपात स्थिति में निःशुल्क किसान कॉल सेंटर 1800-180-1551 पर संपर्क करें।'", "'sahayak.safety_warning'.tr()"),
]

replace_in_file('lib/features/krishi_sahayak/presentation/screens/krishi_sahayak_screen.dart', sahayak_replacements)

