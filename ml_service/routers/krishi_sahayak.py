import os
import json
import uuid
import requests
from typing import List, Optional, Dict
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

router = APIRouter(prefix="/api/v1/krishi-sahayak", tags=["Krishi Sahayak"])

ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")

class ChatRequest(BaseModel):
    farmer_id: str = Field(..., example="farmer_123")
    message: str = Field(..., example="गेहूं में पहली सिंचाई कब करें?")
    crop_context: Optional[str] = Field("शरबती गेहूं (C-306)")
    district: Optional[str] = Field("सीहोर")
    state: Optional[str] = Field("मध्य प्रदेश")
    temperature: Optional[float] = Field(28.0)
    humidity: Optional[int] = Field(55)
    wind_speed: Optional[float] = Field(10.0)
    history: Optional[List[Dict[str, str]]] = Field(default_factory=list)

class ChatResponse(BaseModel):
    id: str
    reply: str
    source: str # 'claude_3_5' or 'icar_expert_rule_engine'

@router.post("/chat", response_model=ChatResponse)
def chat_with_krishi_sahayak(req: ChatRequest):
    """
    Krishi Sahayak conversational assistant powered by Claude API with farmer context injection,
    CIB&RC safe pesticide limits, and ICAR fallback rules.
    """
    system_prompt = f"""You are 'Krishi Sahayak' (कृषि सहायक), an expert agricultural scientist and trusted companion for Indian farmers.
You respond strictly in clear, warm, conversational Hindi (Devanagari script) with zero complex English jargon.
Target farmer: smallholder Indian farmer in rural MP/India.

LIVE FARMER CONTEXT:
- Active Crop: {req.crop_context}
- Location: {req.district}, {req.state}
- Weather: {req.temperature}°C, {req.humidity}% Humidity, Wind: {req.wind_speed} km/h.

STRICT SAFETY GUARDRAILS:
1. NEVER recommend banned chemicals (e.g., Endosulfan, Monocrotophos, Paraquat, Phorate).
2. For any chemical spray, specify CIB&RC approved safe dosage scaled to a standard 15-litre knapsack pump (e.g., 25-30 ml/g per 15L pump).
3. Always offer organic/biological options first (Neem oil 1500 PPM, Trichoderma, Jeevamrut).
4. If wind speed is > 18 km/h or rain is forecasted, warn the farmer to hold off spraying.
5. Emphasize wearing a cloth mask and washing hands after spraying.
6. For severe outbreaks, refer to Government Kisan Call Center toll-free helpline 1800-180-1551 or local KVK.
7. Keep answers structured (max 3-4 bullet points), practical, and warm (start with 'राम-राम किसान भाई!')."""

    # If Anthropic Claude API Key is configured on backend, call Claude API
    if ANTHROPIC_API_KEY and len(ANTHROPIC_API_KEY.strip()) > 10:
        try:
            claude_messages = []
            for h in (req.history or [])[-6:]:
                role = "user" if h.get("role") == "user" else "assistant"
                claude_messages.append({"role": role, "content": h.get("content", "")})

            claude_messages.append({"role": "user", "content": req.message})

            headers = {
                "x-api-key": ANTHROPIC_API_KEY,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            }
            body = {
                "model": "claude-3-5-sonnet-20241022",
                "max_tokens": 600,
                "temperature": 0.3,
                "system": system_prompt,
                "messages": claude_messages,
            }

            resp = requests.post("https://api.anthropic.com/v1/messages", headers=headers, json=body, timeout=12)
            if resp.status_code == 200:
                data = resp.json()
                reply_text = data["content"][0]["text"]
                return ChatResponse(
                    id=str(uuid.uuid4()),
                    reply=reply_text,
                    source="claude_3_5",
                )
        except Exception as e:
            # Fall through to expert rule-based response
            pass

    # Expert ICAR Rule-Based Engine Fallback
    fallback_text = _generate_icar_expert_reply(req)
    return ChatResponse(
        id=str(uuid.uuid4()),
        reply=fallback_text,
        source="icar_expert_rule_engine",
    )

def _generate_icar_expert_reply(req: ChatRequest) -> str:
    msg = req.message.lower()
    crop = req.crop_context or "गेहूं"
    wind = req.wind_speed or 10.0

    if "सिंचाई" in msg or "पानी" in msg or "irrigation" in msg:
        return f"राम-राम किसान साथी! {crop} में पहली और सबसे महत्वपूर्ण सिंचाई बोआई के 20-25 दिन बाद (CRI - मुकुट जड़ अवस्था) पर करनी चाहिए। इस समय हल्की सिंचाई करें और साथ में 30 किग्रा यूरिया प्रति एकड़ दें। खेत में जलभराव न होने दें।"

    if "पीली" in msg or "धब्बे" in msg or "झुलसा" in msg or "रोग" in msg:
        return f"पत्तियों पर पीले धब्बे दिखना फफूंद जनित झुलसा या रतुआ हो सकता है।\n• जैविक उपाय: नीम का तेल (1500 PPM) 5 मिली प्रति लीटर पानी में मिलाकर छिड़कें।\n• रासायनिक उपाय: मैंकोजेब 75 WP (30 ग्राम प्रति 15 लीटर पंप) का छिड़काव करें।\n• आप ऐप में कैमरा खोलकर पत्ती की फोटो भी स्कैन कर सकते हैं।"

    if "छिड़काव" in msg or "कीटनाशक" in msg or "स्प्रे" in msg:
        if wind > 18.0:
            return f"सावधानी: वर्तमान में हवा की गति {wind:.1f} किमी/घंटा है जो तेज है। हवा तेज होने पर कीटनाशक का छिड़काव बिल्कुल न करें, क्योंकि दवा हवा में उड़कर नष्ट हो जाएगी। हवा शांत होने की प्रतीक्षा करें।"
        return "राम-राम किसान भाई! वर्तमान मौसम छिड़काव के लिए अनुकूल है। ध्यान रखें:\n• 15 लीटर पंप में केवल अनुशंसित मात्रा (25-30 ग्राम/मिली) ही मिलाएं।\n• छिड़काव के समय मुंह पर गमछा या मास्क जरूर बांधें।\n• दोपहर की तेज धूप के बजाय सुबह या शाम को छिड़काव करें।"

    if "इल्ली" in msg or "कीट" in msg or "चना" in msg:
        return "चने व दलहन में इल्ली नियंत्रण के मुख्य उपाय:\n1. खेत में 5 फेरोमोन ट्रैप लगाएं जिससे नर पतंगे पकड़े जा सकें।\n2. 5% नीम बीज अर्क (NSKE) या नीम तेल का प्रारंभिक छिड़काव करें।\n3. प्रकोप अधिक होने पर इमामेक्टिन बेंजोएट 5% SG (8-10 ग्राम प्रति 15 लीटर पंप) का उपयोग करें।"

    if "खाद" in msg or "यूरिया" in msg or "डीएपी" in msg:
        return f"{crop} के लिए अनुशंसित पोषण प्रबंधन:\n• बोआई के समय: 50 किग्रा डीएपी व 20 किग्रा पोटाश प्रति एकड़।\n• पहली सिंचाई (21 दिन): 30-35 किग्रा यूरिया प्रति एकड़।\n• कल्ले फूटते समय: 25 किग्रा यूरिया। अधिक यूरिया से पौधों में कीटों का प्रकोप बढ़ता है, अतः संतुलित प्रयोग करें।"

    return f"राम-राम किसान भाई! मैं आपके {crop} की फसल की पूरी देखभाल के लिए तैयार हूँ। आप बोआई, खाद, सिंचाई, मौसम या पत्तियों पर दिखने वाले रोग के बारे में पूछ सकते हैं। यदि कोई गंभीर समस्या हो तो सरकारी किसान कॉल सेंटर के टोल-फ्री नंबर 1800-180-1551 पर तुरंत सलाह लें।"

