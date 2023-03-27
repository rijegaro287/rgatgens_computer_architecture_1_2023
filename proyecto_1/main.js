const path = require('path');
const fs = require('fs');
const fsExtra = require('fs-extra');
const readline = require('readline');
const { spawn } = require('child_process');

const { app, BrowserWindow } = require('electron');

const { generateImagesFromText } = require('./textToImage');

function createWindow() {
  const win = new BrowserWindow({ webPreferences: { nodeIntegration: true } });

  win.maximize();
  win.loadFile('index.html');
}

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

  await fs.readFile(path.resolve(encryptedFilePath), 'utf8', async (err, data) => {
    if (err) {
      console.error(err);
      return;
    }

    let encryptedText = '';
    for (let i = 0; i < data.length; i++) {
      const char = data.charCodeAt(i);
      if (char !== 10) {
        encryptedText += data[i];
      }
    }

    await fs.writeFile('./text/encrypted.txt', encryptedText, 'utf-8', (err) => {
      if (err) {
        console.error(err);
        return;
      }
    });
  });


  console.log('Compilando el algoritmo de desencriptación...');
  const RSAPath = './RSA';
  const buildProcess = spawn('./build.sh', [], {
    stdio: 'inherit',
    cwd: path.resolve(RSAPath)
  });

  buildProcess.on('exit', () => {
    console.log('-------------------------------------------------------------------');
    const decryptProcess = spawn('./main', [], {
      stdio: 'inherit',
      cwd: path.resolve(`${RSAPath}/build`)
    });

    decryptProcess.on('exit', () => {
      console.log('Desencriptación terminada.');
      showWindow();
    })

    decryptProcess.on('error', (err) => {
      console.log(err);
      app.quit();
    });
  });

  buildProcess.on('error', (err) => {
    console.log(err);
    app.quit();
  })
}

main();