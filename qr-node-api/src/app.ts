import express from "express";
import QRCode from "qrcode";
import crypto from "crypto";
import { existsSync } from "node:fs";

function generateHash(data: string): string {
  const md5 = crypto.createHash("md5");
  md5.update(data);
  return md5.digest("hex");
}

function run() {
  const app = express();

  app.get("/qr", async function (req, res) {
    console.log(req.query);
    const text: string = req.query.text?.toString() ?? "";
    const size = req.query.size ?? 200;
    const border = req.query.border ?? 2;
    console.log(size, border);

    let dict = { mssage: "generate image failed" };
    if (!text) {
      dict.mssage = "no text";
      res.status(500).json(dict);
      return;
    }

    let name = generateHash(text);
    try {
      let file = "temp/" + name + ".png";
      if (!existsSync(file)) {
        await QRCode.toFile(file, text, {});
        // await QRCode.toFile(file, text, {
        //     size: size,
        //     margin: border
        // });HasklugNerdFontCompleteM-MediumIt,
      }

      res.status(200).type("png").sendFile(file, { root: "." });
    } catch (err) {
      console.log(err);
      res.status(500).json(dict);
    }
  });

  app.listen(3000);
}

run()

