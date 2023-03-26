const fs = require('fs');
const Jimp = require('jimp');

function generateImagesFromText(images) {
  images.forEach((imageInfo) => {
    const pixels = fs.readFileSync(`../text/${imageInfo['name']}.txt`, 'utf8', (err, data) => {
      if (err) throw err;
    }).split(' ');

    let pixelMatrix = [];

    for (let row = 0; row < imageInfo['height']; row++) {
      let rowPixels = [];
      for (let col = 0; col < imageInfo['width']; col++) {
        let pixelString = '';
        let pixel = pixels[row * imageInfo['width'] + col];

        for (let i = 0; i < pixel.length; i++) {
          const charCode = pixel.charCodeAt(i);
          if (charCode >= 48 && charCode <= 57) {
            pixelString += pixel[i];
          }
        }

        rowPixels.push(Number(pixelString));
      }
      pixelMatrix.push(rowPixels);
    }

    const image = new Jimp(imageInfo['width'], imageInfo['height'], (err, image) => {
      if (err) throw err;

      for (let row = 0; row < imageInfo['height']; row++) {
        for (let col = 0; col < imageInfo['width']; col++) {
          const color = getHexColor(pixelMatrix[row][col]);
          image.setPixelColor(color, col, row);
        }
      }

      image.write(`../images/${imageInfo['name']}.png`, (err) => {
        if (err) throw err;
      });
    });
  });
}

function getHexColor(color) {
  let hex = color.toString(16);
  hex = hex.length < 2 ? `0${hex}` : hex;
  hex = `0x${hex}${hex}${hex}FF`;
  return Number(hex);
}

module.exports = {
  generateImagesFromText
}