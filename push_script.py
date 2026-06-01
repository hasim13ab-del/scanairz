import os
import subprocess

token = os.environ.get("GH_TOKEN")
repo = "github.com/hasim13ab-del/scanairz.git"
url = f"https://hasim13ab-del:{token}@{repo}"

subprocess.run(["git", "add", "."])
subprocess.run(["git", "commit", "-m", "Final Release: Fix Windows build & Trigger CI on full-release branch"])
result = subprocess.run(["git", "push", url, "HEAD:refs/heads/full-release", "--force"], capture_output=True, text=True)
print(result.stdout)
print(result.stderr)
