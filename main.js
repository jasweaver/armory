const path = require('path');
const { app, BrowserWindow, protocol, net, shell } = require('electron');

protocol.registerSchemesAsPrivileged([
  {
    scheme: 'app',
    privileges: {
      standard: true,
      secure: true,
      supportFetchAPI: true,
      allowServiceWorkers: true,
      corsEnabled: true,
      stream: true
    }
  }
]);

function resolveAppPathFromUrl(requestUrl) {
  const url = new URL(requestUrl);
  let pathname = decodeURIComponent(url.pathname || '/');

  if (pathname === '/' || pathname === '') {
    pathname = '/armory_combined.html';
  }

  const appRoot = app.getAppPath();
  const targetPath = path.normalize(path.join(appRoot, pathname));

  if (!targetPath.startsWith(appRoot)) {
    return path.join(appRoot, 'armory_combined.html');
  }

  return targetPath;
}

async function registerAppProtocol() {
  protocol.handle('app', (request) => {
    const filePath = resolveAppPathFromUrl(request.url);
    return net.fetch(`file://${filePath}`);
  });
}

function createMainWindow() {
  const win = new BrowserWindow({
    width: 1440,
    height: 920,
    minWidth: 1100,
    minHeight: 720,
    backgroundColor: '#0d0e10',
    autoHideMenuBar: true,
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true,
      devTools: true
    }
  });

  win.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });

  win.loadURL('app://local/armory_combined.html');
}

app.whenReady().then(async () => {
  await registerAppProtocol();
  createMainWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createMainWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
