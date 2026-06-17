#!/usr/bin/env bash
set -e
TOOLS_DIR="/home/user/Murad/tools"
mkdir -p "$TOOLS_DIR"
cd "$TOOLS_DIR"

clone_or_update() {
  local url="$1"
  local name="$2"
  if [ -d "$name" ]; then
    git -C "$name" pull -q 2>/dev/null || true
  else
    git clone --depth=1 -q "$url" "$name"
  fi
}

pip_install() {
  local dir="$1"
  if [ -f "$dir/requirements.txt" ]; then
    pip3 install -q -r "$dir/requirements.txt" --break-system-packages 2>/dev/null || \
    pip3 install -r "$dir/requirements.txt" --break-system-packages || true
  fi
  if [ -f "$dir/setup.py" ] || [ -f "$dir/pyproject.toml" ]; then
    pip3 install -q -e "$dir" --break-system-packages 2>/dev/null || true
  fi
}

echo "[1/4] Cloning all repos in parallel..."

declare -A REPOS=(
  ["sherlock"]="https://github.com/sherlock-project/sherlock"
  ["maigret"]="https://github.com/soxoj/maigret"
  ["theHarvester"]="https://github.com/laramies/theHarvester"
  ["helix"]="https://github.com/thalha-a9/helix"
  ["osint-recon-suite"]="https://github.com/Panda1847/osint-recon-suite"
  ["WhatsMyName"]="https://github.com/WebBreacher/WhatsMyName"
  ["social-analyzer"]="https://github.com/qeeqbox/social-analyzer"
  ["osmedeus"]="https://github.com/j3ssie/osmedeus"
  ["OneListForAll"]="https://github.com/six2dez/OneListForAll"
  ["sn0int"]="https://github.com/kpcyrd/sn0int"
  ["enumerepo"]="https://github.com/trickest/enumerepo"
  ["python-for-OSINT-21-days"]="https://github.com/cipher387/python-for-OSINT-21-days"
  ["cheatsheets"]="https://github.com/cipher387/cheatsheets"
  ["Python-osint-automation-examples"]="https://github.com/cipher387/Python-osint-automation-examples"
  ["awesome-grep"]="https://github.com/cipher387/awesome-grep"
  ["Awesome-OSINT-Lists"]="https://github.com/ubikron/Awesome-OSINT-Lists"
  ["OSINT-corsec00"]="https://github.com/corsec00/OSINT"
  ["OSINT-BIBLE"]="https://github.com/frangelbarrera/OSINT-BIBLE"
  ["holehe"]="https://github.com/megadose/holehe"
  ["blackbird"]="https://github.com/p1ngul1n0/blackbird"
  ["GHunt"]="https://github.com/mxrch/GHunt"
)

PIDS=()
for name in "${!REPOS[@]}"; do
  (clone_or_update "${REPOS[$name]}" "$name" && echo "  cloned: $name") &
  PIDS+=($!)
done
for pid in "${PIDS[@]}"; do wait "$pid" 2>/dev/null || true; done

echo "[2/4] Installing Python tool dependencies in parallel..."

PYTHON_TOOLS=(sherlock maigret theHarvester helix osint-recon-suite WhatsMyName social-analyzer
              python-for-OSINT-21-days Python-osint-automation-examples holehe blackbird GHunt)

PIDS=()
for t in "${PYTHON_TOOLS[@]}"; do
  [ -d "$t" ] && (pip_install "$TOOLS_DIR/$t" && echo "  pip done: $t") &
  PIDS+=($!)
done
for pid in "${PIDS[@]}"; do wait "$pid" 2>/dev/null || true; done

echo "[3/4] Installing Go tools..."
if [ -d osmedeus ]; then
  cd osmedeus
  go build -o osmedeus . 2>&1 | tail -3 || true
  cd "$TOOLS_DIR"
  echo "  go build done: osmedeus"
fi

if [ -d enumerepo ]; then
  cd enumerepo
  go build -o enumerepo . 2>&1 | tail -3 || true
  cd "$TOOLS_DIR"
  echo "  go build done: enumerepo"
fi

echo "[4/4] Installing Rust tools..."
if [ -d sn0int ]; then
  cd sn0int
  cargo build --release -q 2>&1 | tail -3 || true
  cd "$TOOLS_DIR"
  echo "  cargo build done: sn0int"
fi

echo ""
echo "=== DONE ==="
ls -1 "$TOOLS_DIR"
