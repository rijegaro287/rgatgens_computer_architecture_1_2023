const path = require('path');
const { app, BrowserWindow } = require('electron');

const { generateImagesFromText } = require('./textToImage');

const images = [
  {
    name: 'encrypted',
    width: 320,
    height: 640
  },
  {
    name: 'decrypted',
    width: 320,
    height: 320
  }
];

function createWindow() {
  const win = new BrowserWindow({
    width: 750,
    height: 700,
    resizable: false,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true
    }
  });

  win.loadFile('index.html');
}

app.whenReady().then(() => {
  generateImagesFromText(images);

  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});