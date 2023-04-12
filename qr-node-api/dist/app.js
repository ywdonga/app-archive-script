var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
import express from "express";
import QRCode from "qrcode";
import crypto from "crypto";
import { existsSync } from "node:fs";
const app = express();
function hashString(str) {
    const md5 = crypto.createHash('md5');
    md5.update(str);
    return md5.digest('hex');
}
app.get('/qr', function (req, res) {
    var _a, _b, _c;
    return __awaiter(this, void 0, void 0, function* () {
        console.log(req.query);
        const text = (_a = req.query.text) !== null && _a !== void 0 ? _a : "";
        const size = (_b = req.query.size) !== null && _b !== void 0 ? _b : 200;
        const border = (_c = req.query.border) !== null && _c !== void 0 ? _c : 2;
        console.log(size, border);
        let dict = { mssage: "generate image failed" };
        if (!text) {
            dict.mssage = "no text";
            res.status(500).json(dict);
            return;
        }
        let name = hashString(text);
        try {
            let file = "temp/" + name + ".png";
            if (!existsSync(file)) {
                yield QRCode.toFile(file, text, {
                    size: size,
                    margin: border,
                });
            }
            res.status(200)
                .type("png")
                .sendFile(file, { root: '.' });
        }
        catch (err) {
            console.log(err);
            res.status(500).json(dict);
        }
    });
});
app.listen(3000);
