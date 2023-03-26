const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');
const readline = require('readline');
const { spawn } = require('child_process');

const { app, BrowserWindow } = require('electron');

const { generateImagesFromText } = require('./textToImage');

function showWindow() {
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
}

async function main() {
  fsExtra.emptyDirSync(path.resolve('./images'));
  fsExtra.emptyDirSync(path.resolve('./text'));

  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const prompt = (query) => new Promise((resolve) => rl.question(query, resolve));

  const encryptedFilePath = await prompt('Ingrese el directorio del archivo crudo:\n');
  rl.close();

  await fs.copyFile(
    path.resolve(encryptedFilePath),
    path.resolve('./text/encrypted.txt'),
    (err) => { if (err) process.exit(0); }
  );

  console.log('Compilando el algoritmo de desencriptación...');
  const RSAPath = './RSA';
  const buildProcess = spawn('./build.sh', [], {
    stdio: 'inherit',
    cwd: path.resolve(RSAPath)
  });

  buildProcess.on('exit', () => {
    console.log('-------------------------------------------------------------------');
    const processingProcess = spawn('./main', [], {
      stdio: 'inherit',
      cwd: path.resolve(`${RSAPath}/build`)
    });

    processingProcess.on('exit', () => {
      console.log('Desencriptación terminada.');
      showWindow();
    })

    processingProcess.on('error', (err) => {
      console.log(err);
      process.exit(0);
    });
  });

  buildProcess.on('error', (err) => {
    console.log(err);
    process.exit(0);
  })
}

main();