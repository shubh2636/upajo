# Upajo (उपजो) - Google Play Store Production Deployment Playbook

---

## 1. Store Listing Metadata

### App Details
- **App Name**: `उपजो - Upajo: किसान से सीधा बाज़ार` (30 characters)
- **Short Description**: `खेत से सीधा अनाज, दालें व फल-सब्जियां। AI रोग जांच, लाइव मंडी भाव व कृषि सहायक।` (79 characters)

### Full Description (4,000 character maximum)
```markdown
🌾 उपजो (Upajo) – भारतीय किसानों और उपभोक्ताओं का विश्वसनीय सीधा डिजिटल मंच 🌾

उपजो भारतीय किसानों (अन्नदाताओं) को बिना किसी बिचौलिए (दलाल) के सीधे शहरी उपभोक्ताओं और थोक खरीदारों से जोड़ता है। अब किसान अपनी मेहनत की कमाई का पूरा 100% मूल्य (0% कमीशन) पाएंगे और ग्राहकों को मिलेगा खेत से सीधे शुद्ध, ताजा और पौष्टिक खाद्यान्न।

प्रमुख विशेषताएं (Key Features for Farmers & Consumers):

1. 🛒 सीधा किसान-उपभोक्ता बाज़ार (Direct Marketplace):
- छोटे और बड़े पैक में बिक्री (10 kg, 20 kg, 50 kg)।
- गेहूं, दालें, सोयाबीन, सरसों, प्याज, आलू व मौसमी सब्जियां सीधे खेत से मंगवाएं।
- पारदर्शी डिलीवरी विकल्प: सीधे खेत से उठाना (Farm Pickup) या घर तक सुरक्षित डिलीवरी (Doorstep Delivery)।
- सुरक्षित डिजिटल भुगतान (UPI, Razorpay) और डिलीवरी पर नकद (COD)।

2. 🤖 AI कृषि सलाहकार व कैलेंडर (ICAR Agronomy Engine):
- अपनी मिट्टी का प्रकार, रकबा (एकड़), मौसम और पानी की सुविधा बताएं।
- पाइए वैज्ञानिक फसल अनुशंसा, किस्म (Variety) और अनुमानित पैदावार।
- बुवाई से लेकर कटाई तक का स्वचालित साप्ताहिक कार्य कैलेंडर व खाद-सिंचाई अलर्ट।

3. 📸 कैमरा से फसल रोग पहचान (AI Plant Pathology Scanner):
- पत्ती या तने की फोटो खींचें, 2 सेकंड में जानिए रोग का नाम।
- 100% सटीक जैविक (Organic) और CIB&RC सुरक्षित रासायनिक उपचार व पंप डोज।
- सरकारी किसान कॉल सेंटर (1800-180-1551) टोल-फ्री हेल्पलाइन कनेक्टिविटी।

4. 🎙️ "कृषि सहायक" – हिंदी आवाज़ AI (Hindi Voice Assistant):
- अपनी भाषा में बोलकर या लिखकर खेती का कोई भी सवाल पूछें।
- मौसम अलर्ट, खाद की सही मात्रा और कीट नियंत्रण पर तुरंत वैज्ञानिक सलाह।

5. 🚜 कृषि यंत्र शेयरिंग एवं किराया (Machinery Rentals):
- ट्रैक्टर, रोटावेटर, कंबाइन हार्वेस्टर व थ्रेशर को घंटे या दिन के हिसाब से किराए पर लें या दें।
- आसान बुकिंग और सुरक्षित अमानत राशि (Deposit) व्यवस्था।

6. 📊 लाइव मंडी भाव व ऐतिहासिक ग्राफ (Agmarknet APMC Rates):
- देशभर की 2,000+ कृषि उपज मंडियों के दैनिक मॉडल भाव और पिछले 7 दिनों का ट्रेंड चार्ट।
- उपजो उचित मूल्य सुझाव (Fair Price Advisor) – जानिए पारंपरिक मंडी से 35% से 45% अधिक मुनाफा कमाने का तरीका।

7. 🧾 GST-मुक्त डिजिटल बिल (Farmer Invoicing):
- CGST अधिनियम धारा 23 के तहत 100% टैक्स-फ्री अधिकृत PDF इनवॉइस एक क्लिक में डाउनलोड व शेयर करें।

सुरक्षा एवं गोपनीयता:
- 100% डेटा सुरक्षा (TLS 1.3 एन्क्रिप्शन)।
- 2 GB RAM वाले साधारण फोन पर भी तीव्र गति से काम करने के लिए विशेष रूप से डिज़ाइन।

उपजो से आज ही जुड़ें – समृद्ध किसान, स्वस्थ भारत!
```

---

## 2. Graphic Assets Checklist

| Asset | Dimensions | Format | Requirements |
|---|---|---|---|
| **App Icon** | $512 \times 512\text{ px}$ | 32-bit PNG (no alpha) | Clean logo (Sprout & Wheat) on Khadi Cream background |
| **Feature Graphic** | $1024 \times 500\text{ px}$ | JPEG / 24-bit PNG | Earthy banner showing farmer with smartphone in field |
| **Phone Screenshot 1** | $1080 \times 1920\text{ px}$ | JPEG / PNG | "सीधे किसान से खरीदें – 10/20/50 kg पैक" |
| **Phone Screenshot 2** | $1080 \times 1920\text{ px}$ | JPEG / PNG | "कैमरा से पत्ती स्कैन करें – तुरंत रोग का इलाज पाएं" |
| **Phone Screenshot 3** | $1080 \times 1920\text{ px}$ | JPEG / PNG | "कृषि सहायक – हिंदी आवाज़ से खेती की हर समस्या का हल" |
| **Phone Screenshot 4** | $1080 \times 1920\text{ px}$ | JPEG / PNG | "लाइव मंडी भाव (Agmarknet) व 7-दिन का ग्राफ" |
| **Phone Screenshot 5** | $1080 \times 1920\text{ px}$ | JPEG / PNG | "ट्रैक्टर व कृषि यंत्र किराए पर लें व दें" |

---

## 3. Play Console Setup Steps

### Step 1: Content Rating Questionnaire
- **App Category**: Shopping / Agriculture & Productivity.
- **Violence, Blood, Sex, Gambling**: **NO** to all questions.
- **User-Generated Content**: Yes (reviews/product listings, with admin moderation).
- **Resulting Rating**: **PEGI 3 / Everyone** (All Ages).

### Step 2: Target Audience & Content
- Target age group: **18 and over** (General Public & Farmers).
- Ads: **No Ads** (Clean transactional utility).

### Step 3: App Access & Credentials for Google Reviewers
Under **App Access -> Restricted Access**, provide:
- **Test Phone Number**: `9876543210`
- **Demo Verification Code**: `123456`
- **Explanation**: Allows full review of Farmer Dashboard, Consumer Shopping Cart, and AI Crop Advisor without real SMS dispatch.

---

## 4. Release Tracks & Staged Rollout Strategy
1. **Internal Testing Track**:
   - Invite internal QA team (up to 100 internal email testers).
   - Test build on physical 2 GB RAM devices (e.g. Redmi 9A, itel Vision).
2. **Closed Testing Track (Alpha)**:
   - 20 verified farmers in Sehore & Bhopal districts (Madhya Pradesh).
   - 14-day continuous testing period required by Google Play policy.
3. **Production Rollout**:
   - Day 1: **10%** of active devices.
   - Day 2: **25%** (Validate Crashlytics Crash-Free Rate $\ge 99.5\%$).
   - Day 3: **50%**.
   - Day 4: **100% Full Rollout**.

