# SplitDine Admin Deployment

**URL**: https://admin.splitdine.noodev8.com/

## Deploy Updates

### 1. On Your Local Machine
```bash
git add .
git commit -m "Your change description"
git push
```

### 2. On the Server
Copy and paste this entire block:

```bash
cd /apps/splitdine2/
git pull
rsync -av --delete --exclude='.env' --exclude='node_modules' --exclude='.git' --exclude='tests' --exclude='docs' --exclude='.github' /apps/splitdine2/splitdine2_admin/ /apps/production/splitdine2_admin/
cd /apps/production/splitdine2_admin
npm install
npm run build
sudo systemctl restart splitdine-admin
sudo systemctl status splitdine-admin
```