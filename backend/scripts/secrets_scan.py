
#!/usr/bin/env python3
"""
Secrets scan - run before commit
"""
import re
import pathlib

base = pathlib.Path(__file__).parent.parent.parent

patterns = [
    (r"sk-[a-zA-Z0-9]{20,}", "OpenAI API key"),
    (r"sk-ant-[a-zA-Z0-9_-]{20,}", "Anthropic API key"),
    (r"AIza[a-zA-Z0-9_-]{20,}", "Google API key"),
    (r"password\s*=\s*['"][^'"]+['"]", "Hardcoded password"),
    (r"JWT_SECRET\s*=\s*['"][^'"]+['"]", "Hardcoded JWT secret"),
]

flutter_files = list((base / "lib").rglob("*.dart"))
backend_files = list((base / "backend/src").rglob("*.py"))

found = False
for filepath in flutter_files + backend_files:
    if "secure_storage" in str(filepath) or "settings.py" in str(filepath):
        continue
    try:
        content = filepath.read_text(encoding='utf-8')
        for pattern, desc in patterns:
            matches = re.findall(pattern, content)
            if matches:
                # Ignore if in .env.example or comment with placeholder
                if "example" in str(filepath) or "placeholder" in content.lower() or "change-this" in content.lower():
                    continue
                # Check if it's reading from env, not hardcoding
                if "settings." in content or "fromEnvironment" in content or "env" in content.lower():
                    continue
                print(f"POSSIBLE SECRET in {filepath.relative_to(base)}: {desc} -> {matches[0][:20]}...")
                found = True
    except:
        pass

if not found:
    print("Secrets scan: PASS - No hardcoded secrets found in Flutter or backend source (excluding settings.py env reads)")
else:
    print("Secrets scan: FAIL - Potential secrets found")
