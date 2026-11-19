#!/usr/bin/env bash
# Checks every endpoint the app uses against a running API.
#
#   ./scripts/smoke-test.sh                      # http://127.0.0.1:3001
#   API_URL=http://localhost:3000 ./scripts/smoke-test.sh
#
# It publishes one price as the demo user `jorge`.
set -u
API="${API_URL:-http://127.0.0.1:3001}"
JSON='Content-Type: application/json'
failures=0

check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then
    printf '  ok    %-45s %s\n' "$name" "$actual"
  else
    printf '  FALHA %-45s esperado %s, recebido %s\n' "$name" "$expected" "$actual"
    failures=$((failures + 1))
  fi
}

status() { curl -s -o /dev/null -w '%{http_code}' "$@"; }

echo "Mercadex API: $API"
check 'GET /health' 200 "$(status "$API/health")"
check 'GET /products' 200 "$(status "$API/products")"
check 'GET /search?query=cafe (sem acento)' 200 "$(status "$API/search?query=cafe")"
check 'GET /search sem termo' 400 "$(status "$API/search?query=")"
check 'GET /products/cafe-500g/deals' 200 "$(status "$API/products/cafe-500g/deals")"
check 'GET /products/barcode/2000000000060' 200 "$(status "$API/products/barcode/2000000000060")"
check 'GET /products/barcode/desconhecido' 404 "$(status "$API/products/barcode/0000")"
check 'GET /markets' 200 "$(status "$API/markets")"
check 'GET /markets/assai' 200 "$(status "$API/markets/assai")"
check 'POST /auth/login senha errada' 401 \
  "$(status -X POST "$API/auth/login" -H "$JSON" -d '{"username":"jorge","password":"x"}')"
check 'POST /auth/login sem campos' 400 \
  "$(status -X POST "$API/auth/login" -H "$JSON" -d '{}')"

token=$(curl -s -X POST "$API/auth/login" -H "$JSON" \
  -d '{"username":"jorge","password":"mercadex"}' |
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{console.log(JSON.parse(s).accessToken??"")}catch{console.log("")}})')
check 'POST /auth/login jorge' 'token' "$([[ -n "$token" ]] && echo token || echo vazio)"

body='{"productId":"cafe-500g","branchId":"carrefour-centro","price":15.49}'
check 'POST /prices sem token' 401 "$(status -X POST "$API/prices" -H "$JSON" -d "$body")"
check 'POST /prices preço inválido' 400 "$(status -X POST "$API/prices" -H "$JSON" \
  -H "Authorization: Bearer $token" \
  -d '{"productId":"cafe-500g","branchId":"carrefour-centro","price":-1}')"
check 'POST /prices com userId do cliente' 400 "$(status -X POST "$API/prices" -H "$JSON" \
  -H "Authorization: Bearer $token" \
  -d '{"productId":"cafe-500g","branchId":"carrefour-centro","price":15.49,"userId":"x"}')"
check 'POST /prices' 201 "$(status -X POST "$API/prices" -H "$JSON" \
  -H "Authorization: Bearer $token" -d "$body")"

author=$(curl -s "$API/products/cafe-500g/deals" |
  node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{const d=JSON.parse(s).deals.find(x=>x.branch.id==="carrefour-centro");console.log(`${d.price} ${d.submittedBy}`)})')
check 'Preço publicado aparece nas ofertas' '15.49 jorge' "$author"

if (( failures > 0 )); then
  echo "$failures verificação(ões) falharam."
  exit 1
fi
echo 'Todas as verificações passaram.'
