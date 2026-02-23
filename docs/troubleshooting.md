# Troubleshooting Guide

## Common Issues

### "Gateway already running"
Another instance has the lock. Either:
- Stop the other instance first
- Or it crashed and left a stale lock — delete `*.lock` files in sessions/

### "Rate limit exceeded"
- Check which model is configured
- Verify API key is valid
- May need to wait for limit reset

### "A2A not connected"
1. Check `A2A_AGENT_ID` matches original
2. Verify relay URL is reachable
3. Check daemon logs

### "Telegram bot not responding"
- Only ONE instance can use a bot token at a time
- Stop local before starting cloud (or vice versa)
- Check bot token is valid: `curl https://api.telegram.org/bot<TOKEN>/getMe`

## Getting Help
Contact Sybil via A2A or Bridget directly.
