# DNS FocusGuard - Freedom Through Focus

FocusGuard is a set of scripts to install, set up and configure a nameserver service on a server.

## Why "FocusGuard"?
This tool creates **digital freedom** by protecting your attention from distractions. The idea is that by setting all your devices to use a central nameserver that you control, that you can block/allow websites in one place and cover all devices and internet connections.

## Configuring Your Focus Environment

### Allowlists
Location: `lists/allowlists/`
- Add domains you **always need access to** (job sites, health resources)
- Format: One domain per line in appropriate category files

Example `jobs.txt`:
```
linkedin.com
indeed.com
remoteok.io
mycareerportal.com
```

### Blocklists
Location: `lists/blocklists/`
- Add domains that **hijack your attention**
- Uses aggressive subdomain blocking (`*.tiktok.com`)

Example `social-media.txt`:
```
facebook.com
*.facebook.com
tiktok.com
*.tiktok.com
instagram.com
```

### Customization Workflow
1. Edit files in `lists/allowlists/` and `lists/blocklists/`
2. Run refresh command:
```bash
sudo ./update-and-restart.sh
```
3. Changes apply in **under 10 seconds** with zero downtime

## ADHD-Specific Features
- **Time-Based Rules**: Block job sites after work hours to prevent burnout
- **Distraction Delay**: 5-second DNS delay for blocked sites breaks autopilot access
- **Emergency Override**: `curl -X POST http://focusguard/api/emergency/15min` for timed access

## Installation
```bash
git clone https://github.com/tim-projects/dns-focusguard.git
cd dns-focusguard
sudo ./install.sh
```

After it's up and running, set your devices to the cname nameserver to use it.

## Maintenance
```bash
# Update blocklists:
nano lists/blocklists/social-media.txt

# Apply changes:
sudo ./update-and-restart.sh

# Check status:
docker ps | grep focusguard
```

## Troubleshooting
- **DNS not resolving?** Check firewall: `ufw status`
- **Changes not applying?** Restart manually: `docker restart focusguard`
