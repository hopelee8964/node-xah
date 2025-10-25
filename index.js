const fs = require("fs");
const path = require("path");
const { spawn } = require("child_process");

const DOMAIN = "node-xah-hopelee8964348-qehpf89w.leapcell.dev";
const PORT = process.env.PORT || 8080;
const UUID = "1f68008d-4978-44e9-b788-b572f5f78087";
const SHORT_ID = "YOUR_SHORT_ID";
const PUBLIC_KEY = "YOUR_PUBLIC_KEY";
let ARGO_DOMAIN = "leapcell.c.6.8.b.0.d.0.0.1.0.a.2.ip6.arpa";
const ARGO_TOKEN = "eyJhIjoiMjY5MTA5YzVhNDQ5NDY3NzE2NmRmZThmMDY0YjZhYzciLCJ0IjoiOGU5NmYzNDQtYTI1My00ZTNmLTkzYjgtZTNhOTY2YmZjZmFkIiwicyI6Ik5HRmlPR1ZrTWpRdE56VTRZaTAwTmpoaUxUazNNVEl0WW1ObU1qUmpaVGxrWVRneiJ9";
const REMARKS_PREFIX = "leapcell";

// Binary and config definitions
const apps = [
  {
    name: "cf",
    binaryPath: path.join(__dirname, "bin/cloudflared"),
    args: ["tunnel", "--config", "config.yaml", "run"],
  },
  {
    name: "xray",
    binaryPath: path.join(__dirname, "bin/xray"),
    args: ["-config", "xray-config.json"],
  },
  {
    name: "hysteria",
    binaryPath: path.join(__dirname, "bin/hysteria"),
    args: ["server", "-c", "hysteria-config.yaml"],
  }
];

const subInfo = [
  `vless://${UUID}@${ARGO_DOMAIN}:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&fp=chrome&type=ws&path=%2F%3Fed%3D2560#${REMARKS_PREFIX}-ws-argo`,
  `vless://${UUID}@${DOMAIN}:${PORT}?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.cloudflare.com&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&spx=%2F&type=tcp&headerType=none#${REMARKS_PREFIX}-reality`,
  `hysteria2://${UUID}@${DOMAIN}:${PORT}?insecure=1#${REMARKS_PREFIX}-hy2`
];

// Print sub info
function printSubInfo() {
  console.log(
    `============================================================
🚀 WebSocket+Argo & Reality & HY2 Node Info
------------------------------------------------------------
${subInfo.join('\n')}
============================================================`);
}

if (ARGO_TOKEN) {
  apps[0].mode = "ignore";
  apps[0].args = ["tunnel", "--no-autoupdate", "--edge-ip-version", "auto", "--protocol", "http2", "run", "--token", ARGO_TOKEN];
  printSubInfo();
}

// Run binary with keep-alive
function runProcess(app) {
  const child = spawn(app.binaryPath, app.args, {
    stdio: app.mode === "filter" ? ["ignore", "pipe", "pipe"] : app.mode
  });

  if (app.mode === "filter") {
    const handleData = (data) => {
      const logText = data.toString();
      const matches = logText.match(app.pattern);
      if (matches && matches.length > 0) {
        child.stdout.off("data", handleData);
        child.stderr.off("data", handleData);
        const tunnelUrl = matches[matches.length - 1];
        ARGO_DOMAIN = new URL(tunnelUrl).hostname;
        subInfo[0] = `vless://${UUID}@${ARGO_DOMAIN}:443?encryption=none&security=tls&sni=${ARGO_DOMAIN}&fp=chrome&type=ws&path=%2F%3Fed%3D2560#${REMARKS_PREFIX}-ws-argo`;
        fs.writeFile(path.join(__dirname, "node.txt"), subInfo.join('\n'), () => { });
        printSubInfo();
      }
    };
    child.stdout.on("data", handleData);
    child.stderr.on("data", handleData);
  }

  child.on("exit", (code) => {
    console.log(`[EXIT] ${app.name} exited with code: ${code}`);
    console.log(`[RESTART] Restarting ${app.name}...`);
    setTimeout(() => runProcess(app), 3000); // restart after 3s
  });
}

// Main execution
function main() {
  try {
    for (const app of apps) {
      runProcess(app);
    }
  } catch (err) {
    console.error("[ERROR] Startup failed:", err);
    process.exit(1);
  }
}

main();
