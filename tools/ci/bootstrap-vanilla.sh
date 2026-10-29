#!/usr/bin/env bash
# The pinned release from Mojang's public CDN, for runners without the maintainer's own
# imported Minecraft (forks). piston-meta, piston-data and libraries.minecraft.net serve
# exactly what the official launcher would have downloaded for the pinned release; this
# lays them out as a launcher's game directory, and `horizon-prepare import` then checks
# every byte against research-lock.json and the manifest's own checksums. Nothing here
# bypasses the game's own license gates: it is Mojang's public distribution of it.
#
# After this, compile-exporters finds the artifacts in .local/minecraft as on a
# self-hosted runner (no HORIZON_SHARED_SOURCE needed: the import lands in this checkout).
set -euo pipefail
root=$PWD
vanilla="${RUNNER_TEMP:-/tmp}/vanilla-minecraft"
mkdir -p "$vanilla"
read -r version manifest_sha1 client_sha1 server_sha1 java_major <<EOF
$(python3 - <<'PY'
import json
lock = json.load(open("research-lock.json"))["minecraft"]
print(lock["version"], lock["manifest_sha1"], lock["client_sha1"], lock["server_sha1"], lock["java_major"])
PY
)
EOF
echo "pinned Minecraft $version (manifest $manifest_sha1, Java $java_major)"

fetch() { # fetch URL OUT ATTEMPTS
  local url=$1 out=$2
  for _ in 1 2 3; do
    if curl -fsSL --retry 2 --connect-timeout 20 "$url" -o "$out"; then return 0; fi
    sleep 5
  done
  echo "::error::could not fetch $url" >&2
  return 1
}
check() { # check FILE EXPECTED-SHA1 WHAT
  local got
  got=$(sha1sum "$1" | cut -d' ' -f1)
  if [ "$got" != "$2" ]; then
    echo "::error::$3: sha1 $got, expected $2" >&2
    return 1
  fi
}

# The pinned version JSON, Mojang's own (a republished one is accepted by the importer too).
mkdir -p "$vanilla/versions/$version"
fetch "https://piston-meta.mojang.com/v1/packages/$manifest_sha1/$version.json" \
  "$vanilla/versions/$version/$version.json"
check "$vanilla/versions/$version/$version.json" "$manifest_sha1" "the version JSON"

# Client and server jars, and every client library, at the paths the importer looks in.
python3 - "$vanilla/versions/$version/$version.json" "$vanilla" "$version" <<'PY'
import json, sys
manifest, vanilla, version = json.load(open(sys.argv[1])), sys.argv[2], sys.argv[3]
downloads = manifest["downloads"]
open(f"{vanilla}/urls.txt", "w").write(
    "\n".join([downloads["client"]["url"] + f"\tversions/{version}/{version}.jar",
               downloads["server"]["url"] + "\tserver.jar"])
    + "\n"
    + "\n".join(
        f"{lib['downloads']['artifact']['url']}\tlibraries/{lib['downloads']['artifact']['path']}"
        for lib in manifest.get("libraries", [])
        if lib.get("downloads", {}).get("artifact")
    )
    + "\n"
)
PY
while IFS=$'\t' read -r url path || [ -n "${url:-}" ]; do
  [ -n "$url" ] || continue
  out="$vanilla/$path"
  if [ -f "$out" ]; then continue; fi
  mkdir -p "$(dirname "$out")"
  fetch "$url" "$out"
  echo "  $(basename "$out")"
done < "$vanilla/urls.txt"
check "$vanilla/versions/$version/$version.jar" "$client_sha1" "the client jar"
check "$vanilla/server.jar" "$server_sha1" "the server jar"

# The importer checks the jars and libraries again, against the lock, and writes
# .local/minecraft/<version>/prepared.json (compile-exporters reads exactly that).
cargo build --release --locked -p horizon-prepare
target/release/horizon-prepare import \
  --minecraft-dir "$vanilla" --server-jar "$vanilla/server.jar" --root "$root"
