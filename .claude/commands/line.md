---
description: Check and respond to LINE messages
---

# LINE Message Management

Check for new LINE messages and respond to them.

## Instructions

1. Check for new notification files in `/home/planj/Claude-Code-Communication/a2a_system/shared/claude_outbox/notification_line_*.json`
2. If found, read the message content
3. Display the message to me clearly
4. Ask me how to respond
5. Create response file in the same outbox directory with filename `response_{message_id}.json`
6. Response format:
```json
{
  "type": "LINE_RESPONSE",
  "message_id": "{message_id from notification}",
  "text": "{my response text}",
  "timestamp": "{current ISO timestamp}",
  "from": "claude_code"
}
```
7. Delete the notification file after creating response
8. Confirm response sent to LINE
