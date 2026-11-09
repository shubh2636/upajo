"""
Verification script for real Supabase project connectivity, authentication, and table verification.
Usage:
  python supabase/tests/verify_supabase_auth.py
"""

import os
import sys
import json
import time
import urllib.request
import urllib.error

def load_env_file():
    """Reads .env from root or ml_service if available."""
    env_vars = {}
    candidates = [".env", "ml_service/.env", "supabase/.env"]
    for path in candidates:
        if os.path.exists(path):
            with open(path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        env_vars[k.strip()] = v.strip().strip('"').strip("'")
            print(f"Loaded credentials from {path}")
            break
    return env_vars

def main():
    env = load_env_file()
    supabase_url = os.environ.get("SUPABASE_URL", env.get("SUPABASE_URL", "")).rstrip("/")
    supabase_anon_key = os.environ.get("SUPABASE_ANON_KEY", env.get("SUPABASE_ANON_KEY", ""))

    print("\n" + "=" * 60)
    print("  UPAJO SUPABASE REAL AUTHENTICATION & SCHEMA VERIFICATION")
    print("=" * 60)

    if not supabase_url or "your-project" in supabase_url or "placeholder" in supabase_url:
        print("\n❌ Error: SUPABASE_URL is not set or still contains placeholder.")
        print("   Set SUPABASE_URL in your root .env file or environment.")
        print(f"   Current value: {supabase_url or '(empty)'}\n")
        sys.exit(1)

    if not supabase_anon_key or "your-" in supabase_anon_key or "placeholder" in supabase_anon_key:
        print("\n❌ Error: SUPABASE_ANON_KEY is not set or still contains placeholder.")
        print("   Set SUPABASE_ANON_KEY in your root .env file or environment.")
        sys.exit(1)

    if "service_role" in supabase_anon_key.lower():
        print("\n❌ FATAL SECURITY ERROR: service_role key detected!")
        print("   Never use the service_role key in the client app. Use the anon key.")
        sys.exit(1)

    print(f"[*] Target Supabase URL: {supabase_url}")
    print(f"[*] Anon Key (masked):  {supabase_anon_key[:12]}...{supabase_anon_key[-6:]}")

    # 1. Ping Auth API
    print("\n--- 1. Testing Auth API Reachability ---")
    auth_health_url = f"{supabase_url}/auth/v1/health"
    req = urllib.request.Request(auth_health_url, headers={"apikey": supabase_anon_key})
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            print(f"  [✓] Auth API is REACHABLE! Status: {resp.status}")
    except urllib.error.HTTPError as e:
        print(f"  [✓] Auth API reached with response: HTTP {e.code}")
    except Exception as e:
        print(f"  [✗] Failed to connect to Auth API: {e}")
        sys.exit(1)

    # 2. Test Signup with unique phone / password
    test_phone = f"+9198{int(time.time()) % 100000000:08d}"
    test_password = "TestPassword@12345"
    print(f"\n--- 2. Testing Signup ({test_phone}) ---")
    signup_url = f"{supabase_url}/auth/v1/signup"
    signup_payload = json.dumps({
        "phone": test_phone,
        "password": test_password,
        "data": {
            "full_name": "Upajo Verification Test",
            "role": "farmer"
        }
    }).encode("utf-8")

    req = urllib.request.Request(
        signup_url,
        data=signup_payload,
        headers={
            "apikey": supabase_anon_key,
            "Content-Type": "application/json"
        }
    )
    access_token = None
    user_id = None
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            user_id = data.get("id") or (data.get("user", {})).get("id")
            access_token = data.get("access_token")
            print(f"  [✓] Signup SUCCESSFUL! User ID: {user_id}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"  [!] Signup returned HTTP {e.code}: {err_body}")
        if "sms_provider" in err_body or "disabled" in err_body or "phone_provider_disabled" in err_body:
            print("  [*] Note: Phone provider is not enabled in this Supabase project.")
            print("      Enable Phone Auth in Supabase Dashboard -> Authentication -> Providers -> Phone.")
    except Exception as e:
        print(f"  [✗] Signup failed: {e}")

    # 3. Test Login
    print(f"\n--- 3. Testing Login ({test_phone}) ---")
    login_url = f"{supabase_url}/auth/v1/token?grant_type=password"
    login_payload = json.dumps({
        "phone": test_phone,
        "password": test_password
    }).encode("utf-8")
    req = urllib.request.Request(
        login_url,
        data=login_payload,
        headers={
            "apikey": supabase_anon_key,
            "Content-Type": "application/json"
        }
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            access_token = data.get("access_token")
            print(f"  [✓] Login SUCCESSFUL! Session established.")
            print(f"      Access Token: {access_token[:15]}...{access_token[-6:]}")
    except urllib.error.HTTPError as e:
        err_body = e.read().decode("utf-8")
        print(f"  [!] Login returned HTTP {e.code}: {err_body}")

    # 4. Test Logout
    if access_token:
        print(f"\n--- 4. Testing Logout ---")
        logout_url = f"{supabase_url}/auth/v1/logout"
        req = urllib.request.Request(
            logout_url,
            data=b"",
            headers={
                "apikey": supabase_anon_key,
                "Authorization": f"Bearer {access_token}"
            }
        )
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                print(f"  [✓] Logout SUCCESSFUL! Session revoked.")
        except Exception as e:
            print(f"  [!] Logout call returned: {e}")

    # 5. Verify Database Tables
    print("\n--- 5. Verifying Database Tables & Public Profiles Access ---")
    profiles_url = f"{supabase_url}/rest/v1/profiles?select=id,role&limit=1"
    req = urllib.request.Request(
        profiles_url,
        headers={
            "apikey": supabase_anon_key,
            "Authorization": f"Bearer {supabase_anon_key}"
        }
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            print(f"  [✓] 'profiles' table exists and is queryable via REST! Records returned: {len(data)}")
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8")
        print(f"  [!] REST API query returned HTTP {e.code}: {err}")
    except Exception as e:
        print(f"  [✗] Failed to query profiles table: {e}")

    print("\n" + "=" * 60)
    print("  VERIFICATION COMPLETE")
    print("=" * 60)

if __name__ == "__main__":
    main()
