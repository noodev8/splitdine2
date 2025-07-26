# SplitDine Admin - Deployment Guide

Deploy the Next.js admin interface to splitdine.noodev8.com/admin/

## Setup

- **URL**: https://splitdine.noodev8.com/admin/
- **Port**: 3011
- **API**: Uses existing production API on port 3010

## Initial Deployment

### 1. Create directory
```bash
sudo mkdir -p /apps/production/splitdine2_admin
sudo chown $USER:$USER /apps/production/splitdine2_admin
```

### 2. Deploy code
```bash
cd /apps/splitdine2/
git pull
rsync -av --delete --exclude='.env' --exclude='node_modules' --exclude='.git' --exclude='tests' --exclude='docs' --exclude='.github' /apps/splitdine2/splitdine2_admin/ /apps/production/splitdine2_admin/
cd /apps/production/splitdine2_admin
```

### 3. Create environment file
```bash
nano .env
```

Add this content:
```ini
NEXT_PUBLIC_API_URL=https://splitdine.noodev8.com/api
NEXT_PUBLIC_ADMIN_LOGIN_REDIRECT=/admin/
NEXT_PUBLIC_SESSION_TIMEOUT=3600000
NEXT_PUBLIC_APP_NAME=SplitDine Admin
NEXT_PUBLIC_APP_VERSION=1.0.0
NODE_ENV=production
```

### 4. Install and build
```bash
npm install
npm run build
```

### 5. Create systemd service
```bash
sudo nano /etc/systemd/system/splitdine-admin.service
```

Add this content (replace `your-username` with your actual Linux username):
```ini
[Unit]
Description=SplitDine Admin Interface
After=network.target

[Service]
Type=simple
User=your-username
WorkingDirectory=/apps/production/splitdine2_admin
ExecStart=/usr/bin/npm start
Restart=on-failure
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
```

### 6. Start service
```bash
sudo systemctl enable splitdine-admin
sudo systemctl start splitdine-admin
sudo systemctl status splitdine-admin
```

### 7. Update nginx

Find your nginx config file (likely one of these):
```bash
/etc/nginx/sites-available/splitdine.noodev8.com
/etc/nginx/sites-available/default
/etc/nginx/nginx.conf
```

Look for the existing server block with `server_name splitdine.noodev8.com;`

Add this location block inside that server block:
```nginx
location /admin/ {
    proxy_pass http://localhost:3011;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_cache_bypass $http_upgrade;
}
```

Test and reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

### 8. Test
Visit: https://splitdine.noodev8.com/admin/

## Regular Updates

```bash
cd /apps/splitdine2/
git pull
rsync -av --delete --exclude='.env' --exclude='node_modules' --exclude='.git' --exclude='tests' --exclude='docs' --exclude='.github' /apps/splitdine2/splitdine2_admin/ /apps/production/splitdine2_admin/
cd /apps/production/splitdine2_admin
npm install
npm run build
sudo systemctl restart splitdine-admin
```

