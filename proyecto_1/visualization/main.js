const path = require('path');
const { spawn } = require('child_process');
const rimraf = require("rimraf");

const { app, BrowserWindow } = require('electron');

const { generateImagesFromText } = require('./textToImage');


rimraf.sync(path.resolve("../images"), [], () => { });
rimraf.sync(path.resolve("../text/decrypted.txt"), [], () => { });

const executablePath = '../RSA/build';
const proc = spawn('./main', [], {
  stdio: 'inherit',
  cwd: path.resolve(executablePath)
});

proc.on('exit', () => {
  const images = [
    {
      name: 'encrypted',
      width: 640,
      height: 960
    },
    {
      name: 'decrypted',
      width: 640,
      height: 480
    }
  ];

  function createWindow() {
    const win = new BrowserWindow({
      webPreferences: {
        nodeIntegration: true
      }
    });

    win.maximize();
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
})