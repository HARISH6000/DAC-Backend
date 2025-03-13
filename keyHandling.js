const { privateToPublic, publicToAddress } = require("ethereumjs-util");
const privateKey = '0x9c315ea91c6457728a41b395e6920dc6bb52546f2c375dbe2d059a1008538bc7';
const publicKey = privateToPublic(privateKey); // 64 bytes (x + y)
const fullPublicKey = "0x04" + publicKey.toString("hex"); // Uncompressed
const address = "0x" + publicToAddress(publicKey).toString("hex");
console.log("Public Key:", fullPublicKey);
console.log("Address:", address);