# Phase 5 Backend Handoff

This Flutter repository now includes the mobile client-side Phase 5 inbox action work.
The matching backend work has been implemented in `C:\Users\SYed Mohd Hatta\whatsapp-crm-v2` under the mobile v1 API surface.

## Resolution Status

- Resolved `POST /api/mobile/v1/messages/send` reply passthrough with `replyToMessageId`.
- Resolved `POST /api/mobile/v1/messages/:messageId/forward`.
- Resolved `POST /api/mobile/v1/messages/:messageId/create-sales` with duplicate source-message protection.
- Resolved mobile message DTO enrichment for reply preview and message-level sales metadata.
- Resolved mobile inbox conversation DTO enrichment for conversation-level sales metadata.
- Validated existing backend build/lint while leaving existing web endpoints unchanged.

## Goal

Keep the web app behavior unchanged while adding mobile-focused wrappers and DTO enrichment for:

- Reply to a specific message
- Forward a message to another conversation
- Create or tag sales from a message
- Message-level sales metadata
- Conversation-level sales metadata

## Web Safety Rules

- Do not change existing web endpoint response shapes.
- Do not change existing React pages, hooks, components, layouts, or UI.
- Do not rename or remove shared backend functions used by the web app.
- Keep existing endpoints unchanged:
  - `/api/messages/send`
  - `/api/messages/:messageId/forward`
  - `/api/sales/*`
  - `/api/leads/*`
  - `/api/inbox/*`
  - `/api/contacts/*`
  - `/api/auth/*`
- Add or extend mobile-v1 wrappers only.

## Mobile Client Already Implemented

The Flutter app now expects:

- `POST /api/mobile/v1/messages/send`
  - accepts optional `replyToMessageId`
- `POST /api/mobile/v1/messages/:messageId/forward`
  - accepts `targetConversationId`
- `POST /api/mobile/v1/messages/:messageId/create-sales`
  - accepts `status`
  - optional `notes`
- message read DTOs that may include:
  - `replyToMessageId`
  - `replyPreviewText`
  - `hasSales`
  - `salesId`
  - `salesStatus`
  - `salesLabel`
- conversation list DTOs that may include:
  - `hasSales`
  - `salesId`
  - `salesStatus`
  - `salesLabel`

The client parsing remains backward-compatible if these fields are absent.

## Recommended Backend Implementation

## 1. Reply wrapper

### Endpoint

`POST /api/mobile/v1/messages/send`

### Required payload support

```json
{
  "whatsappAccountId": "uuid",
  "conversationId": "uuid",
  "text": "string",
  "replyToMessageId": "uuid | null"
}
```

### Implementation notes

- Reuse existing `/api/messages/send` service logic.
- Pass `replyToMessageId` through unchanged.
- Keep camelCase mobile DTOs.
- Preserve organization scoping and existing permission checks.

## 2. Forward wrapper

### Endpoint

`POST /api/mobile/v1/messages/:messageId/forward`

### Request body

```json
{
  "targetConversationId": "uuid"
}
```

### Implementation notes

- Reuse existing `/api/messages/:messageId/forward` logic.
- Preserve org scoping and permissions.
- A minimal success payload is acceptable if it is stable.

## 3. Create sales from message wrapper

### Preferred endpoint

`POST /api/mobile/v1/messages/:messageId/create-sales`

### Suggested request body

```json
{
  "status": "new_lead",
  "notes": "optional"
}
```

### Suggested success response

```json
{
  "data": {
    "id": "string",
    "sourceMessageId": "string | null",
    "conversationId": "string | null",
    "contactId": "string | null",
    "status": "string",
    "displayStatus": "string",
    "label": "string"
  }
}
```

### Implementation notes

- Inspect the existing web CreateSales flow and reuse the same domain model.
- Prefer the existing sales or leads service that already links `source_message_id` or equivalent.
- Prevent duplicates for the same source message.
- Return a stable mobile DTO.
- If a duplicate exists, return a readable error and stable code.

## 4. Message read DTO enrichment

### Endpoint

`GET /api/mobile/v1/inbox/:conversationId/messages`

### Additive fields per message

```json
{
  "id": "string",
  "direction": "incoming | outgoing | system | string",
  "messageType": "text | image | video | audio | document | sticker | location | contact | reaction | string",
  "contentText": "string",
  "contentJson": {},
  "sentAt": "ISO string | null",
  "externalMessageId": "string | null",
  "ackStatus": "string | null",
  "replyToMessageId": "string | null",
  "replyPreviewText": "string | null",
  "hasSales": true,
  "salesId": "string | null",
  "salesStatus": "string | null",
  "salesLabel": "string | null"
}
```

### Notes

- `replyPreviewText` should be a short preview of the replied-to message if available.
- `hasSales` should be `false` when there is no linked sales record.
- `salesLabel` should use the existing business status label when possible.

## 5. Conversation list DTO enrichment

### Endpoint

`GET /api/mobile/v1/inbox`

### Additive fields per conversation

```json
{
  "hasSales": true,
  "salesId": "string | null",
  "salesStatus": "string | null",
  "salesLabel": "string | null"
}
```

### Selection rule

- If multiple linked sales records exist for a conversation, use the latest active or otherwise most relevant one.

## Error contract

Use readable mobile-safe errors:

```json
{
  "error": "Readable message",
  "code": "stable_error_code"
}
```

Suggested codes:

- `message_not_found`
- `conversation_not_found`
- `duplicate_sales_source_message`
- `forbidden`
- `validation_error`

## Backend file areas to inspect

- messages controller and routes
- mobile v1 controller and routes
- sales routes, controllers, services, DTO mappers
- leads routes, controllers, services, DTO mappers
- web CreateSalesModal-related API calls
- inbox thread projection and query services
- message DTO mappers

## Suggested implementation order

1. Add `replyToMessageId` passthrough to mobile send wrapper.
2. Add mobile forward wrapper that delegates to existing forward logic.
3. Identify the existing sales creation flow used by web and add the mobile wrapper.
4. Extend mobile message DTO mapper with reply and sales metadata.
5. Extend mobile inbox conversation DTO mapper with conversation-level sales metadata.
6. Validate that existing web responses are unchanged.

## Validation commands

Run these in the backend or monorepo after implementation:

```bash
npm run build --workspace apps/api
```

If available:

```bash
npm run lint --workspace apps/api
```

If any shared backend code could affect web behavior:

```bash
npm run build --workspace apps/frontend
```

## Manual smoke checklist

1. Existing web inbox still loads.
2. Existing web reply still works.
3. Existing web forward still works.
4. Existing web sales tagging still works.
5. Mobile reply sends `replyToMessageId`.
6. Mobile forward works to another conversation.
7. Mobile create-sales links the source message.
8. Re-opening mobile thread still shows message sales bubble.
9. Re-opening mobile inbox still shows conversation briefcase indicator.
10. Duplicate sales creation from the same message is blocked.
