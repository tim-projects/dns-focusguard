# DNS FocusGuard - Freedom Through Focus

FocusGuard is a robust DNS-based distraction blocker using **Blocky** as its core engine. It provides centralized control over internet access across all your devices by configuring them to use your self-hosted DNS server.

## Key Features
- **Time-Based Blocking**: Schedule blocking for specific categories (entertainment, social media, gaming)
- **Distraction Delay**: Add loading delays to break automatic browsing habits
- **Emergency Override**: Temporarily disable blocking when needed
- **DDoS Protection**: Built-in security against DNS attacks
- **Simple Management**: Edit plain text files to control access

## Core Technology: Blocky
FocusGuard uses **[Blocky](https://github.com/0xERR0R/blocky)** - a fast and lightweight DNS proxy with:
- Flexible blocking groups
- Time-based rule activation
- Response delays
- API control
- Minimal resource usage

## Configuration Guide

### 1. Allowlists (`lists/allowlists/`)
Domains you **always need access to**:
```txt
# essential.txt
google.com
microsoft.com
apple.com

# jobs.txt
linkedin.com
indeed.com
glassdoor.com

# health.txt
headspace.com
calm.com
strava.com
```

### 2. Blocklists (`lists/blocklists/`)
Domains that **hijack your attention**:
```txt
# social-media.txt
facebook.com
*.facebook.com
instagram.com
*.instagram.com

# entertainment.txt
netflix.com
youtube.com
hulu.com

# gaming.txt
steampowered.com
epicgames.com
xbox.com
```

### 3. Advanced Configuration (`deploy/config/blocky-config.yaml`)
Customize blocking behavior:

```yaml
blocking:
  groups:
    # Block entertainment 8AM-8PM
    work:
      blockLists:
        - file:///app/lists/blocklists/entertainment.txt
      activation:
        start: "08:00"
        end: "20:00"
    
    # Block social media & gaming 8PM-10AM
    night:
      blockLists:
        - file:///app/lists/blocklists/social-media.txt
        - file:///app/lists/blocklists/gaming.txt
      activation:
        start: "20:00"
        end: "10:00"
  
  # 10-second delay for social media
  blockingTimeout: 10s
```

Key Configuration Options:
| **Setting**          | **Description**                                 | **Example**        |
|----------------------|-------------------------------------------------|--------------------|
| `activation`         | Time window for group enforcement               | `start: "20:00"`   |
| `blockLists`         | Files containing domains to block               | `entertainment.txt`|
| `blockingTimeout`    | Delay for blocked domains (seconds)             | `10s`              |
| `defaultGroup`       | Rules applied when no time group is active      | `free`             |

## ADHD-Focused Features

### 1. Time-Based Blocking
```yaml
# Block entertainment sites during work hours
- blockLists: [entertainment.txt]
  activation: {start: "08:00", end: "20:00"}

# Block social media & gaming at night
- blockLists: [social-media.txt, gaming.txt]
  activation: {start: "20:00", end: "10:00"}
```

### 2. Distraction Delay
```yaml
# Add 10-second delay to social media
blockingTimeout: 10s
```

### 3. Emergency Override
```bash
# Get 15 minutes of unrestricted access
curl -X POST http://your-server-ip:5000/override?minutes=15
```

## Installation
```bash
git clone https://github.com/tim-projects/dns-focusguard.git
cd dns-focusguard
sudo ./install.sh
```

After installation:
1. Set your devices' DNS to: `your-server-ip`
2. Configure blocking rules as needed

## Maintenance
```bash
# Update blocklists:
nano lists/blocklists/social-media.txt

# Apply changes:
sudo /opt/dns-focusguard/update-and-restart.sh

# Check status:
docker ps | grep focusguard
```

## Troubleshooting
- **DNS not working?**
  ```bash
  ufw status  # Check firewall rules
  docker logs focusguard  # View DNS server logs
  ```
  
- **Changes not applying?**
  ```bash
  sudo systemctl restart ddos-guard
  docker restart focusguard
  ```

- **Emergency reset:**
  ```bash
  curl -X POST http://localhost:4000/api/groups -d '{"group": "free"}'
  ```

## Schedule Reference
| **Time**       | **Blocked Categories**      | **Accessible**              |
|----------------|-----------------------------|-----------------------------|
| 8AM - 8PM     | Entertainment              | All except entertainment   |
| 8PM - 10AM    | Social Media & Gaming      | All except social/gaming   |
| 10AM - 8PM    | None                       | All sites                  |

**Note**: Social media always has 10-second delay regardless of time
```

### Key Improvements:

1. **Blocky Introduction**:
   - Clear explanation of the core technology
   - Link to official Blocky repository

2. **Configuration Focus**:
   - Dedicated section for YAML configuration
   - Configuration options table with examples
   - Clear path references

3. **ADHD Features Breakdown**:
   - Separate sections for each feature
   - Concrete YAML examples
   - Visual schedule reference table

4. **Simplified Instructions**:
   - Streamlined installation steps
   - Direct maintenance commands
   - Practical troubleshooting tips

5. **Visual Enhancements**:
   - Configuration options table
   - Time schedule table
   - Code fencing for config snippets
   - Clear section separation
