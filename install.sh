#!/usr/bin/env sh

XRAY_VERSION="${XRAY_VERSION:-25.10.15}"
HY2_VERSION="${HY2_VERSION:-2.6.5}"
ARGO_VERSION="${ARGO_VERSION:-2025.10.0}"
DOMAIN="${DOMAIN:-vevc.github.com}"
PORT="${PORT:-10008}"
UUID="${UUID:-$(cat /proc/sys/kernel/random/uuid)}"
ARGO_DOMAIN="${ARGO_DOMAIN:-xxx.trycloudflare.com}"
ARGO_TOKEN="${ARGO_TOKEN:-}"
REMARKS_PREFIX="${REMARKS_PREFIX:-vevc}"
MAIN_FILE="${MAIN_FILE:-index.js}"

sys_arch=amd64
xray_arch=64
arch=$(uname -m)
case "$arch" in
  arm*|aarch64)
    sys_arch=arm64
    xray_arch=arm64-v8a
    ;;
esac

curl -sSL -o $MAIN_FILE https://raw.githubusercontent.com/vevc/node-xah/refs/heads/main/index.js
curl -sSL -o package.json https://raw.githubusercontent.com/vevc/node-xah/refs/heads/main/package.json
sed -i "s/index.js/$MAIN_FILE/g" package.json

mkdir -p /home/container/cf
cd /home/container/cf
curl -sSL -o cf https://github.com/cloudflare/cloudflared/releases/download/$ARGO_VERSION/cloudflared-linux-$sys_arch
chmod +x cf

mkdir -p /home/container/xy
cd /home/container/xy
rm -f *
curl -sSL -o Xray-linux.zip https://github.com/XTLS/Xray-core/releases/download/v$XRAY_VERSION/Xray-linux-$xray_arch.zip
unzip Xray-linux.zip
rm Xray-linux.zip
mv xray xy
curl -sSL -o config.json https://raw.githubusercontent.com/vevc/node-xah/refs/heads/main/xray-config.json
sed -i "s/10008/$PORT/g" config.json
sed -i "s/YOUR_UUID/$UUID/g" config.json
keyPair=$(./xy x25519)
privateKey=$(echo "$keyPair" | grep "PrivateKey" | awk '{print $2}')
publicKey=$(echo "$keyPair" | grep "Password" | awk '{print $2}')
sed -i "s/YOUR_PRIVATE_KEY/$privateKey/g" config.json
shortId=$(openssl rand -hex 4)
sed -i "s/YOUR_SHORT_ID/$shortId/g" config.json
wsUrl="vless://$UUID@$ARGO_DOMAIN:443?encryption=none&security=tls&fp=chrome&type=ws&path=%2F%3Fed%3D2560#$REMARKS_PREFIX-ws-argo"
echo $wsUrl > /home/container/node.txt
realityUrl="vless://$UUID@$DOMAIN:$PORT?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$publicKey&sid=$shortId&spx=%2F&type=tcp&headerType=none#$REMARKS_PREFIX-reality"
echo $realityUrl >> /home/container/node.txt

mkdir -p /home/container/h2
cd /home/container/h2
rm -f *
curl -sSL -o h2 https://github.com/apernet/hysteria/releases/download/app%2Fv$HY2_VERSION/hysteria-linux-$sys_arch
curl -sSL -o config.yaml https://raw.githubusercontent.com/vevc/node-xah/refs/heads/main/hysteria-config.yaml
openssl req -x509 -newkey rsa:2048 -days 3650 -nodes -keyout key.pem -out cert.pem -subj "/CN=$DOMAIN"
chmod +x h2
sed -i "s/10008/$PORT/g" config.yaml
sed -i "s/HY2_PASSWORD/$UUID/g" config.yaml
hy2Url="hysteria2://$UUID@$DOMAIN:$PORT?insecure=1#$REMARKS_PREFIX-hy2"
echo $hy2Url >> /home/container/node.txt

cd /home/container
sed -i "s/YOUR_DOMAIN/$DOMAIN/g" $MAIN_FILE
sed -i "s/10008/$PORT/g" $MAIN_FILE
sed -i "s/YOUR_UUID/$UUID/g" $MAIN_FILE
sed -i "s/YOUR_SHORT_ID/$shortId/g" $MAIN_FILE
sed -i "s/YOUR_PUBLIC_KEY/$publicKey/g" $MAIN_FILE
sed -i "s/YOUR_ARGO_DOMAIN/$ARGO_DOMAIN/g" $MAIN_FILE
sed -i 's/ARGO_TOKEN = ""/ARGO_TOKEN = "'$ARGO_TOKEN'"/g' $MAIN_FILE
sed -i "s/YOUR_REMARKS_PREFIX/$REMARKS_PREFIX/g" $MAIN_FILE

echo "✅ Installation completed. Restart the server and enjoy ~"
